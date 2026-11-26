# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# module.bbclass clears the recipe's earlier FILES assignment
FILES:${PN}:append = " ${modprobedir}/nxp-wlan-btnxpuart.conf"
