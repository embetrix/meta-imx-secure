# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Store the SMW database on the separate writable secdata partition
do_install:append() {
    sed -i -e 's|^database=.*|database=${localstatedir}/secdata/smw/smw_objects_database.dat|' \
        ${D}${sysconfdir}/opt/smw/smw.conf
    sed -i -e 's|^DEFAULT_DATABASE=.*|DEFAULT_DATABASE=${localstatedir}/secdata/smw/smw_objects_database.dat|' \
        ${D}${bindir}/smw_database.sh

    install -d ${D}${nonarch_libdir}/tmpfiles.d
    echo 'd ${localstatedir}/secdata/smw 0700 root root -' \
        > ${D}${nonarch_libdir}/tmpfiles.d/smw.conf
}

FILES:${PN} += "${nonarch_libdir}/tmpfiles.d/smw.conf"
