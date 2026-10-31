# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Keep test binaries and vectors out of runtime packages
PACKAGES =+ "${PN}-tests"
FILES:${PN}-tests = "${bindir}/*_test ${datadir}/se"
RDEPENDS:${PN}-tests = "${PN}"
