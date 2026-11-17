# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit swupdate

SWU_IMAGE ?= "${@d.getVar('PN').removesuffix('-update')}"
SRC_URI = "file://sw-description"
IMAGE = "${SWU_IMAGE}"
IMAGE_DEPENDS = "${SWU_IMAGE}"
IMX_SWUPDATE_FIT_IMAGE ?= "${@bb.utils.contains('IMX_FIT_AHAB_ENABLE', '1', 'fitImage.ahab', 'fitImage', d)}"
SWUPDATE_IMAGES = " ${IMX_BOOTLOADER} ${IMX_SWUPDATE_FIT_IMAGE} ${SWU_IMAGE}"
# Let swugenerator create a fresh IV for each payload and add it to the manifest
SWUPDATE_UNIQUE_IV = "1"

python () {
    img = d.getVar('SWU_IMAGE')
    if not img:
        bb.fatal('SWU_IMAGE must be set before requiring imx-secure-image-update.inc')
    d.setVarFlag('SWUPDATE_IMAGES_FSTYPES', img, '-${MACHINE}.rootfs.${ROOTFS_TYPE}.avbverity.gz')
    d.setVarFlag('SWUPDATE_IMAGES_ENCRYPTED', img, '1')
    d.setVarFlag('SWUPDATE_IMAGES_ENCRYPTED', d.getVar('IMX_SWUPDATE_FIT_IMAGE'), '1')
    d.setVarFlag('SWUPDATE_IMAGES_ENCRYPTED', d.getVar('IMX_BOOTLOADER'), '1')
}

python imx_check_swu_keys() {
    imx_validate_swupdate_keys(d, private=True)
}

python imx_check_swu_bootloader() {
    import os

    filename = d.getVar('IMX_BOOTLOADER')
    path = os.path.join(d.getVar('DEPLOY_DIR_IMAGE'), filename)
    if not os.path.isfile(path):
        bb.fatal('Boot firmware is missing: %s' % path)
    size = os.path.getsize(path)
    limit = int(d.getVar('IMX_BOOT_MAX_SIZE'), 0)
    if not 0 < size <= limit:
        bb.fatal('%s is %d bytes, expected 1..%d bytes (IMX_BOOT_MAX_SIZE)' %
                 (filename, size, limit))
}

python do_swuimage:prepend() {
    import os

    artifacts = d.getVar('SWUPDATE_ARTIFACTS_DIR')
    bb.utils.mkdirhier(artifacts)
    # Generate after task cleanup so the payload survives until packaging
    # Clear the whole firmware area, including headers from older images
    with open(os.path.join(artifacts, 'imx-boot-zeros'), 'wb') as stream:
        stream.truncate(int(d.getVar('IMX_BOOT_MAX_SIZE'), 0))
}

do_swuimage[prefuncs] += "imx_check_swu_keys imx_check_swu_bootloader"
do_swuimage[depends] += "linux-yocto-fitimage:do_deploy imx-boot:do_deploy"
do_swuimage[file-checksums] += "${@imx_swupdate_key_checksums(d, private=True)}"
