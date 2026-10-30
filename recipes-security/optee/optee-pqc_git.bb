# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "Experimental post-quantum cryptography for OP-TEE"
HOMEPAGE = "https://github.com/embetrix/optee-pqc"
LICENSE = "BSD-2-Clause & BSD-3-Clause"
LIC_FILES_CHKSUM = " \
    file://LICENSE;md5=b2afbf75a2458dfa60426cd39a9d35cc \
    file://external/leancrypto/LICENSE;md5=b00845406d87e919d7995d9b51e06861 \
    file://external/leancrypto/LICENSE.bsd;md5=66a5cedaf62c4b2637025f049f9b826f \
"

# The source commit also pins the leancrypto submodule
SRC_URI = "gitsm://github.com/embetrix/optee-pqc.git;protocol=https;branch=main"
SRCREV = "fa58b54acb280d61848dbe760b5cbb9b9ee12527"
PV = "0.1+git"

inherit cmake python3native features_check

REQUIRED_MACHINE_FEATURES = "optee"
DEPENDS = "optee-client optee-os-tadevkit meson-native ninja-native \
           python3-cryptography-native python3-pyelftools-native"
RDEPENDS:${PN} += "optee-client ${VIRTUAL-RUNTIME_base-utils}"
PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_HOST = "(arm|aarch64).*-linux"

PQC_TA_UUID = "7b1e6f40-9c32-4da8-a567-71930c4e82b6"
PQC_TA_DEV_KIT ?= "${STAGING_INCDIR}/optee/export-user_ta"
PQC_TA_CROSS_COMPILE ?= "${HOST_PREFIX}"

EXTRA_OECMAKE = " \
    -DPQC_BUILD_CLIENT=ON \
    -DPQC_BUILD_TA=ON \
    -DPQC_TA_DEV_KIT=${PQC_TA_DEV_KIT} \
    -DPQC_TA_CROSS_COMPILE=${PQC_TA_CROSS_COMPILE} \
    -DPQC_TA_INSTALL_DIR=${nonarch_base_libdir}/optee_armtz \
"

# Keep Linux flags out of the TA build, which uses the devkit's ABI settings
CFLAGS[unexport] = "1"
CXXFLAGS[unexport] = "1"
CPPFLAGS[unexport] = "1"
LDFLAGS[unexport] = "1"
AS[unexport] = "1"
LD[unexport] = "1"

export OPENSSL_MODULES = "${STAGING_LIBDIR_NATIVE}/ossl-modules"
# Let the TA devkit find libgcc in the target sysroot
export LIBGCC_LOCATE_CFLAGS = "--sysroot=${STAGING_DIR_HOST}"

do_install:append() {
    # OP-TEE embeds the ELF instead of loading a TA from the root filesystem
    rm -f ${D}${nonarch_base_libdir}/optee_armtz/${PQC_TA_UUID}.ta
    rmdir ${D}${nonarch_base_libdir}/optee_armtz
    install -D -m 0644 ${B}/ta/${PQC_TA_UUID}.stripped.elf \
        ${D}${datadir}/optee-pqc/${PQC_TA_UUID}.stripped.elf
    install -D -m 0755 ${S}/tests/optee-pqc-test.sh ${D}${bindir}/optee-pqc-test
}

PACKAGES =+ "${PN}-early-ta"
FILES:${PN}-early-ta = "${datadir}/optee-pqc/${PQC_TA_UUID}.stripped.elf"
INHIBIT_PACKAGE_STRIP_FILES = "${PKGD}${datadir}/optee-pqc/${PQC_TA_UUID}.stripped.elf"
