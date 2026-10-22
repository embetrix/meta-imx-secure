# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>
#
# Sign and verify i.MX8/9 AHAB boot images using SPSDK
# AHAB only, HABv4 signing is not implemented
# Family and revision support depends on the installed SPSDK version
#
# Sign OEM containers and preserve NXP and V2X containers
# Verify signatures, image hashes and unchanged payloads before deployment
# Deploy signed images under the normal imx-boot filenames
# This class does not program SRK hash fuses or change the device lifecycle
#
# Enable in local.conf or distro configuration:
# Generate keys and a kas fragment with tools/genkey-helper.sh <KEY_DIR>
# IMX_SIGN_ENABLE = "1"
# IMX_SIGN_KEYDIR = "/path/to/signing-keys"
# Set IMX_SIGN_DEBUG = "1" to show signing details in the build console
#
# Generate ahab-sign.yaml from the template below and the machine settings
# Default keys are srk0.pub through srk3.pub and srk0.pem
# Set IMX_SIGN_SRK_ID to select another private key
# Override IMX_SIGN_PRIVATE_KEY and IMX_SIGN_SRK_FILES for other filenames
# Set IMX_SIGN_CONFIG only when supplying a custom YAML file
# Override IMX_SPSDK_FAMILY and IMX_SPSDK_REVISION for a specific SPSDK profile
# List profiles with nxpimage ahab get-families -c get-template
# Keep all referenced keys inside IMX_SIGN_KEYDIR so key changes trigger signing
# Encryption, certificate delegation and PQC signing are not supported yet
# The u-boot-imx bbappend enables boot authentication when signing is enabled

inherit imx-signing-keys

# Match specific SoCs before shared BSP overrides
def imx_sign_soc(d):
    overrides = (d.getVar("MACHINEOVERRIDES") or "").split(":")
    for soc in ("mx937", "mx952", "mx943", "mx95", "mx93", "mx91",
                "mx8ulp", "mx8dxl", "mx8dx", "mx8qxp", "mx8qm",
                "mx8mp", "mx8mn", "mx8mm", "mx8mq"):
        if soc in overrides or soc + "-generic-bsp" in overrides:
            return soc
    return ""

IMX_SIGN_SOC ??= "${@imx_sign_soc(d)}"
IMX_SIGN_FORMAT ??= "${@'hab4' if d.getVar('IMX_SIGN_SOC') in ('mx8mq', 'mx8mm', 'mx8mn', 'mx8mp') else ('ahab' if d.getVar('IMX_SIGN_SOC') else '')}"
IMX_SIGN_BACKEND ??= "${@{'ahab': 'spsdk', 'hab4': 'cst'}.get(d.getVar('IMX_SIGN_FORMAT'), '')}"

def imx_sign_family(d):
    return {
        "mx8qm": "mimx8qm",
        "mx8qxp": "mimx8qxp",
        "mx8dx": "mimx8qxp",
        "mx8dxl": "mimx8dxl",
        "mx8ulp": "mimx8ulp",
        "mx91": "mimx9131",
        "mx93": "mimx9352",
        "mx937": "mimx93754",
        "mx943": "mimx943",
        "mx95": "mimx9596",
        "mx952": "mimx95294",
    }.get(d.getVar("IMX_SIGN_SOC"), "")

def imx_sign_revision(d):
    # SPSDK uses one a0 profile for these families, separate from the BSP silicon revision
    if d.getVar("IMX_SIGN_SOC") in ("mx8qm", "mx8qxp", "mx8dx", "mx8dxl"):
        return "a0"
    return (d.getVar("IMX_SOC_REV") or "").lower()

IMX_SPSDK_FAMILY ??= "${@imx_sign_family(d)}"
IMX_SPSDK_REVISION ??= "${@imx_sign_revision(d)}"

# Raw SD/eMMC flash.bin files start at the container, without disk padding
# Set a UBOOT_CONFIG flag for other layouts, for example [fspi] = "flexspi_nor"
IMX_SPSDK_MEMORY_TYPE ??= "serial_downloader"

IMX_SIGN_DEBUG ??= "0"
IMX_SIGN_UNSIGNED_DIR = "${WORKDIR}/imx-boot-unsigned"
IMX_SIGN_OUTPUT_DIR = "${WORKDIR}/imx-boot-signed"

def imx_sign_images(d):
    configs = (d.getVar("UBOOT_CONFIG") or "").split()
    targets = (d.getVar("IMXBOOT_TARGETS") or "").split()
    if not configs or not targets:
        bb.fatal("imx-boot signing needs UBOOT_CONFIG and IMXBOOT_TARGETS")
    for config in configs:
        for target in targets:
            name = "imx-boot%s-%s-%s.bin-%s" % (
                d.getVar("BOOT_VARIANT") or "", d.getVar("MACHINE"), config, target)
            yield config, name

def imx_sign_config(d):
    import json
    import os
    import textwrap
    from pathlib import Path

    if d.getVar("IMX_SIGN_CONFIG"):
        return d.getVar("IMX_SIGN_CONFIG")
    keydir = d.getVar("IMX_SIGN_KEYDIR")
    values = {
        "IMX_SPSDK_FAMILY": d.getVar("IMX_SPSDK_FAMILY"),
        "IMX_SPSDK_REVISION": d.getVar("IMX_SPSDK_REVISION"),
        "IMX_SIGN_SRK_ID": int(d.getVar("IMX_SIGN_SRK_ID")),
        "IMX_SIGN_PRIVATE_KEY": os.path.join(keydir, d.getVar("IMX_SIGN_PRIVATE_KEY")),
        "IMX_SIGN_SRK_FILES": [os.path.join(keydir, key)
                               for key in d.getVar("IMX_SIGN_SRK_FILES").split()],
    }
    template = textwrap.dedent("""\
        family: @IMX_SPSDK_FAMILY@
        revision: @IMX_SPSDK_REVISION@
        srk_set: oem
        used_srk_id: @IMX_SIGN_SRK_ID@
        signer: @IMX_SIGN_PRIVATE_KEY@
        srk_table:
          flag_ca: false
          srk_array: @IMX_SIGN_SRK_FILES@
        """)
    for name, value in values.items():
        template = template.replace("@" + name + "@", json.dumps(value))
    output = Path(d.getVar("T"), "ahab-sign.yaml")
    output.write_text(template)
    return str(output)

python imx_sign_save_unsigned() {
    import shutil

    for config, name in imx_sign_images(d):
        source = os.path.join(d.getVar("S"), name)
        if not os.path.isfile(source):
            bb.fatal("Missing boot image: %s" % source)
        shutil.copy2(source, os.path.join(d.getVar("IMX_SIGN_UNSIGNED_DIR"), name))
}

python do_imx_boot_sign() {
    import shutil
    import subprocess
    import textwrap

    debug = d.getVar("IMX_SIGN_DEBUG") == "1"
    sign_config = imx_sign_config(d)
    if debug:
        bb.verbnote("imx-boot signing: SoC=%s format=%s backend=%s family=%s revision=%s" % (
            d.getVar("IMX_SIGN_SOC"), d.getVar("IMX_SIGN_FORMAT"),
            d.getVar("IMX_SIGN_BACKEND"), d.getVar("IMX_SPSDK_FAMILY"),
            d.getVar("IMX_SPSDK_REVISION")))
        bb.verbnote("Signing configuration: %s" % sign_config)

    command = [
        os.path.join(d.getVar("STAGING_BINDIR_NATIVE"), "python3-native", "python3"),
        "-",
        "--config", sign_config,
        "--key-dir", d.getVar("IMX_SIGN_KEYDIR"),
        "--family", d.getVar("IMX_SPSDK_FAMILY"),
        "--revision", d.getVar("IMX_SPSDK_REVISION"),
    ]
    environment = os.environ.copy()
    environment["PYTHONNOUSERSITE"] = "1"
    environment["SPSDK_CACHE_FOLDER"] = os.path.join(d.getVar("T"), "spsdk-cache")
    environment["SPSDK_DEBUG_LOG_FILE"] = os.path.join(d.getVar("T"), "spsdk-debug.log")
    images = list(imx_sign_images(d))
    for config, name in images:
        memory = d.getVarFlag("IMX_SPSDK_MEMORY_TYPE", config) or d.getVar("IMX_SPSDK_MEMORY_TYPE")
        source = os.path.join(d.getVar("IMX_SIGN_UNSIGNED_DIR"), name)
        output = os.path.join(d.getVar("IMX_SIGN_OUTPUT_DIR"), name)
        bb.note("Signing %s (%s, %s, %s)" % (
            name, d.getVar("IMX_SPSDK_FAMILY"), d.getVar("IMX_SPSDK_REVISION"), memory))
        if debug:
            bb.verbnote("Signing %s -> %s (memory type: %s)" % (source, output, memory))
        subprocess.run(command + [
            "--memory-type", memory,
            "--input", source,
            "--output", output,
        ], input=textwrap.dedent(d.getVar("imx_sign_ahab")), text=True,
            check=True, env=environment)
        if debug:
            bb.verbnote("Verified signatures and unchanged payloads: %s" % output)

    # Publish only after every variant has passed verification
    for config, name in images:
        destination = os.path.join(d.getVar("S"), name)
        shutil.copy2(os.path.join(d.getVar("IMX_SIGN_OUTPUT_DIR"), name), destination + ".signed")
        os.replace(destination + ".signed", destination)
        if debug:
            bb.verbnote("Signed boot image ready for install and deploy: %s" % destination)
}
do_imx_boot_sign[cleandirs] = "${IMX_SIGN_OUTPUT_DIR}"
do_imx_boot_sign[vardeps] += "IMX_SPSDK_MEMORY_TYPE UBOOT_CONFIG IMXBOOT_TARGETS BOOT_VARIANT MACHINE"

python __anonymous() {
    imx_validate_signing_keys(d)
    if d.getVar("IMX_SIGN_ENABLE") != "1":
        return
    if d.getVar("IMX_SIGN_FORMAT") == "hab4":
        bb.fatal("HABv4 signing needs CST and is not implemented yet")
    if (d.getVar("IMX_SIGN_FORMAT") != "ahab" or
            d.getVar("IMX_SIGN_BACKEND") != "spsdk"):
        bb.fatal("AHAB signing needs IMX_SIGN_FORMAT = 'ahab' and IMX_SIGN_BACKEND = 'spsdk'")
    if not d.getVar("IMX_SPSDK_FAMILY") or d.getVar("IMX_SPSDK_REVISION") in ("", "latest"):
        bb.fatal("Set IMX_SPSDK_FAMILY and an explicit IMX_SPSDK_REVISION")
    # BitBake does not walk directory symlinks when hashing inputs
    d.setVar("IMX_SIGN_KEYDIR", os.path.realpath(d.getVar("IMX_SIGN_KEYDIR")))

    d.appendVar("DEPENDS", " python3-spsdk-native")
    d.appendVarFlag("do_compile", "cleandirs", " " + d.getVar("IMX_SIGN_UNSIGNED_DIR"))
    d.appendVarFlag("do_compile", "postfuncs", " imx_sign_save_unsigned")
    d.appendVarFlag("do_imx_boot_sign", "file-checksums", " %s:True" % d.getVar("IMX_SIGN_KEYDIR"))
    if d.getVar("IMX_SIGN_CONFIG"):
        d.appendVarFlag("do_imx_boot_sign", "file-checksums", " %s:True" % d.getVar("IMX_SIGN_CONFIG"))
    bb.build.addtask("do_imx_boot_sign", "do_install do_deploy", "do_compile", d)
}

python imx_sign_ahab() {
    import argparse
    from pathlib import Path

    from spsdk.exceptions import SPSDKError
    from spsdk.image.ahab.ahab_data import FlagsSrkSet
    from spsdk.image.ahab.ahab_image import AHABImage
    from spsdk.image.ahab.utils import ahab_sign_image
    from spsdk.image.bootable_image.bimg import BootableImage
    from spsdk.image.bootable_image.segments import SegmentAhab
    from spsdk.image.mem_type import MemoryType
    from spsdk.utils.config import Config
    from spsdk.utils.family import FamilyRevision
    from spsdk.utils.verifier import VerifierResult


    def load_config(path, key_dir, family, revision):
        family = FamilyRevision(family, revision).name
        supported = {device.name for device in AHABImage.get_supported_families()}
        if family not in supported:
            raise ValueError(f"Installed SPSDK does not support AHAB for {family}")
        config = Config.create_from_file(str(path))
        if "family" in config:
            config["family"] = FamilyRevision(config["family"], revision).name
        for name, expected in (("family", family), ("revision", revision)):
            if name in config and config[name] != expected:
                raise ValueError(f"Signing config {name} must match {expected}")
            config[name] = expected
        if revision == "latest":
            raise ValueError("Set an explicit silicon revision")
        if config.get("srk_set") != "oem":
            raise ValueError("Signing config must set srk_set: oem")
        if any(name in config for name in ("blob", "certificate", "signer_#2")):
            raise ValueError("Encryption, certificate delegation and PQC are not supported")
        table = config.get("srk_table", {})
        if "srk_table_#2" in table:
            raise ValueError("PQC signing is not supported")
        keys = table.get("srk_array", [])
        if len(keys) != 4:
            raise ValueError("srk_table.srk_array must contain four public keys or certificates")

        def key_path(value):
            if not isinstance(value, str) or not value or ";" in value or value.startswith("type="):
                raise ValueError("Use local key paths in signer and srk_table.srk_array")
            resolved = (path.parent / value).resolve()
            if not resolved.is_relative_to(key_dir.resolve()) or not resolved.is_file():
                raise ValueError(f"Signing key must be a file inside IMX_SIGN_KEYDIR: {value}")
            return str(resolved)

        config["signer"] = key_path(config.get("signer"))
        table["srk_array"] = [key_path(key) for key in keys]
        config.check(AHABImage.get_signing_validation_schemas(FamilyRevision(family, revision)),
                     check_unknown_props=True)
        return config


    def containers(image):
        return [container for segment in image.segments if isinstance(segment, SegmentAhab)
                for container in segment.ahab.ahab_containers]


    def signable(container):
        # SPSDK leaves vendor V2X containers unchanged too
        return (container.flag_srk_set in (FlagsSrkSet.NONE, FlagsSrkSet.OEM)
                and not any("v2x" in image.flags_core_id_name for image in container.image_array))


    def sign_image(config, source, destination, memory_type):
        family = FamilyRevision.load_from_config(config)
        memory = MemoryType.from_label(memory_type)
        original = BootableImage.parse(source.read_bytes(), family=family, mem_type=memory)
        before = containers(original)
        oem = [c for c in before if signable(c)]
        if not oem:
            raise ValueError("Boot image has no OEM containers to sign")
        if any(image.flags_is_encrypted for c in oem for image in c.image_array):
            raise ValueError("Encrypted OEM images are not supported")
        data, _ = ahab_sign_image(str(source), config, memory_type)

        # Verify the exported bytes, including signatures and image hashes
        signed = BootableImage.parse(data, family=family, mem_type=memory)
        signed.verify().validate()
        after = containers(signed)
        if len(before) != len(after):
            raise ValueError("Signing changed the container count")
        for old, new in zip(before, after):
            if ([(i.export(), i.image) for i in old.image_array] !=
                    [(i.export(), i.image) for i in new.image_array]):
                raise ValueError("Signing changed image data or metadata")
            if signable(old):
                if new.flag_srk_set != FlagsSrkSet.OEM:
                    raise ValueError("An OEM container was left unsigned")
                # SPSDK treats dummy or unverifiable signatures as warnings
                authenticity = new.signature_block.verify_container_authenticity(
                    new.get_signature_data())
                if authenticity.result != VerifierResult.SUCCEEDED:
                    raise ValueError(f"OEM signature verification did not succeed:\n{authenticity}")
            elif old.export() != new.export():
                raise ValueError("Signing changed a non-OEM container")
        destination.write_bytes(data)


    def main():
        parser = argparse.ArgumentParser(description=__doc__)
        for option in ("config", "key-dir", "input", "output"):
            parser.add_argument("--" + option, type=Path, required=True)
        for option in ("family", "revision", "memory-type"):
            parser.add_argument("--" + option, required=True)
        args = parser.parse_args()
        try:
            config = load_config(args.config, args.key_dir, args.family, args.revision)
            sign_image(config, args.input, args.output, args.memory_type)
        except (SPSDKError, ValueError, OSError) as error:
            parser.exit(1, f"imx-boot signing failed: {error}\n")


    if __name__ == "__main__":
        main()
}
