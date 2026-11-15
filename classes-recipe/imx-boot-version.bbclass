# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Encode the release version in the 16-bit AHAB software version field
# Derive SW_VERSION from IMX_SECURE_VERSION as major * 10000 + minor * 100 + patch
#
# Examples:
#   0.1.0                        -> 100
#   1.2.3                        -> 10203
#   1.2.3-rc.1                   -> 10203
#   v1.2.3-4-gabcdef0-dirty      -> 10203
#   1.2.3+build.7                -> 10203
#   1.10.0                       -> 11000
#
# Ignore the optional v prefix and everything after major.minor.patch
# Prerelease, release and Git builds with the same core share SW_VERSION
# Minor and patch must be below 100, and the result must fit in 0..65535
# For example, 6.55.35 fits, while 6.55.36 and 1.100.0 fail
# Bare Git hashes and versions without major.minor.patch need an override
# Overrides must still fit in 16 bits with no leading zeros in decimal values
def imx_boot_sw_version(d):
    import re

    version = d.getVar("IMX_SECURE_VERSION") or ""
    match = re.match(
        r"v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
        r"(?![0-9])", version)
    if not match:
        bb.fatal("Cannot derive SW_VERSION from IMX_SECURE_VERSION %r\n"
                 "Use a major.minor.patch release tag or set SW_VERSION explicitly" % version)

    major, minor, patch = map(int, match.groups())
    if minor > 99 or patch > 99:
        bb.fatal("Cannot encode IMX_SECURE_VERSION %r: minor and patch must be below 100\n"
                 "Set SW_VERSION explicitly to use another numbering scheme" % version)
    return str(major * 10000 + minor * 100 + patch)

SW_VERSION ?= "${@imx_boot_sw_version(d)}"

python __anonymous() {
    import re

    version = d.getVar("SW_VERSION") or ""
    if not re.fullmatch(r"(?:0|[1-9][0-9]*|0[xX][0-9a-fA-F]+)", version):
        bb.fatal("SW_VERSION must be a decimal integer without leading zeros or a hex integer")
    if not 0 <= int(version, 0) <= 65535:
        bb.fatal("SW_VERSION %s is outside the AHAB range 0 to 65535\n"
                 "Set SW_VERSION explicitly to use another numbering scheme" % version)
}
