# Partitioning

[Back to README](../README.md)

Disk layout, initial partition contents and runtime mount points. See [boot flow](boot-flow.md) for authentication and first-boot encryption, and [device setup](device-setup.md) for flashing.

## Partition layout

The [WIC layout](../files/wic/imx-boot-secure-bootpart.wks.in) writes `imx-boot` before the GPT partitions. Offsets below are measured from the start of the disk and use the default sizes:

| Image / partition | Offset | Default size | Mount point | Purpose |
| --- | --- | --- | --- | --- |
| `fwenv` | 20 KiB | 6 KiB | NA | Firmware environment |
| `fwenv` redundant | 26 KiB | 6 KiB | NA | Firmware environment copy |
| `imx-boot` | 32 KiB (`0x8000`) | Image size | NA | Boot firmware, written raw outside the partition table |
| `imx-boot` redundant | 4 MiB (`0x400000`) | Image size | NA | Second boot image set location, not populated by WIC |
| `boot_a` | 8 MiB | 512 MiB | `/boot` | Initial active FIT image |
| `root_a` | 520 MiB | 1024 MiB | `/` | Initially empty, filled through dm-crypt on first boot and mounted through dm-verity |
| `boot_b` | 1544 MiB | 512 MiB | `/var/boot-update` | Initially empty FAT filesystem, then inactive boot slot |
| `root_b` | 2056 MiB | 1024 MiB | Not mounted | Plain root image with AVB metadata and verity data, cleared after first-boot migration |
| `secdata` | 3080 MiB | 512 MiB | `/var/secdata` | Key blobs, OP-TEE storage and ELE storage |
| `data` | 3592 MiB | 3072 MiB | `/var/data` | Encrypted persistent storage for writable paths via volatile-binds |

The default disk image is about 6.51 GiB and fits an 8 GB eMMC.

Set partition sizes with the BitBake variables `BOOT_PART_SZ`, `ROOT_PART_SZ`, `SECDATA_PART_SZ` and `DATA_PART_SZ` in `local.conf`.

Mount points above show slot A active. With slot B active, the boot and root slots swap roles. The inactive root is available through `/dev/mapper/update` for encrypted writes.

The second firmware location uses the default `IMX_BOOT_SECONDARY_OFFSET`. The update or provisioning process must populate it and keep it aligned with its matching FIT and root slot. See [OTA update integration](ota-updates.md) for redundant boot images and A/B slot handling.

`secdata` is a plain ext4 filesystem. It holds protected key blobs in `keys/`, OP-TEE storage in `tee/` and ELE persistent storage in `ele/`.

The root filesystem defaults to EROFS. `data` is formatted as ext4 through dm-crypt on first boot. Persistent writable paths use bind mounts from `/var/data`.
