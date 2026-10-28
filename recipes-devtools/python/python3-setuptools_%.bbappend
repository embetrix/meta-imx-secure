# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

PV = "83.0.0"
SRC_URI[sha256sum] = "025bccbbf0fa05b6192bc64ae1e7b16e001fd6d6d4d5de03c97b1c1ade523bef"

# Setuptools 83.0.0 already includes the fix for CVE-2026-59890
# Remove the 82.0.1 backport to avoid applying the same fix twice
SRC_URI:remove = "file://CVE-2026-59890.patch"
