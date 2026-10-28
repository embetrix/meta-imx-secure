# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
            file://patches/v6.18/0001-dm-verity-add-CONFIG_DM_VERITY_REQUIRE_ROOTHASH_SIG.patch \
            file://dev-mapper.cfg \
            file://ext4.cfg \
            file://erofs.cfg \
            file://squashfs.cfg \
            file://hwrng.cfg \
            file://netfilter.cfg \
            file://crypto.cfg \
            file://rpmb.cfg \
            "
