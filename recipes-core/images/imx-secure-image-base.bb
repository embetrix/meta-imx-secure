# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "Minimal image for meta-imx-secure"
LICENSE = "MIT"

inherit core-image extrausers image-buildinfo

IMAGE_FEATURES:append = " read-only-rootfs ssh-server-openssh"

# Generate an escaped password hash with:
# openssl passwd -5 -salt "$(openssl rand -hex 8)" 'some_very_secure_password' | sed 's/\$/\\$/g'
# Default passwords: imx = notrustnofun, root = 1234butbetter
# The imx user has no admin privileges
# Production disables SSH password login and serial login
IMX_USER_PASSWD_HASH ?= "\$5\$ae3c3495942cbc3b\$PKEnZIPY2QldtV2ExeTafSRpuMAgjLL4NEw74RPPxp/"
ROOT_USER_PASSWD_HASH ?= "\$5\$8fe9b3c5b1479874\$kZwSJoxUOIHpuJRVts0Th4ueQPEJ2A0T7o3a3Fn92a4"

EXTRA_USERS_PARAMS = " \
    useradd -m -s /bin/sh imx; \
    usermod -p '${IMX_USER_PASSWD_HASH}' imx; \
    usermod -p '${ROOT_USER_PASSWD_HASH}' root; \
"

IMAGE_INSTALL += " \
    packagegroup-security-base \
    ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', 'packagegroup-dev', '', d)}         \
    ${@bb.utils.contains('DISTRO_FEATURES', 'ima', 'packagegroup-ima', '', d)}              \
    ${@bb.utils.contains('DISTRO_FEATURES', 'selinux', 'packagegroup-selinux', '', d)}      \
"
