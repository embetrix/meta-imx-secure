# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

python imx_security_profile_check() {
    profile = e.data.getVar("IMX_SECURITY_PROFILE")
    if profile not in ("dev", "prod"):
        bb.fatal("IMX_SECURITY_PROFILE must be 'dev' or 'prod', got %r" % profile)
    if profile == "prod":
        for name in ("IMX_SIGN_ENABLE", "UBOOT_SIGN_ENABLE"):
            if e.data.getVar(name) != "1":
                bb.fatal("Production builds require %s = '1'" % name)

    provider = e.data.getVar("OPENSSL_PKCS11_DEFAULT_PROVIDER")
    if provider not in ("optee", "smw"):
        bb.fatal("OPENSSL_PKCS11_DEFAULT_PROVIDER must be 'optee' or 'smw', got %r" % provider)

    # Both PKCS#11 libraries require OP-TEE in the current BSP
    if not bb.utils.contains("MACHINE_FEATURES", "optee", True, False, e.data):
        bb.fatal("OPENSSL_PKCS11_DEFAULT_PROVIDER = '%s' requires 'optee' in MACHINE_FEATURES" % provider)

    if provider == "smw":
        # Match the ELE and SECO platforms enabled by the BSP's SMW recipe
        smw_socs = ("mx8ulp", "mx91", "mx93", "mx943", "mx95", "mx952", "mx937",
                    "mx8qxp", "mx8dx", "mx8dxl")
        overrides = (e.data.getVar("MACHINEOVERRIDES") or "").split(":")
        supported = any(soc in overrides or soc + "-nxp-bsp" in overrides for soc in smw_socs)
        if "use-nxp-bsp" not in overrides or not supported:
            bb.fatal("OPENSSL_PKCS11_DEFAULT_PROVIDER = 'smw' requires an NXP BSP platform "
                     "with an enabled ELE or SECO driver, got MACHINE = %r. "
                     "Use 'optee' on this platform" % e.data.getVar("MACHINE"))
}
addhandler imx_security_profile_check
imx_security_profile_check[eventmask] = "bb.event.ConfigParsed"
