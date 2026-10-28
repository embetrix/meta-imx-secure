# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "NXP SPSDK image signing tools"
HOMEPAGE = "https://github.com/nxp-mcuxpresso/spsdk"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=863e3c0c79e2589ac9d16c3918e115d1"

SRC_URI += "file://0001-use-yocto-dependencies.patch"

SRC_URI[sha256sum] = "cca81c81fc6a8614ac38ef974b17da2d41ae2f51e8ab8cf952ab7849dfd6174c"

inherit pypi python_setuptools_build_meta dos2unix

DEPENDS += "python3-setuptools-scm-native"

do_convert_crlf_to_lf() {
    dos2unix ${S}/requirements.txt ${S}/pyproject.toml ${S}/spsdk/apps/utils/common_cli_options.py
}

RDEPENDS:${PN} += " \
    python3-asn1crypto \
    python3-bincopy \
    python3-bitstring \
    python3-chardet \
    python3-click \
    python3-click-command-tree \
    python3-click-option-group \
    python3-colorama \
    python3-crcmod-plus \
    python3-cryptography (>= 48.0.1) \
    python3-deepmerge \
    python3-fastjsonschema \
    python3-filelock \
    python3-hexdump \
    python3-importlib-metadata \
    python3-libusbsio \
    python3-modules \
    python3-packaging \
    python3-platformdirs \
    python3-prettytable \
    python3-pyasn1 \
    python3-pyserial \
    python3-pyyaml \
    python3-requests \
    python3-ruamel-yaml \
    python3-setuptools (>= 83.0.0) \
    python3-setuptools-scm \
    python3-sly \
    python3-typing-extensions \
    python3-x690 \
"

BBCLASSEXTEND = "native"
