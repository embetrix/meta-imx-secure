# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

python imx_security_profile_check() {
    profile = e.data.getVar("IMX_SECURITY_PROFILE")
    if profile not in ("dev", "prod"):
        bb.fatal("IMX_SECURITY_PROFILE must be 'dev' or 'prod', got %r" % profile)
}
addhandler imx_security_profile_check
imx_security_profile_check[eventmask] = "bb.event.ConfigParsed"
