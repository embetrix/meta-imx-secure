# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

INHERIT += "${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'trowl', '', d)}"

# Scan the rootfs archive because Trowl does not support EROFS
TROWL_FSTYPES ?= "tar.zst"
TROWL_LLM ?= "0"
