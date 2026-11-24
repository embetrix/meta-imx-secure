# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SMW_TA_UUID = "11b5c4aa-6d20-11ea-bc55-0242ac130003"

# Stage the TA for embedding in OP-TEE instead of loading it from the rootfs
do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/optee_armtz/${SMW_TA_UUID}.ta
    rmdir ${D}${nonarch_base_libdir}/optee_armtz
    install -D -m 0644 ${B}/core/subsystems/tee/ta/${SMW_TA_UUID}.stripped.elf \
        ${D}${datadir}/optee-smw/${SMW_TA_UUID}.stripped.elf
}

PACKAGES =+ "${PN}-early-ta"
FILES:${PN}-early-ta = "${datadir}/optee-smw/${SMW_TA_UUID}.stripped.elf"
INHIBIT_PACKAGE_STRIP_FILES = "${PKGD}${datadir}/optee-smw/${SMW_TA_UUID}.stripped.elf"

# Keep backend configs with the runtime library instead of the tests !
FILES:${PN}-tests:remove = "${datadir}/${BPN}/*"
FILES:${PN}-tests += "${datadir}/${BPN}/tests ${datadir}/${BPN}/pkcs11"
FILES:${PN} += "${datadir}/${BPN}"
