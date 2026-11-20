# SPDX-License-Identifier: BSD-3-Clause
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

"""Sign AHAB images using ASN.1 references to HSM keys

Read a PKCS#11 PROVIDER URI PEM file and use the referenced token key through
the SPSDK PKCS#11 plugin. The private key stays on the HSM. Before signing,
prepare_signer checks that the key matches the selected SRK public key.

Limitations:
- ECDSA and RSA-PSS only, with SHA-256, SHA-384 or SHA-512
- No ML-DSA reference keys
- Requires IMX_SIGN_PKCS11_MODULE and IMX_SIGN_PKCS11_PIN_FILE on the host
- Accepts token, serial, manufacturer, model, object, id and type URI fields
- Rejects URI query parameters, including embedded PINs
- Reference file paths must not contain ';' or '='
"""

import base64
import os
import re
from pathlib import Path
from urllib.parse import unquote_to_bytes

import pkcs11
from asn1crypto import core
from spsdk.crypto.hash import EnumHashAlgorithm, get_hash
from spsdk.crypto.keys import PublicKeyEcc, PublicKeyRsa
from spsdk.exceptions import SPSDKError
from spsdk_pkcs11.provider import PKCS11SP


PEM_LABEL = "PKCS#11 PROVIDER URI"


class Reference(core.Sequence):
    _fields = [("description", core.VisibleString), ("uri", core.UTF8String)]


def read_reference(path):
    """Return URI attributes, or None for a normal key file"""
    data = Path(path).read_bytes()
    if ("-----BEGIN " + PEM_LABEL + "-----").encode() not in data:
        return None
    try:
        # asn1crypto's PEM reader does not accept '#' in a PEM label
        lines = data.strip().splitlines()
        if (len(lines) < 3 or lines[0] != b"-----BEGIN PKCS#11 PROVIDER URI-----"
                or lines[-1] != b"-----END PKCS#11 PROVIDER URI-----"):
            raise ValueError()
        der = base64.b64decode(b"".join(lines[1:-1]), validate=True)
        reference = Reference.load(der, strict=True)
        if len(reference) != 2:
            raise ValueError()
        if reference["description"].native != "PKCS#11 Provider URI v1.0":
            raise ValueError()
        uri = reference["uri"].native
        if not uri.startswith("pkcs11:") or "#" in uri or "?" in uri:
            raise ValueError()
        attributes = {}
        allowed = {"token", "serial", "manufacturer", "model", "object", "id", "type"}
        for item in uri[7:].split(";"):
            name, value = item.split("=", 1)
            if name not in allowed or name in attributes or re.search(r"%(?![0-9a-fA-F]{2})", value):
                raise ValueError()
            value = unquote_to_bytes(value)
            attributes[name] = value if name == "id" else value.decode("utf-8")
        if attributes.get("type") != "private":
            raise ValueError()
        if not (attributes.get("token") or attributes.get("serial")):
            raise ValueError()
        if not (attributes.get("object") or attributes.get("id")):
            raise ValueError()
        return attributes
    except (ValueError, TypeError, KeyError) as error:
        # Do not echo URI contents, which might contain a PIN
        raise SPSDKError("Invalid PKCS#11 reference PEM. Use a private-key URI with token/serial "
                         "and object/id, without query parameters") from error


class PKCS11PEM(PKCS11SP):
    """Keep key references in files while signing through PKCS#11"""

    identifier = "pkcs11_pem"

    def __init__(self, file_path, hash_alg=None, pss_padding=True, **kwargs):
        reference = read_reference(file_path)
        if reference is None:
            raise SPSDKError("Expected a PKCS#11 reference PEM")
        module = os.environ.get("IMX_SIGN_PKCS11_MODULE", "")
        pin_file = os.environ.get("IMX_SIGN_PKCS11_PIN_FILE", "")
        if not Path(module).is_absolute() or not Path(module).is_file():
            raise SPSDKError("Set IMX_SIGN_PKCS11_MODULE to the host PKCS#11 library")
        if not Path(pin_file).is_absolute() or not Path(pin_file).is_file():
            raise SPSDKError("Set IMX_SIGN_PKCS11_PIN_FILE to an absolute PIN file path")
        self.hash_alg = hash_alg
        try:
            super().__init__(
                so_path=module, user_pin=pin_file,
                token_label=reference.get("token"), token_serial=reference.get("serial"),
                key_label=reference.get("object"), key_id=reference.get("id", b"").hex() or None,
                pss_padding=pss_padding, **kwargs)
            for name in ("manufacturer", "model"):
                if name in reference and getattr(self.token, name) != reference[name]:
                    raise SPSDKError(f"PKCS#11 token {name} does not match the reference PEM")
        except pkcs11.PKCS11Error as error:
            raise SPSDKError(f"PKCS#11 token lookup failed: {type(error).__name__}") from error

    def sign(self, data):
        # The upstream plugin ignores hash_alg and fixes RSA-PSS to SHA-256
        try:
            with self.token.open(user_pin=self.user_pin) as session:
                key = session.get_key(object_class=pkcs11.ObjectClass.PRIVATE_KEY,
                                      label=self.key_label, id=self.key_id)
                algorithm = self.hash_alg or self._get_hash_alg(key)
                if algorithm not in (EnumHashAlgorithm.SHA256, EnumHashAlgorithm.SHA384,
                                     EnumHashAlgorithm.SHA512):
                    raise SPSDKError("PKCS#11 AHAB signing supports SHA-256, SHA-384 and SHA-512")
                digest = get_hash(data, algorithm)
                if key.key_type == pkcs11.KeyType.EC:
                    return key.sign(digest, mechanism=pkcs11.Mechanism.ECDSA)
                if key.key_type == pkcs11.KeyType.RSA and self.pss_padding:
                    name = algorithm.label.upper()
                    params = (getattr(pkcs11.Mechanism, name), getattr(pkcs11.MGF, name), len(digest))
                    return key.sign(digest, mechanism=pkcs11.Mechanism.RSA_PKCS_PSS,
                                    mechanism_param=params)
                raise SPSDKError("PKCS#11 AHAB signing needs ECDSA or RSA-PSS")
        except pkcs11.PKCS11Error as error:
            raise SPSDKError(f"PKCS#11 signing failed: {type(error).__name__}") from error

    def verify_public_key(self, public_key):
        if not isinstance(public_key, (PublicKeyEcc, PublicKeyRsa)):
            raise SPSDKError("PKCS#11 reference PEM files support RSA and ECC keys only")
        data = b"AHAB PKCS#11 key check"
        return public_key.verify_signature(self.sign(data), data, algorithm=self.hash_alg,
                                           pss_padding=self.pss_padding)


def prepare_signer(path, public_key, hash_algorithm="default"):
    """Check the referenced key and return an SPSDK signer string"""
    if read_reference(path) is None:
        return None
    if any(char in str(path) for char in ";="):
        raise SPSDKError("PKCS#11 reference PEM paths must not contain ';' or '='")
    if not isinstance(public_key, (PublicKeyEcc, PublicKeyRsa)):
        raise SPSDKError("PKCS#11 reference PEM files support RSA and ECC keys only")
    algorithm = (EnumHashAlgorithm.from_label(hash_algorithm) if hash_algorithm != "default"
                 else EnumHashAlgorithm.SHA256 if isinstance(public_key, PublicKeyRsa)
                 else public_key.default_hash_algorithm)
    provider = PKCS11PEM(str(path), hash_alg=algorithm)
    if not provider.verify_public_key(public_key):
        raise SPSDKError("PKCS#11 key does not match the selected SRK public key")
    return f"type=pkcs11_pem;file_path={path}"
