# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

inherit_defer ${@bb.utils.contains('IMX_SIGN_ENABLE', '1', 'imx-boot-sign', '', d)}
