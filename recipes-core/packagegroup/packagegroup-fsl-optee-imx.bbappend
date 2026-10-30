# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

RDEPENDS:${PN}:remove = "${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'optee-test', '', d)}"
RDEPENDS:${PN}:append = " ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', 'optee-pqc', '', d)}"
