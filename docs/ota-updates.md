# OTA update integration

[Back to README](../README.md)

Use this guide when adding an update agent. See the [partition layout](architecture.md#partition-layout) for storage sizes and mount points.

The layer provides A/B slot selection and storage mappings. The integrator must handle update delivery, activation policy, boot attempt tracking, health checks, confirmation and recovery. Optional SWUpdate support provides an example for verifying and installing bundles.

## Slot layout and boot selection

On supported i.MX8/9 MMC boots, U-Boot selects the FIT partition to match the boot firmware image set:

| Boot image set | Slot | FIT partition | Root partition |
| --- | --- | --- | --- |
| 0 | A | `boot_a` | `root_a` |
| 1 | B | `boot_b` | `root_b` |

U-Boot passes `boot_slot=a` or `boot_slot=b` on the kernel command line. The initramfs uses `root=` to identify the disk and selects the matching root partition. Without `boot_slot=` it keeps the slot identified by `root=`.

An update agent installs the new FIT in `/var/boot-update` and writes the root filesystem image with its AVB metadata and verity data to `/dev/mapper/update`. Both targets belong to the inactive slot. Writes to the inactive rootfs slot are encrypted by dm-crypt.

i.MX ROM selects between redundant boot firmware image sets using container software versions and boot settings. With version-based selection enabled it tries the image set with the higher software version first. Set `SW_VERSION` when building `imx-boot` to assign this version.

Keep each firmware copy aligned with its matching FIT and root filesystem slot. The WIC image writes only the first firmware copy, so the update or provisioning process must populate the second copy. See [Partition layout](architecture.md#partition-layout) for the default locations.

> **NOTE:** An alternative is to store the boot firmware copies in the eMMC hardware boot partitions (`boot0` and `boot1`) with FIT and root filesystem slots in the user area.

See [build artifacts](building-images.md#build-artifacts) for the files produced by the build.

## SWUpdate example implementation

> **NOTE:** This integration provides bundle verification and installation. The integrator must implement and validate the product's boot attempt tracking, health checks, update confirmation and recovery policy.

Optional SWUpdate support provides CMS-signed, AES-encrypted `.swu` bundles through `imx-secure-image-base-update`. Install a bundle with `swupdate-client /path/to/imx-secure-image-base-update.swu`.

The example installs the inactive slot and reboots automatically after a successful update. Development updates invalidate the old firmware copy to allow reused software versions. Production updates keep it for integrator-managed fallback and need a higher `SW_VERSION` for ROM to prefer the new firmware. The bundle does not write update state to the firmware environment, and initramfs selects slots from the bootloader arguments without tracking attempts or performing rollback.

### Typical integrator workflow

The integrator must implement and validate this flow for the board. See [SWUpdate best practice: update concept](https://sbabic.github.io/swupdate/swupdate-best-practise.html#update-concept) for the update state machine.

```mermaid
flowchart TD
    BUNDLE["Decrypt and verify update bundle"] --> PREPARE["Record update in progress<br/>Keep the previous working slot"]
    PREPARE --> INSTALL["Install FIT, root filesystem and imx-boot<br/>in the inactive slot"]
    INSTALL --> PENDING["Mark update pending<br/>Reset trial boot count"]
    PENDING --> REBOOT["Reboot"]
    REBOOT --> ROM["ROM selects boot firmware by SW_VERSION"]
    ROM --> TRIAL["Bootloader records trial attempt<br/>Boot the matching FIT and root filesystem"]
    TRIAL --> HEALTH{"Boot and application health checks pass?"}
    HEALTH -->|Yes| CONFIRM["Confirm update<br/>Clear pending state and trial count"]
    HEALTH -->|No or watchdog timeout| LIMIT{"Trial limit reached?"}
    LIMIT -->|No| REBOOT
    LIMIT -->|Yes| FALLBACK["Arrange fallback using board-specific recovery<br/>Reboot into the previous working slot"]
    FALLBACK --> REPORT["Record and report failed update"]
```
