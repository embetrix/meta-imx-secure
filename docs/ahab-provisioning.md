# AHAB secure boot provisioning

[Back to README](../README.md)

Provision the device after building and testing a signed image with the [building images](building-images.md) and [device setup](device-setup.md) guides. Selecting the `prod` profile does not program fuses or close the device lifecycle.

The build preserves NXP firmware containers and signs OEM containers. It exports SRK hashes and fuse scripts beside the signed images.

In **OEM Open**, AHAB can report authentication failures, including a mismatch between the OEM SRK table hash and OTP fuses, without stopping boot. A successful boot alone does not prove correct provisioning. **OEM Closed** enforces authentication. See [NXP's authentication examples](https://docs.mcuxpresso.nxp.com/secure/latest/06_processor_specific_workflow.html#get-ele-events-with-nxpele-utility).

**Fuse programming is irreversible.** Verify the signing keys, SoC family, silicon revision, signed image and recovery procedure before programming OTP fuses.

## 1. Prepare the device

Install NXP SPSDK on the host. Boot a signed development or provisioning image with the U-Boot console and `ele_message` command enabled. The production profile disables console access.

Stop at the U-Boot prompt, then disconnect the serial terminal so `nxpele` can use the port.

## 2. Select the fuse script

Find the following file for the image you flashed:

```text
build/tmp/deploy/images/<MACHINE>/<BOOT_IMAGE>.fuses/ahab_oem<N>_srk0_hash_nxpele.bcf
```

Check the family, revision and fuse values in the script header and commands. The generated scripts for different OEM containers use the same SRK hash, so program that hash once. For PQC builds using a second SRK table, also program the matching `srk1` script.

## 3. Program and verify the SRK hash

Run the selected script from the host:

```sh
nxpele -f "<FAMILY>" --revision "<REVISION>" \
    -d uboot_serial -p /dev/ttyACM0,115200 \
    batch "<FUSE_SCRIPT>.bcf"
```

| SoC | SPSDK family |
| --- | --- |
| i.MX91 | `mimx9131` |
| i.MX93 | `mimx9352` |
| i.MX95 | `mimx9596` |

Replace `<REVISION>` with the device revision, `<FUSE_SCRIPT>.bcf` with the selected script's full path and `/dev/ttyACM0` with the board's serial port.

Read back each programmed word using the same connection options:

```sh
nxpele -f "<FAMILY>" --revision "<REVISION>" \
    -d uboot_serial -p /dev/ttyACM0,115200 \
    read-common-fuse --index <INDEX>
```

Compare the values with the script. Reboot the signed image and check `ahab_status` at the U-Boot prompt. Resolve all AHAB errors before closing the device lifecycle using NXP's procedure for the specific SoC.

**The SRK scripts program the hash fuses. They do not close the device lifecycle.**

See the [NXP nxpele guide](https://spsdk.readthedocs.io/en/latest/apps/nxpele.html#batch) and [fuse usage guide, section 4.5](https://www.nxp.com/docs/en/application-note/AN14954.pdf#page=10).

See the [security architecture](architecture.md#secure-boot-authentication) for the boot authentication flow.
