# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Leave out the Python TPM bindings in production
RDEPENDS:packagegroup-security-tpm2:remove = "${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'python3-tpm2-pytss', '', d)}"
