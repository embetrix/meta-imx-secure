# Device setup

[Back to README](../README.md)

Flash an image and set up login access. First, follow [building images](building-images.md) to create the image and signing keys.

Install `bmaptool` and `ssh-keygen` on the host. Use a **16 GB or larger SD card** with the default partition sizes. Run the commands from the layer directory and replace `<MACHINE>` with the machine used for your build.

## 1. Flash the SD card

Unmount the SD card partitions, then write the complete disk image:

```sh
sudo bmaptool copy \
    "build/tmp/deploy/images/<MACHINE>/imx-secure-image-base-<MACHINE>.rootfs.wic.gz" \
    /dev/sdX
```

Replace `/dev/sdX` with the **whole SD card device**. This overwrites its contents.

On first boot, the initramfs creates the storage keys, copies the plaintext root filesystem from slot B into encrypted slot A and formats the encrypted data volume. This takes longer than later boots.

## 2. Login and SSH

Default accounts for development login:

| User | Password | Access |
| --- | --- | --- |
| `imx` | `notrustnofun` | Regular user |
| `root` | `1234butbetter` | Administrator |

Set `IMX_USER_PASSWD_HASH` and `ROOT_USER_PASSWD_HASH` to use your own password hashes. The `prod` profile disables SSH password login and serial login.

### Development login

```sh
ssh root@<device-ip>
```

### Production login

For a production image, first sign your public key with the SSH CA key from [key generation](building-images.md#2-generate-signing-keys):

```sh
ssh-keygen -s imx-secure-keys/ssh-ca/ssh-ca-ed25519.key \
    -I developer -n root -V +1h ~/.ssh/id_ed25519.pub
```

This issues a client SSH certificate valid for one hour. Keep validity as short as your work allows.

Then connect using the matching private key:

```sh
ssh -i ~/.ssh/id_ed25519 root@<device-ip>
```

In production images, the SSH service waits for time synchronization. Ensure the device can reach its time servers so certificate validity checks use the correct time.

For product integration, read the [security architecture](architecture.md), [AHAB provisioning guide](ahab-provisioning.md) and [OTA update guide](ota-updates.md). To use an existing Yocto build, see [layer integration](layer-integration.md).
