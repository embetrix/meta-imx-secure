# AHAB secure boot provisioning

[Back to README](../README.md)

Provision the device after building and testing a signed image with the [building images](building-images.md) and [device setup](device-setup.md) guides. Selecting the `prod` profile does not program fuses or close the device lifecycle.

The build preserves NXP firmware containers and signs OEM containers. It exports SRK hashes and fuse scripts beside the signed images.

In **OEM Open**, AHAB can report authentication failures, including a mismatch between the OEM SRK table hash and OTP fuses, without stopping boot. A successful boot alone does not prove correct provisioning. **OEM Closed** enforces authentication. See [NXP's authentication examples](https://docs.mcuxpresso.nxp.com/secure/latest/06_processor_specific_workflow.html#get-ele-events-with-nxpele-utility).

**Fuse programming is irreversible.** Verify the signing keys, SoC family, silicon revision, signed image and recovery procedure before programming OTP fuses.

## 1. Prepare the device

Install NXP SPSDK on the host. Boot a signed development or provisioning image with the U-Boot console and `ele_message` command enabled. The production profile disables console access.

Press a key during the autoboot countdown to stop at the U-Boot prompt. Check that `help ele_message` shows the command, then close the serial terminal so `nxpele` can use the port. Keep the board powered on at the prompt.

| SoC    | SPSDK family |
| :----- | :----------- |
| i.MX91 | `mimx9131`   |
| i.MX93 | `mimx9352`   |
| i.MX95 | `mimx9596`   |

Use the SPSDK family for your SoC as `<FAMILY>` in every command below.

Read the device information from the host:

```sh
nxpele -f "<FAMILY>" -d uboot_serial \
    -p /dev/ttyACM0,115200 get-info
```

Replace `/dev/ttyACM0` with the board's serial port. An i.MX91 reporting `SoC version: A000` uses SPSDK revision `a0` in the signing configuration. SPSDK lists the supported revisions in its [device table](https://spsdk.readthedocs.io/en/latest/devices_list.html#mimx9131). The `nxpele` commands below do not take a `--revision` option.

## 2. Read AHAB events before programming

Check AHAB events before programming any fuses. With U-Boot waiting at its prompt and the serial terminal closed, read the stored ELE events from the host:

```sh
nxpele -f "<FAMILY>" -d uboot_serial \
    -p /dev/ttyACM0,115200 get-events
```

Before programming the SRK hash, an OEM Open device can report:

```text
Event count:     2
Event[0]:      0x0287FAD6
  IPC ID:        Application Processor message unit
  Command:       OEM Container authenticate
  Indication:    The key hash verification does not match OTP
  Status:        The request was successful
Event[1]:      0x0287FAD6
  IPC ID:        Application Processor message unit
  Command:       OEM Container authenticate
  Indication:    The key hash verification does not match OTP
  Status:        The request was successful
```

Both events mean the OEM container's SRK table hash does not match the OTP fuses. If `get-info` also reports `OEM_OPEN` and an all-zero `OEM SRKH`, this is expected before provisioning the matching SRK hash. OEM Open allows boot to continue despite this mismatch.

`Status: The request was successful` does not mean the key hash check passed. These events also do not prove that all other signature checks passed. NXP shows this exact output in its [authentication failure example](https://docs.mcuxpresso.nxp.com/secure/latest/06_processor_specific_workflow.html#get-ele-events-with-nxpele-utility).

**Program the fuses only when there are no blocking AHAB events.** The only expected exception here is an SRK hash mismatch when the device is in OEM Open and the OEM SRK hash is all zero. Treat every other error or unexplained event as blocking. Resolve it and repeat this check before programming. This check alone does not prove that everything is working.

## 3. Select the fuse script and check existing fuses

Find the following file for the image you flashed:

```text
build/tmp/deploy/images/<MACHINE>/<BOOT_IMAGE>.fuses/ahab_oem<N>_srk0_hash_nxpele.bcf
```

Check the family, revision and fuse values in the script header and commands. The generated scripts for different OEM containers use the same SRK hash, so program that hash once. For PQC builds using a second SRK table, also program the matching `srk1` script.

Confirm that `get-info` reports `OEM_OPEN`. Stop if the device is in another lifecycle.

Before writing, read the target SRK hash fuses and compare the whole hash with the selected script. Check each SRK table separately when using `srk0` and `srk1`:

- All target words are zero: the table is blank and can be programmed after the event checks pass
- All target words match the script: skip programming that table and continue with boot verification
- Any other value: stop and investigate the existing provisioning. Do not run the script

Use the fuse word indexes for your SoC. For words supported by `read-common-fuse`, read them from the host with:

```sh
nxpele -f "<FAMILY>" \
    -d uboot_serial -p /dev/ttyACM0,115200 \
    read-common-fuse --index <INDEX>
```

If this command cannot read the target words, use NXP's fuse read procedure for the SoC. Do not program until you have verified the existing values.

## 4. Program and verify the SRK hash

Run the selected script from the host only when the device is in OEM Open, the target table is blank, there are no blocking AHAB events and the script checks in step 3 have passed:

```sh
nxpele -f "<FAMILY>" \
    -d uboot_serial -p /dev/ttyACM0,115200 \
    batch "<FUSE_SCRIPT>.bcf"
```

Replace `<FUSE_SCRIPT>.bcf` with the selected script's full path and use the same family and serial port as above.

Read back each programmed word using the same method as step 3. Stop if any value differs from the script.

Reboot the signed image and repeat `get-events` from step 2, or check `ahab_status` at the U-Boot prompt. Require no AHAB events. The SRK hash mismatch is no longer an expected exception.

Keep the device in OEM Open until fuse readback matches, authentication passes and the signed image boots successfully through Linux. Only then close the device lifecycle using NXP's procedure for the specific SoC.

**The SRK scripts program the hash fuses. They do not close the device lifecycle.**

See the [NXP nxpele guide](https://spsdk.readthedocs.io/en/latest/apps/nxpele.html#batch) and [fuse usage guide, section 4.5](https://www.nxp.com/docs/en/application-note/AN14954.pdf#page=10).

See the [security architecture](architecture.md#secure-boot-authentication) for the boot authentication flow.
