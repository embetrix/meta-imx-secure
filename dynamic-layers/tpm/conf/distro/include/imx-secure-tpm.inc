# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

DISTRO_FEATURES:append = " ${@bb.utils.contains_any('MACHINE_FEATURES', 'optee-ftpm tpm2', 'tpm2', '', d)}"

MACHINE_EXTRA_RRECOMMENDS:append = " ${@bb.utils.contains_any('MACHINE_FEATURES', 'optee-ftpm tpm2', \
    bb.utils.contains('DISTRO_FEATURES', 'tpm2', 'packagegroup-security-tpm2', '', d), '', d)}"

# Allow meta-tpm to stay in the build when TPM support is disabled
SKIP_META_TPM_SANITY_CHECK ?= "${@bb.utils.contains_any('MACHINE_FEATURES', 'optee-ftpm tpm2', '0', '1', d)}"
