# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Enable Kernel modules signing
inherit kernel-modsign

# # Stage IMA/EVM & AVB_X509 x509 for CONFIG_SYSTEM_TRUSTED_KEYS
KERNEL_TRUSTED_KEYS = "${AVB_X509} ${IMA_EVM_X509}"
inherit kernel-trusted-keys

SRC_URI += " \
            file://patches/v6.18/0001-dm-verity-add-CONFIG_DM_VERITY_REQUIRE_ROOTHASH_SIG.patch \
            file://patches/v6.18/0002-arm64-dts-imx95-add-system-manager-reset.patch \
            file://dev-mapper.cfg \
            file://ext4.cfg \
            file://erofs.cfg \
            file://squashfs.cfg \
            file://hwrng.cfg \
            file://imx-sm-reset.cfg \
            file://netfilter.cfg \
            file://crypto.cfg \
            file://rpmb.cfg \
            file://kmod-sign.cfg \
            ${@bb.utils.contains('DISTRO_FEATURES', 'ima', 'file://ima-evm.cfg', '', d)} \
            ${@bb.utils.contains('DISTRO_FEATURES', 'selinux', 'file://selinux.cfg', '', d)} \
            ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'file://security-harden.cfg', '', d)} \
            "
