# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Enable by default with meta-selinux, allow DISTRO_FEATURES:remove to disable it
DISTRO_FEATURES += "selinux"
BBPATH .= ":${IMX_SECURE_BASE}/dynamic-layers/selinux"

PREFERRED_PROVIDER_virtual/refpolicy = "refpolicy-mls"
IMAGE_CLASSES += "${@bb.utils.contains('DISTRO_FEATURES', 'selinux', 'selinux-image selinux-image-order', '', d)}"
IMAGE_CLASSES += "${@bb.utils.contains('DISTRO_FEATURES', 'selinux ima', 'ima-evm-rootfs-extra', '', d)}"

# Match the Raspberry Pi layer until the board policy is ready for enforcement
DEFAULT_ENFORCING ?= "permissive"
