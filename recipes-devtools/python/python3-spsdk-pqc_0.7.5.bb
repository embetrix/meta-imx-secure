# SPDX-License-Identifier: MIT
SUMMARY = "Post-quantum crypto support for NXP SPSDK"
HOMEPAGE = "https://github.com/nxp-mcuxpresso/spsdk_plugins/tree/master/pqc"
LICENSE = "BSD-3-Clause & MIT & CC0-1.0 & PD"
LIC_FILES_CHKSUM = " \
    file://LICENSE;md5=fe2a425fb1f291c670f58b9e3771878e \
    file://ref/LICENSE.txt;md5=4b93ef2da47496727a4e8a59f443844e \
    file://ref/src/sig/dilithium/oldpqclean_dilithium3_aarch64/LICENSE;md5=65d3616852dbf7b1a6d4b53b00626032 \
    file://ref/src/sig/ml_dsa/pqcrystals-dilithium-standard_ml-dsa-65_ref/LICENSE;md5=797e50ad95293bd4f6734e0645e589a3 \
    file://ref/src/common/sha2/sha2_c.c;beginline=1;endline=1;md5=f5083c31156cf1f709aa79844d486668 \
"

SRC_URI[sha256sum] = "1b3b98cd9f82e1e435ba2a76fa9623fd6620d4ef93ca3871185492c23c824ab8"

PYPI_PACKAGE = "spsdk_pqc"

inherit pypi cmake python_setuptools_build_meta

# Pass Yocto's toolchain to CMake invoked by setup.py
export CMAKE_TOOLCHAIN_FILE = "${WORKDIR}/toolchain.cmake"
export CMAKE_GENERATOR = "${OECMAKE_GENERATOR}"

RDEPENDS:${PN} += " \
    python3-click \
    python3-cryptography \
    python3-ctypes \
    python3-logging \
    python3-pyasn1 \
    python3-pycryptodome \
    python3-spsdk (>= 3.10.0) \
    python3-typing-extensions \
"

BBCLASSEXTEND = "native"
