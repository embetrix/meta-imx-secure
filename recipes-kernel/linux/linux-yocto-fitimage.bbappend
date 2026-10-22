# SPDX-License-Identifier: MIT

# NXP machine settings can list the same DTB more than once
python do_compile:prepend() {
    d.setVar("KERNEL_DEVICETREE", " ".join(dict.fromkeys(d.getVar("KERNEL_DEVICETREE").split())))
}
