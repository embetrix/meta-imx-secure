# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>
#
# Sign and verify i.MX8/9 AHAB boot images using SPSDK:
# https://github.com/nxp-mcuxpresso/spsdk
# AHAB only, HABv4 signing is not implemented
# Family and revision support depends on the installed SPSDK version
#
# Sign unsigned and OEM containers, preserving NXP and V2X containers
# Verify OEM signatures, image hashes and unchanged image data and metadata
# Keep unsigned build outputs and deploy verified copies as <image>.sign
# Deploy imx-boot.sign and imx-boot.tagged.sign for the BSP's default image
# Deploy SPSDK SRK hashes and fuse scripts in <image>.sign.fuses/
# This class does not program SRK hash fuses or change the device lifecycle
#
# Generate keys and a kas fragment with tools/genkey-helper.sh <KEY_DIR>, then run:
# kas build kas-imx-secure.yml:kas-signing-keys.yml
# Or enable in local.conf or distro configuration with existing keys:
# INHERIT += "imx-signing-keys"
# IMX_SIGN_ENABLE = "1"
# IMX_SIGN_KEYDIR = "/path/to/signing-keys"
# Set IMX_SIGN_DEBUG = "1" to show signing details in the build console
#
# By default, generate ${T}/ahab-sign.yaml from the settings below
# IMX_SIGN_SRK_FILES lists exactly four public keys or certificates in SRK order
# Defaults are srk0.pub through srk3.pub inside IMX_SIGN_KEYDIR
# IMX_SIGN_SRK_ID selects entry 0 to 3 and defaults to 0
# IMX_SIGN_PRIVATE_KEY defaults to srk${IMX_SIGN_SRK_ID}.pem and must match that entry
# Key paths may be absolute or relative to their configured key directory
# Keys must stay inside that directory so changes trigger signing
# Private keys must be local, unencrypted files
#
# Set IMX_SIGN_PQC_ENABLE = "1" to add a second SRK table and signer
# IMX_SIGN_PQC_KEYDIR defaults to ${IMX_SIGN_KEYDIR}/mldsa
# IMX_SIGN_PQC_SRK_FILES and IMX_SIGN_PQC_PRIVATE_KEY use the same naming defaults
# Both tables use IMX_SIGN_SRK_ID to select the signing key
# IMX_SIGN_HASH_ALGORITHM defaults to "default", IMX_SIGN_PQC_HASH_ALGORITHM to "sha3_512"
#
# IMX_SIGN_CONFIG selects a custom YAML file instead of the generated settings
# It must set srk_set: oem, with family and revision matching the build if supplied
# Relative key paths in custom YAML are resolved from the YAML directory
# Keys must still be inside IMX_SIGN_KEYDIR or the enabled IMX_SIGN_PQC_KEYDIR
# Key directories and IMX_SIGN_CONFIG must be absolute paths without spaces or colons
#
# IMX_SPSDK_FAMILY and IMX_SPSDK_REVISION default to the machine's SoC settings
# Override them for a specific SPSDK profile, using an explicit revision, not "latest"
# List profiles with nxpimage ahab get-families -c get-template
# SoC formats, SPSDK profiles and PQC revisions are listed in imx_sign_soc_data
# Second key sets require a listed family/revision pair and AHAB v2 OEM containers
# Encryption and certificate delegation are not supported yet
# The u-boot-imx bbappend enables boot authentication when signing is enabled

IMX_SIGN_ENABLE ??= "0"
IMX_SIGN_KEYDIR ??= ""
IMX_SIGN_CONFIG ??= ""
IMX_SIGN_SRK_ID ??= "0"
IMX_SIGN_PRIVATE_KEY ??= "${IMX_SIGN_KEYDIR}/srk${IMX_SIGN_SRK_ID}.pem"
IMX_SIGN_SRK_FILES ??= "${IMX_SIGN_KEYDIR}/srk0.pub \
                        ${IMX_SIGN_KEYDIR}/srk1.pub \
                        ${IMX_SIGN_KEYDIR}/srk2.pub \
                        ${IMX_SIGN_KEYDIR}/srk3.pub"
IMX_SIGN_HASH_ALGORITHM ??= "default"

IMX_SIGN_PQC_ENABLE ??= "0"
IMX_SIGN_PQC_KEYDIR ??= "${IMX_SIGN_KEYDIR}/mldsa"
IMX_SIGN_PQC_PRIVATE_KEY ??= "${IMX_SIGN_PQC_KEYDIR}/srk${IMX_SIGN_SRK_ID}.pem"
IMX_SIGN_PQC_SRK_FILES ??= "${IMX_SIGN_PQC_KEYDIR}/srk0.pub \
                            ${IMX_SIGN_PQC_KEYDIR}/srk1.pub \
                            ${IMX_SIGN_PQC_KEYDIR}/srk2.pub \
                            ${IMX_SIGN_PQC_KEYDIR}/srk3.pub"
IMX_SIGN_PQC_HASH_ALGORITHM ??= "sha3_512"

# Keep specific SoCs before shared BSP overrides
# revision overrides IMX_SOC_REV for fixed SPSDK profiles
# pqc_revisions lists revisions that support ML-DSA as a second signer
def imx_sign_soc_data():
    return {
        "mx937": {"format": "ahab", "family": "mimx93754"},
        "mx952": {"format": "ahab", "family": "mimx95294", "pqc_revisions": ("a0",)},
        "mx943": {"format": "ahab", "family": "mimx943", "pqc_revisions": ("a1",)},
        "mx95": {"format": "ahab", "family": "mimx9596", "pqc_revisions": ("b0",)},
        "mx93": {"format": "ahab", "family": "mimx9352"},
        "mx91": {"format": "ahab", "family": "mimx9131"},
        "mx8ulp": {"format": "ahab", "family": "mimx8ulp"},
        "mx8dxl": {"format": "ahab", "family": "mimx8dxl", "revision": "a0"},
        "mx8dx": {"format": "ahab", "family": "mimx8qxp", "revision": "a0"},
        "mx8qxp": {"format": "ahab", "family": "mimx8qxp", "revision": "a0"},
        "mx8qm": {"format": "ahab", "family": "mimx8qm", "revision": "a0"},
        "mx8mp": {"format": "hab4"},
        "mx8mn": {"format": "hab4"},
        "mx8mm": {"format": "hab4"},
        "mx8mq": {"format": "hab4"},
    }

def imx_sign_soc(d):
    overrides = (d.getVar("MACHINEOVERRIDES") or "").split(":")
    for soc in imx_sign_soc_data():
        if soc in overrides or soc + "-generic-bsp" in overrides:
            return soc
    return ""

def imx_sign_format(d):
    return imx_sign_soc_data().get(d.getVar("IMX_SIGN_SOC"), {}).get("format", "")

def imx_sign_family(d):
    return imx_sign_soc_data().get(d.getVar("IMX_SIGN_SOC"), {}).get("family", "")

def imx_sign_pqc_profiles():
    return [(soc["family"], revision) for soc in imx_sign_soc_data().values()
            if soc["format"] == "ahab"
            for revision in soc.get("pqc_revisions", ())]

def imx_sign_revision(d):
    return imx_sign_soc_data().get(d.getVar("IMX_SIGN_SOC"), {}).get(
        "revision", (d.getVar("IMX_SOC_REV") or "").lower())

IMX_SIGN_SOC ??= "${@imx_sign_soc(d)}"
IMX_SIGN_FORMAT ??= "${@imx_sign_format(d)}"
IMX_SIGN_BACKEND ??= "${@{'ahab': 'spsdk', 'hab4': 'cst'}.get(d.getVar('IMX_SIGN_FORMAT'), '')}"
IMX_SPSDK_FAMILY ??= "${@imx_sign_family(d)}"
IMX_SPSDK_REVISION ??= "${@imx_sign_revision(d)}"

# Raw SD/eMMC flash.bin files start at the container, without disk padding
# Override per UBOOT_CONFIG entry, for example IMX_SPSDK_MEMORY_TYPE[fspi] = "flexspi_nor"
IMX_SPSDK_MEMORY_TYPE ??= "serial_downloader"

IMX_SIGN_DEBUG ??= "0"
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
        "IMX_SIGN_HASH_ALGORITHM": d.getVar("IMX_SIGN_HASH_ALGORITHM"),
    }
    template = textwrap.dedent("""\
        family: @IMX_SPSDK_FAMILY@
        revision: @IMX_SPSDK_REVISION@
        srk_set: oem
        used_srk_id: @IMX_SIGN_SRK_ID@
        signer: @IMX_SIGN_PRIVATE_KEY@
        srk_table:
          flag_ca: false
          hash_algorithm: @IMX_SIGN_HASH_ALGORITHM@
          srk_array: @IMX_SIGN_SRK_FILES@
        """)
    if d.getVar("IMX_SIGN_PQC_ENABLE") == "1":
        pqc_keydir = d.getVar("IMX_SIGN_PQC_KEYDIR")
        values.update({
            "IMX_SIGN_PQC_PRIVATE_KEY": os.path.join(pqc_keydir, d.getVar("IMX_SIGN_PQC_PRIVATE_KEY")),
            "IMX_SIGN_PQC_SRK_FILES": [os.path.join(pqc_keydir, key)
                                       for key in d.getVar("IMX_SIGN_PQC_SRK_FILES").split()],
            "IMX_SIGN_PQC_HASH_ALGORITHM": d.getVar("IMX_SIGN_PQC_HASH_ALGORITHM"),
        })
        template += textwrap.indent(textwrap.dedent("""\
            srk_table_#2:
              flag_ca: false
              hash_algorithm: @IMX_SIGN_PQC_HASH_ALGORITHM@
              srk_array: @IMX_SIGN_PQC_SRK_FILES@
            """), "  ")
        template += "signer_#2: @IMX_SIGN_PQC_PRIVATE_KEY@\ncheck_all_signatures: check_all_signatures\n"
    for name, value in values.items():
        template = template.replace("@" + name + "@", json.dumps(value))
    output = Path(d.getVar("T"), "ahab-sign.yaml")
    output.write_text(template)
    return str(output)

python do_imx_boot_sign() {
    import json
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
        "--pqc-profiles", json.dumps(imx_sign_pqc_profiles()),
    ]
    if d.getVar("IMX_SIGN_PQC_ENABLE") == "1":
        command += ["--pqc-key-dir", d.getVar("IMX_SIGN_PQC_KEYDIR")]
    environment = os.environ.copy()
    environment["PYTHONNOUSERSITE"] = "1"
    environment["SPSDK_CACHE_FOLDER"] = os.path.join(d.getVar("T"), "spsdk-cache")
    environment["SPSDK_DEBUG_LOG_FILE"] = os.path.join(d.getVar("T"), "spsdk-debug.log")
    images = list(imx_sign_images(d))
    for config, name in images:
        memory = d.getVarFlag("IMX_SPSDK_MEMORY_TYPE", config) or d.getVar("IMX_SPSDK_MEMORY_TYPE")
        source = os.path.join(d.getVar("S"), name)
        output = os.path.join(d.getVar("IMX_SIGN_OUTPUT_DIR"), name)
        bb.note("Signing %s (%s, %s, %s)" % (
            name, d.getVar("IMX_SPSDK_FAMILY"), d.getVar("IMX_SPSDK_REVISION"), memory))
        if debug:
            bb.verbnote("Signing %s -> %s (memory type: %s)" % (source, output, memory))
        result = subprocess.run(command + [
            "--memory-type", memory,
            "--input", source,
            "--output", output,
        ], input=textwrap.dedent(d.getVar("imx_sign_ahab")), text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=environment)
        if result.returncode:
            detail = result.stdout.strip() or "SPSDK exited with status %s" % result.returncode
            bb.fatal("Signing %s failed:\n%s" % (name, detail))
        if result.stdout:
            bb.note(result.stdout.rstrip())
        if debug:
            bb.verbnote("Verified signatures and unchanged payloads: %s" % output)
            bb.verbnote("SPSDK SRK hashes and fuse scripts: %s.fuses/" % output)

}
do_imx_boot_sign[cleandirs] = "${IMX_SIGN_OUTPUT_DIR}"
do_imx_boot_sign[vardeps] += "IMX_SPSDK_MEMORY_TYPE UBOOT_CONFIG IMXBOOT_TARGETS BOOT_VARIANT MACHINE"

python imx_sign_deploy() {
    import shutil
    from pathlib import Path

    source = Path(d.getVar("IMX_SIGN_OUTPUT_DIR"))
    deploy = Path(d.getVar("DEPLOYDIR"))
    images = list(imx_sign_images(d))
    default = (deploy / "imx-boot").resolve().name
    if default not in [name for config, name in images]:
        bb.fatal("No signed variant for deployed imx-boot: %s" % default)

    # This hook runs only after every variant has passed signing and verification
    for config, name in images:
        shutil.copy2(source / name, deploy / (name + ".sign"))
        shutil.copytree(source / (name + ".fuses"), deploy / (name + ".sign.fuses"),
                        dirs_exist_ok=True)

    link = deploy / "imx-boot.sign"
    link.unlink(missing_ok=True)
    link.symlink_to(default + ".sign")

    tagged = deploy / "imx-boot.tagged.sign"
    shutil.copy2(link, tagged)
    # Match the size tag appended by uuu_bootloader_tag.bbclass
    size = tagged.stat().st_size
    with tagged.open("ab") as output:
        output.write(("UUUBURNXXOEUZX7+A-XY5601QQWWZ%dEND\n" % size).encode("ascii"))
}

python __anonymous() {
    if d.getVar("IMX_SIGN_ENABLE") != "1":
        imx_validate_signing_keys(d)
        return
    sign_format = d.getVar("IMX_SIGN_FORMAT")
    if sign_format == "hab4":
        bb.fatal("HABv4 imx-boot signing is not implemented for %s\n"
                 'Set IMX_SIGN_ENABLE = "0" to build without boot image signing' % d.getVar("MACHINE"))
    if sign_format != "ahab":
        bb.fatal("Unsupported IMX_SIGN_FORMAT: %r\nThis class supports 'ahab'" % sign_format)
    if d.getVar("IMX_SIGN_BACKEND") != "spsdk":
        bb.fatal("Unsupported IMX_SIGN_BACKEND: %r\nAHAB signing needs 'spsdk'" % d.getVar("IMX_SIGN_BACKEND"))
    if not d.getVar("IMX_SPSDK_FAMILY"):
        bb.fatal("Set IMX_SPSDK_FAMILY to an SPSDK AHAB family")
    if not d.getVar("IMX_SPSDK_REVISION") or d.getVar("IMX_SPSDK_REVISION") == "latest":
        bb.fatal("Set IMX_SPSDK_REVISION to an explicit silicon revision")
    if d.getVar("IMX_SIGN_PQC_ENABLE") == "1":
        soc = imx_sign_soc_data().get(d.getVar("IMX_SIGN_SOC"), {})
        revision = d.getVar("IMX_SPSDK_REVISION")
        if d.getVar("IMX_SPSDK_FAMILY") == "mimx9596" and revision in ("a0", "a1"):
            bb.fatal("PQC signing with ML-DSA is not supported for i.MX95 %s\n"
                     "Check /sys/devices/soc0/revision on the board: Linux revision 2.0 is B0 (b0)\n"
                     "Use the b0 profile only for B0 silicon, or set IMX_SIGN_PQC_ENABLE = \"0\" "
                     "to use classical AHAB signing" % revision)
        if revision not in soc.get("pqc_revisions", ()):
            bb.fatal("PQC signing is not supported for %s (%s, revision %s)\n"
                     'Set IMX_SIGN_PQC_ENABLE = "0" to use classical AHAB signing' %
                     (d.getVar("MACHINE"), d.getVar("IMX_SPSDK_FAMILY"), revision))
    # Check boot image selections before compilation
    list(imx_sign_images(d))
    imx_validate_signing_keys(d)
    # BitBake does not walk directory symlinks when hashing inputs
    d.setVar("IMX_SIGN_KEYDIR", os.path.realpath(d.getVar("IMX_SIGN_KEYDIR")))
    if d.getVar("IMX_SIGN_PQC_ENABLE") == "1":
        d.setVar("IMX_SIGN_PQC_KEYDIR", os.path.realpath(d.getVar("IMX_SIGN_PQC_KEYDIR")))
        d.appendVarFlag("do_imx_boot_sign", "file-checksums", " %s:True" % d.getVar("IMX_SIGN_PQC_KEYDIR"))

    d.appendVar("DEPENDS", " python3-spsdk-native")
    # Copy before deploy's sstate postfunc publishes DEPLOYDIR
    d.prependVarFlag("do_deploy", "postfuncs", "imx_sign_deploy ")
    d.appendVarFlag("do_imx_boot_sign", "file-checksums", " %s:True" % d.getVar("IMX_SIGN_KEYDIR"))
    if d.getVar("IMX_SIGN_CONFIG"):
        d.appendVarFlag("do_imx_boot_sign", "file-checksums", " %s:True" % d.getVar("IMX_SIGN_CONFIG"))
    bb.build.addtask("do_imx_boot_sign", "do_deploy", "do_compile", d)
}

python imx_sign_ahab() {
    import argparse
    import json
    from pathlib import Path

    from spsdk.crypto.keys import PrivateKey, PublicKeyMLDSA
    from spsdk.crypto.utils import extract_public_key
    from spsdk.exceptions import SPSDKError
    from spsdk.image.ahab.ahab_container import AHABContainerV2
    from spsdk.image.ahab.ahab_data import FlagsSrkSet
    from spsdk.image.ahab.ahab_image import AHABImage
    from spsdk.image.ahab.utils import ahab_sign_image
    from spsdk.image.bootable_image.bimg import BootableImage
    from spsdk.image.bootable_image.segments import SegmentAhab
    from spsdk.image.mem_type import MemoryType
    from spsdk.utils.config import Config
    from spsdk.utils.family import FamilyRevision
    from spsdk.utils.verifier import VerifierResult


    def load_config(path, key_dir, family, revision, pqc_key_dir=None, pqc_profiles=()):
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
        if any(name in config for name in ("blob", "certificate")):
            raise ValueError("Encryption and certificate delegation are not supported")
        table = config.get("srk_table", {})
        if not isinstance(table, dict):
            raise ValueError("srk_table must be a mapping")
        second = "srk_table_#2" in table
        if second != ("signer_#2" in config):
            raise ValueError("signer_#2 and srk_table.srk_table_#2 must be supplied together")
        if pqc_key_dir is not None and not second:
            raise ValueError("IMX_SIGN_PQC_ENABLE is 1 but the signing config has no second signer")
        if second:
            if (family, revision) not in map(tuple, pqc_profiles):
                raise ValueError(f"Second key set is not supported for {family}, {revision}")
            if 2 not in AHABImage(FamilyRevision(family, revision)).chip_config.container_types:
                raise ValueError(f"Second key set requires AHAB v2 support for {family}, {revision}")

        def key_path(value, directory, setting):
            if not isinstance(value, str) or not value or ";" in value or value.startswith("type="):
                raise ValueError("Use local key paths for signers and SRK tables")
            resolved = (path.parent / value).resolve()
            if not resolved.is_relative_to(directory.resolve()) or not resolved.is_file():
                raise ValueError(f"Signing key must be a file inside {setting}: {value}")
            return str(resolved)

        key_sets = [("signer", "srk_table", table, key_dir, "IMX_SIGN_KEYDIR")]
        if second:
            key_sets.append(("signer_#2", "srk_table.srk_table_#2", table["srk_table_#2"],
                             pqc_key_dir or key_dir,
                             "IMX_SIGN_PQC_KEYDIR" if pqc_key_dir else "IMX_SIGN_KEYDIR"))
        for signer, name, srk_table, directory, setting in key_sets:
            if not isinstance(srk_table, dict):
                raise ValueError(f"{name} must be a mapping")
            keys = srk_table.get("srk_array", [])
            if not isinstance(keys, list) or len(keys) != 4:
                raise ValueError(f"{name}.srk_array must contain four public keys or certificates")
            config[signer] = key_path(config.get(signer), directory, setting)
            srk_table["srk_array"] = [key_path(key, directory, setting) for key in keys]
        config.check(AHABImage.get_signing_validation_schemas(FamilyRevision(family, revision)),
                     check_unknown_props=True)
        for signer, name, srk_table, directory, setting in key_sets:
            # Reject encrypted keys without opening an interactive password prompt
            private = PrivateKey.load(config[signer])
            public_keys = [extract_public_key(key) for key in srk_table["srk_array"]]
            for key, key_file in zip([private.get_public_key()] + public_keys,
                                     [config[signer]] + srk_table["srk_array"]):
                if isinstance(key, PublicKeyMLDSA) and key.level == 2:
                    raise ValueError(f"ML-DSA-44 is not supported for AHAB signing: {key_file}. "
                                     "Use ML-DSA-65 or ML-DSA-87 keys")
            if not private.verify_public_key(public_keys[config.get_int("used_srk_id", 0)]):
                raise ValueError(f"{signer} does not match {name}.srk_array at used_srk_id")
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
        if "signer_#2" in config and any(not isinstance(c, AHABContainerV2) for c in oem):
            raise ValueError("Second key set requires AHAB v2 OEM containers")
        if any(image.flags_is_encrypted for c in oem for image in c.image_array):
            raise ValueError("Encrypted OEM images are not supported")
        data, _ = ahab_sign_image(str(source), config, memory_type)

        # Verify the exported bytes, including signatures and image hashes
        signed = BootableImage.parse(data, family=family, mem_type=memory)
        signed.verify().validate()
        after = containers(signed)
        if len(before) != len(after):
            raise ValueError("Signing changed the container count")
        signed_oem = []
        for old, new in zip(before, after):
            if ([(i.export(), i.image) for i in old.image_array] !=
                    [(i.export(), i.image) for i in new.image_array]):
                raise ValueError("Signing changed image data or metadata")
            if signable(old):
                if new.flag_srk_set != FlagsSrkSet.OEM:
                    raise ValueError("An OEM container was left unsigned")
                if "signer_#2" in config and new.signature_block.signature_2 is None:
                    raise ValueError("An OEM container is missing the requested second signature")
                # SPSDK treats dummy or unverifiable signatures as warnings
                authenticity = new.signature_block.verify_container_authenticity(
                    new.get_signature_data())
                if authenticity.result != VerifierResult.SUCCEEDED:
                    raise ValueError(f"OEM signature verification did not succeed:\n{authenticity}")
                signed_oem.append(new)
            elif old.export() != new.export():
                raise ValueError("Signing changed a non-OEM container")
        for table in range(2 if "signer_#2" in config else 1):
            hashes = {container.get_srk_hash(table) for container in signed_oem}
            if len(hashes) != 1 or not all(hashes):
                raise ValueError(f"OEM containers must use the same non-empty SRK hash for table {table}")
        fuse_dir = destination.with_name(destination.name + ".fuses")
        fuse_dir.mkdir(parents=True, exist_ok=True)
        # Use the same SPSDK export as nxpimage ahab sign --fuse-scripts
        for index, container in enumerate(after):
            if signable(container):
                container.post_export(str(fuse_dir), index)
        destination.write_bytes(data)


    def main():
        parser = argparse.ArgumentParser(description=__doc__)
        for option in ("config", "key-dir", "input", "output"):
            parser.add_argument("--" + option, type=Path, required=True)
        for option in ("family", "revision", "memory-type"):
            parser.add_argument("--" + option, required=True)
        parser.add_argument("--pqc-key-dir", type=Path)
        parser.add_argument("--pqc-profiles", type=json.loads, default=[])
        args = parser.parse_args()
        try:
            config = load_config(args.config, args.key_dir, args.family, args.revision,
                                 args.pqc_key_dir, args.pqc_profiles)
            sign_image(config, args.input, args.output, args.memory_type)
        except (SPSDKError, ValueError, OSError) as error:
            parser.exit(1, f"imx-boot signing failed: {error}\n")


    if __name__ == "__main__":
        main()
}
