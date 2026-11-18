# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://swupdate.cfg"
RDEPENDS:${PN}:append = " libubootenv-config"

python imx_install_swupdate_keys() {
    import os
    import shutil

    imx_validate_swupdate_keys(d)
    dest = d.getVar('D') + d.getVar('sysconfdir')
    config = os.path.join(dest, 'swupdate')
    bb.utils.mkdirhier(config)
    shutil.copyfile(os.path.join(d.getVar('UNPACKDIR'), 'swupdate.cfg'),
                    os.path.join(config, 'swupdate.cfg'))
    shutil.copyfile(d.getVar('SWUPDATE_CMS_CERT'), os.path.join(config, 'swupdate.crt'))
    for name in ('swupdate.cfg', 'swupdate.crt'):
        os.chmod(os.path.join(config, name), 0o644)
    # WARNING: Store the key from SWUPDATE_AES_FILE in secure storage for production
    # and use it from there!
    # This currently installs it as a plain file in the root filesystem
    # OP-TEE PKCS#11 alternative: enable CONFIG_PKCS11 with p11-kit and set
    # decrypt-provider = "pkcs11" then install a key file containing the
    # provisioned key's PKCS#11 URI (libckteec.so.0) and IV instead of the plain key
    # https://sbabic.github.io/swupdate/encrypted_images.html#decrypting-with-a-pkcs-11-token
    with open(d.getVar('SWUPDATE_AES_FILE')) as stream:
        aes = dict(line.strip().split('=', 1) for line in stream if line.strip())
    keyfile = os.path.join(config, 'swupdate-aes.key')
    with open(keyfile, 'w') as stream:
        stream.write('%s %s\n' % (aes['key'], aes['iv']))
    os.chmod(keyfile, 0o400)
    with open(os.path.join(dest, 'hwrevision'), 'w') as stream:
        stream.write('imx-secure %s\n' % d.getVar('MACHINE'))
    os.chmod(os.path.join(dest, 'hwrevision'), 0o644)
}

do_install[postfuncs] += "imx_install_swupdate_keys"
do_install[file-checksums] += "${@imx_swupdate_key_checksums(d)}"
FILES:${PN}:append = " ${sysconfdir}/swupdate ${sysconfdir}/hwrevision"
