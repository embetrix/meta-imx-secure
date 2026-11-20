# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://swupdate.cfg"
DEPENDS:append = " p11-kit"
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
    # Token-backed decryption requires decrypt-provider = "pkcs11"
    # The runtime key file contains the provisioned key URI followed by the IV
    # https://sbabic.github.io/swupdate/encrypted_images.html#decrypting-with-a-pkcs-11-token
    with open(d.getVar('SWUPDATE_AES_FILE')) as stream:
        aes = dict(line.strip().split('=', 1) for line in stream if line.strip())
    if d.getVar('IMX_SECURITY_PROFILE') == 'prod' and not aes['key'].startswith('pkcs11:'):
        bb.warn('SWUpdate installs a plaintext AES key in the production image. '
                'Provision the same key in an SMW or OP-TEE PKCS#11 token and use '
                'its URI in the runtime AES key file and '
                'set decrypt-provider = "pkcs11". Example SMW URI: '
                'pkcs11:token=smw;id=%14%37%04%28%e6%9c%7c%dd;'
                'object=swupdate-aes-key-14370428e69c7cdd;type=secret-key '
                'or OP-TEE: pkcs11:token=optee;id=%01;object=swupdate-aes-key;'
                'type=secret-key. Replace the token, ID and label with the '
                'provisioned values and configure the matching PKCS#11 module. '
                'Keep SWUPDATE_AES_FILE for build-time bundle encryption.')
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
