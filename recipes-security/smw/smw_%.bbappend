# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Keep backend configs with the runtime library instead of the tests !
FILES:${PN}-tests:remove = "${datadir}/${BPN}/*"
FILES:${PN}-tests += "${datadir}/${BPN}/tests ${datadir}/${BPN}/pkcs11"
FILES:${PN} += "${datadir}/${BPN}"
