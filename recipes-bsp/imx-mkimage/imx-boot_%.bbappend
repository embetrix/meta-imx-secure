# SPDX-License-Identifier: MIT

inherit_defer ${@bb.utils.contains('IMX_SIGN_ENABLE', '1', 'imx-boot-sign', '', d)}
