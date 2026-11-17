# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Upstream rewrites fstab with perl -i, losing its SELinux label
# Hide it during signing so its inode and xattrs survive
# The initramfs already sets iversion on writable ext4 mounts
ima_evm_sign_rootfs:prepend() {
    if [ -f ${IMAGE_ROOTFS}/etc/fstab ]; then
        mv ${IMAGE_ROOTFS}/etc/fstab ${IMAGE_ROOTFS}/etc/.fstab.orig
    fi
}

ima_evm_sign_rootfs:append() {
    if [ -f ${IMAGE_ROOTFS}/etc/.fstab.orig ]; then
        mv ${IMAGE_ROOTFS}/etc/.fstab.orig ${IMAGE_ROOTFS}/etc/fstab
    fi
}
