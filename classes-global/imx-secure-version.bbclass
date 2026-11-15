# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

IMX_SECURE_VERSION_PATH ?= "${IMX_SECURE_BASE}"

def imx_secure_version(d):
    import subprocess

    path = d.getVar("IMX_SECURE_VERSION_PATH")
    try:
        return subprocess.check_output(
            ["git", "describe", "--tags", "--always", "--dirty"],
            cwd=path, stderr=subprocess.STDOUT, text=True).strip()
    except (OSError, subprocess.CalledProcessError) as error:
        bb.fatal("Cannot read the Git version from %s: %s\n"
                 "Set IMX_SECURE_VERSION when building without Git metadata" % (path, error))

# Resolve once during parsing, unless a version was supplied
IMX_SECURE_VERSION ?= "${@imx_secure_version(d)}"
IMX_SECURE_VERSION := "${IMX_SECURE_VERSION}"
