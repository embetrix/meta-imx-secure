# SPDX-License-Identifier: MIT
SUMMARY = "NXP SPSDK image signing tools"
HOMEPAGE = "https://github.com/nxp-mcuxpresso/spsdk"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=71f9dfe2f5397e150a180724f0270d11"

SRC_URI += "file://0001-use-yocto-dependencies.patch"

SRC_URI[sha256sum] = "a98c6a9054c6aeb544e8bdc7ee00e08d2dcc6f9b7998da5b7dd4c71f07dcd46f"

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
    python3-crcmod \
    python3-cryptography \
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
    python3-setuptools \
    python3-setuptools-scm \
    python3-sly \
    python3-typing-extensions \
    python3-x690 \
"

BBCLASSEXTEND = "native"
