# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

inherit features_check

REQUIRED_MACHINE_FEATURES = "optee optee-ftpm"
COMPATIBLE_MACHINE:imx-nxp-bsp = "(imx-nxp-bsp)"

EXTRA_OEMAKE:append:aarch64 = " CFG_ARM64_ta_arm64=y"
