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

def imx_fit_key_checksums(d, prefix="UBOOT_SIGN"):
    import os

    if d.getVar(prefix + "_ENABLE") != "1":
        return ""
    return " ".join(os.path.join(d.getVar(prefix + "_KEYDIR"),
                                 d.getVar(prefix + "_KEYNAME") + suffix) + ":True"
                    for suffix in (".key", ".crt"))

def imx_validate_fit_signing_keys(d):
    import os
    import re

    enabled = d.getVar("UBOOT_SIGN_ENABLE") or "0"
    if enabled == "0":
        return
    if enabled != "1":
        bb.fatal("UBOOT_SIGN_ENABLE must be 0 or 1")
    keydir = d.getVar("UBOOT_SIGN_KEYDIR") or ""
    keyname = d.getVar("UBOOT_SIGN_KEYNAME") or ""
    if not os.path.isabs(keydir) or any(c.isspace() for c in keydir) or ":" in keydir:
        bb.fatal("UBOOT_SIGN_KEYDIR must be an absolute path without spaces or colons")
    if not re.fullmatch(r"[A-Za-z0-9_-][A-Za-z0-9_.-]*", keyname):
        bb.fatal("UBOOT_SIGN_KEYNAME must be a filename without a path")
    for suffix in (".key", ".crt"):
        path = os.path.join(keydir, keyname + suffix)
        if not os.path.isfile(path) or not os.access(path, os.R_OK):
            bb.fatal("Missing FIT signing key or certificate: %s\n"
                     "Run tools/genkey-helper.sh <KEY_DIR> to generate FIT keys" % path)

def imx_validate_signing_keys(d):
    import os

    if d.getVar("IMX_SIGN_ENABLE") == "0":
        return
    if d.getVar("IMX_SIGN_ENABLE") != "1":
        bb.fatal("IMX_SIGN_ENABLE must be 0 or 1")

    errors = []
    keydir = d.getVar("IMX_SIGN_KEYDIR") or ""
    config = d.getVar("IMX_SIGN_CONFIG") or ""
    for name, path in [("IMX_SIGN_KEYDIR", keydir)] + ([('IMX_SIGN_CONFIG', config)] if config else []):
        if not os.path.isabs(path) or any(c.isspace() for c in path) or ":" in path:
            errors.append("%s must be an absolute path without spaces or colons" % name)
    if not os.path.isdir(keydir):
        errors.append("IMX_SIGN_KEYDIR does not exist: %s" % keydir)

    if config:
        # SPSDK checks the keys referenced by a custom YAML file during signing
        files = [("IMX_SIGN_CONFIG", config)]
    else:
        if d.getVar("IMX_SIGN_SRK_ID") not in ("0", "1", "2", "3"):
            errors.append("IMX_SIGN_SRK_ID must be 0, 1, 2 or 3")
        public_keys = (d.getVar("IMX_SIGN_SRK_FILES") or "").split()
        if len(public_keys) != 4:
            errors.append("IMX_SIGN_SRK_FILES must list four public keys or certificates")
        files = [("IMX_SIGN_PRIVATE_KEY", d.getVar("IMX_SIGN_PRIVATE_KEY"))]
        files += [("IMX_SIGN_SRK_FILES", path) for path in public_keys]
    for name, path in files:
        path = os.path.join(keydir, path or "")
        if not os.path.isfile(path) or not os.access(path, os.R_OK):
            errors.append("%s is missing or unreadable: %s" % (name, path))
        elif not config and os.path.commonpath([os.path.realpath(keydir), os.path.realpath(path)]) != os.path.realpath(keydir):
            errors.append("%s must be inside IMX_SIGN_KEYDIR: %s" % (name, path))
    if errors:
        bb.fatal("Invalid AHAB signing keys:\n  " + "\n  ".join(errors) +
                 "\n\nGenerate keys with:\n  tools/genkey-helper.sh <KEY_DIR>\n\n"
                 "Then build with:\n  kas build kas-imx-secure.yml:kas-signing-keys.yml")

addhandler imx_check_signing_keys
imx_check_signing_keys[eventmask] = "bb.event.BuildStarted"

python imx_check_signing_keys() {
    imx_validate_signing_keys(e.data)
    imx_validate_fit_signing_keys(e.data)
}
