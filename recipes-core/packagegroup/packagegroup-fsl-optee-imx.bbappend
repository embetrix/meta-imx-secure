# SPDX-License-Identifier: MIT

RDEPENDS:${PN}:remove = "${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'optee-test', '', d)}"
