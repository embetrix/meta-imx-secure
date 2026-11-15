# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Use OE-Core defaults from defaultsetup.conf
DISTRO = "imx-secure"
DISTRO_NAME = "i.MX Secure"
INHERIT += "imx-secure-version"
DISTRO_VERSION = "${IMX_SECURE_VERSION}"

DISTRO_FEATURES += "polkit ima integrity security"

# Development and production profiles
IMX_SECURITY_PROFILE ??= "dev"
INHERIT += "imx-security-profile"

# Use the security profile and Git version in image filenames
IMAGE_VERSION_SUFFIX = "-${IMX_SECURITY_PROFILE}_${IMX_SECURE_VERSION}"

# Allow password-free logins in development images
EXTRA_IMAGE_FEATURES:append = " ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', \
    'allow-empty-password allow-root-login empty-root-password', '', d)}"

# Remove development login features from production images
IMAGE_FEATURES:remove = "${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', \
    'allow-empty-password allow-root-login empty-root-password', '', d)}"

# Shared i.MX machine settings
require conf/machine/include/imx-secure.inc

# Root filesystem signing
INHERIT += "ima-evm-rootfs"
IMAGE_CLASSES += "avb-verity"

# CVE checks conditional on security profile
IMAGE_CLASSES += "${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'sbom-cve-check', '', d)}"
require conf/distro/include/cve-extra-exclusions.inc

# Set persistent Logs
FILESYSTEM_PERMS_TABLES:remove = "files/fs-perms-volatile-log.txt"
