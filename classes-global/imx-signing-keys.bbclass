# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>
#
# Shared AHAB and FIT key defaults and checks
# Generate keys and a kas fragment with tools/genkey-helper.sh

IMX_SIGN_ENABLE ??= "0"
IMX_SIGN_KEYDIR ??= ""
IMX_SIGN_CONFIG ??= ""
IMX_SIGN_SRK_ID ??= "0"
IMX_SIGN_PRIVATE_KEY ??= "${IMX_SIGN_KEYDIR}/srk${IMX_SIGN_SRK_ID}.pem"
IMX_SIGN_SRK_FILES ??= "${IMX_SIGN_KEYDIR}/srk0.pub \
                        ${IMX_SIGN_KEYDIR}/srk1.pub \
                        ${IMX_SIGN_KEYDIR}/srk2.pub \
                        ${IMX_SIGN_KEYDIR}/srk3.pub"
IMX_SIGN_HASH_ALGORITHM ??= "default"

IMX_SIGN_PQC_ENABLE ??= "0"
IMX_SIGN_PQC_KEYDIR ??= "${IMX_SIGN_KEYDIR}/mldsa"
IMX_SIGN_PQC_PRIVATE_KEY ??= "${IMX_SIGN_PQC_KEYDIR}/srk${IMX_SIGN_SRK_ID}.pem"
IMX_SIGN_PQC_SRK_FILES ??= "${IMX_SIGN_PQC_KEYDIR}/srk0.pub \
                            ${IMX_SIGN_PQC_KEYDIR}/srk1.pub \
                            ${IMX_SIGN_PQC_KEYDIR}/srk2.pub \
                            ${IMX_SIGN_PQC_KEYDIR}/srk3.pub"
IMX_SIGN_PQC_HASH_ALGORITHM ??= "sha3_512"

def imx_validate_signing_flags(d):
    for name in ("IMX_SIGN_ENABLE", "IMX_SIGN_PQC_ENABLE", "IMX_SIGN_DEBUG", "UBOOT_SIGN_ENABLE"):
        value = d.getVar(name)
        if value is not None and value not in ("0", "1"):
            bb.fatal("%s must be 0 or 1" % name)

def imx_fit_key_checksums(d, prefix="UBOOT_SIGN"):
    import os

    if d.getVar(prefix + "_ENABLE") != "1":
        return ""
    return " ".join(os.path.join(d.getVar(prefix + "_KEYDIR"),
                                 d.getVar(prefix + "_KEYNAME") + suffix) + ":True"
                    for suffix in (".key", ".crt"))

def imx_validate_fit_signing_keys(d, prefix="UBOOT_SIGN"):
    import os
    import re

    enabled = d.getVar(prefix + "_ENABLE")
    if enabled in (None, "0"):
        return
    if enabled != "1":
        bb.fatal("%s_ENABLE must be 0 or 1" % prefix)
    keydir = d.getVar(prefix + "_KEYDIR") or ""
    keyname = d.getVar(prefix + "_KEYNAME") or ""
    if not os.path.isabs(keydir) or any(c.isspace() for c in keydir) or ":" in keydir:
        bb.fatal("%s_KEYDIR must be an absolute path without spaces or colons" % prefix)
    if not re.fullmatch(r"[A-Za-z0-9_-][A-Za-z0-9_.-]*", keyname):
        bb.fatal("%s_KEYNAME must be a filename without a path" % prefix)
    for suffix in (".key", ".crt"):
        path = os.path.join(keydir, keyname + suffix)
        if not os.path.isfile(path) or not os.access(path, os.R_OK) or not os.path.getsize(path):
            bb.fatal("Missing, empty or unreadable FIT signing key or certificate: %s\n"
                     "Run tools/genkey-helper.sh <KEY_DIR> to generate FIT keys" % path)

def imx_validate_signing_keys(d):
    import os

    imx_validate_signing_flags(d)
    if d.getVar("IMX_SIGN_ENABLE") != "1":
        return

    errors = []
    keydir = d.getVar("IMX_SIGN_KEYDIR") or ""
    keydirs = [("IMX_SIGN", keydir)]
    if d.getVar("IMX_SIGN_PQC_ENABLE") == "1":
        keydirs.append(("IMX_SIGN_PQC", d.getVar("IMX_SIGN_PQC_KEYDIR") or ""))
    config = d.getVar("IMX_SIGN_CONFIG") or ""
    paths = [(prefix + "_KEYDIR", path) for prefix, path in keydirs]
    if config:
        paths.append(("IMX_SIGN_CONFIG", config))
    for name, path in paths:
        if not os.path.isabs(path) or any(c.isspace() for c in path) or ":" in path:
            errors.append("%s must be an absolute path without spaces or colons" % name)
    for prefix, path in keydirs:
        if not os.path.isdir(path):
            errors.append("%s_KEYDIR does not exist: %s" % (prefix, path))

    if config:
        # SPSDK checks the keys referenced by a custom YAML file during signing
        files = [("IMX_SIGN_CONFIG", config, None)]
    else:
        if d.getVar("IMX_SIGN_SRK_ID") not in ("0", "1", "2", "3"):
            errors.append("IMX_SIGN_SRK_ID must be 0, 1, 2 or 3")
        files = []
        for prefix, directory in keydirs:
            public_keys = (d.getVar(prefix + "_SRK_FILES") or "").split()
            if len(public_keys) != 4:
                errors.append("%s_SRK_FILES must list four public keys or certificates" % prefix)
            files.append((prefix + "_PRIVATE_KEY", d.getVar(prefix + "_PRIVATE_KEY"), directory))
            files += [(prefix + "_SRK_FILES", path, directory) for path in public_keys]
    for name, path, directory in files:
        path = os.path.join(directory or "", path or "")
        if not os.path.isfile(path) or not os.access(path, os.R_OK) or not os.path.getsize(path):
            errors.append("%s is missing, empty or unreadable: %s" % (name, path))
        elif directory is not None and os.path.commonpath([os.path.realpath(directory), os.path.realpath(path)]) != os.path.realpath(directory):
            errors.append("%s must be inside its signing key directory: %s" % (name, path))
    if errors:
        command = "PQC_KEY_TYPE=mldsa65 " if d.getVar("IMX_SIGN_PQC_ENABLE") == "1" else ""
        bb.fatal("Invalid AHAB signing keys:\n  " + "\n  ".join(errors) +
                 "\n\nGenerate keys with:\n  " + command + "tools/genkey-helper.sh <KEY_DIR>\n\n"
                 "Then build with:\n  kas build kas-imx-secure.yml:kas-signing-keys.yml")

addhandler imx_check_signing_flags imx_check_signing_keys
imx_check_signing_flags[eventmask] = "bb.event.ConfigParsed"
imx_check_signing_keys[eventmask] = "bb.event.BuildStarted"

python imx_check_signing_flags() {
    imx_validate_signing_flags(e.data)
}

python imx_check_signing_keys() {
    imx_validate_signing_keys(e.data)
    imx_validate_fit_signing_keys(e.data)
}
