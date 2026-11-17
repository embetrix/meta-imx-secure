# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "SELinux policy and tools"
LICENSE = "MIT"

PACKAGE_ARCH = "${TUNE_PKGARCH}"
inherit packagegroup features_check

REQUIRED_DISTRO_FEATURES = "selinux"

RDEPENDS:${PN} = " \
    libsepol \
    libselinux \
    libselinux-bin \
    libsemanage \
    refpolicy \
    ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', \
        'policycoreutils-fixfiles policycoreutils-secon policycoreutils-semodule policycoreutils-sestatus policycoreutils-setfiles', '', d)} \
"
