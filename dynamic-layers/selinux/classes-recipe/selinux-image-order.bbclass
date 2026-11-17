# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Label files before signing their xattrs with IMA/EVM
python selinux_image_order_handler() {
    cmd = d.getVar('IMAGE_PREPROCESS_COMMAND') or ''
    if 'selinux_set_labels;' not in cmd or 'ima_evm_sign_rootfs;' not in cmd:
        return
    cmd = cmd.replace('selinux_set_labels;', '').replace('ima_evm_sign_rootfs;', '')
    d.setVar('IMAGE_PREPROCESS_COMMAND',
             cmd.rstrip() + ' selinux_set_labels; ima_evm_sign_rootfs;')
}

addhandler selinux_image_order_handler
selinux_image_order_handler[eventmask] = "bb.event.RecipeTaskPreProcess"
