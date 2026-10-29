# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Disable the M33 debug monitor in production builds
SYSTEM_MANAGER_MONITOR_MODE = "${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', '0', '2', d)}"

# INC_LIBC=0 disables debug UART setup and console output
EXTRA_OEMAKE:append = " ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', \
    'DEBUG=0 INC_LIBC=0 TEST_MODE=0', '', d)}"
