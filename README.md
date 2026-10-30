# meta-imx-secure

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](COPYING.MIT)

A Yocto layer that extends the NXP i.MX BSP with secure boot, verified and encrypted storage, runtime integrity, and kernel and userspace hardening.

This layer provides a starting point for a product. Review the enabled services, access rules, key management, and update strategy for your hardware and use case. Test the full boot and recovery process before provisioning production devices.

## Features

- AHAB boot image signing with NXP SPSDK and signed U-Boot FIT images
- Read-only EROFS root filesystem protected by dm-crypt, AVB signature verification, and dm-verity
- Encrypted writable data using kernel encrypted keys backed by an OP-TEE trusted master key
- IMA/EVM file integrity and signed kernel modules
- A/B boot and root partitions with inactive slots available for updates
- Development and production profiles for kernel, bootloader, and userspace settings
- OpenSSH CA authentication, nftables, USBGuard, and audit logging
- OpenSSL PKCS#11 support through OP-TEE or NXP Security Middleware
- Image manifests and SPDX SBOM output

## Secure boot flow

```text
i.MX boot ROM
  └─ AHAB-authenticated boot containers (requires device provisioning)
      └─ U-Boot verifies the signed FIT image
          └─ Linux and bundled initramfs
              ├─ Load or create OP-TEE-backed storage keys
              ├─ Open the encrypted root volume
              ├─ Verify AVB metadata and activate dm-verity
              ├─ Mount the read-only root and writable partitions
              └─ Start systemd with IMA/EVM integrity checks
```

The build signs boot images. Enforcing the hardware root of trust also requires AHAB provisioning on the device, as described below.

## Quick start

### 1. Generate signing keys

Install kas, OpenSSL, ssh-keygen, and the Yocto host dependencies. Run from the layer directory:

```sh
tools/generate-signing-keys.sh
```

The helper creates AHAB, FIT, kernel module, IMA/EVM, AVB, and SSH CA keys under `imx-secure-keys/`. It writes `kas-signing-keys.yml` with the signing settings and absolute key paths. Existing keys are checked and reused.

Keep the private keys and an offline backup secure. Run the helper again if you move the checkout or key directory so the generated paths stay correct.

### 2. Select the machine and profile

`KAS_MACHINE` selects the board. `SECURITY_PROFILE` selects the hardening level and is passed to BitBake as `IMX_SECURITY_PROFILE`.

| Profile | Use case | Settings |
| --- | --- | --- |
| `dev` (default) | Bring-up | Serial access, debug tools, and password-free root login |
| `prod` | Release | Requires boot signing, applies kernel and userspace hardening, restricts the U-Boot console, disables the Linux serial console and serial getty, and configures SSH CA authentication with password login disabled |

Storage encryption, root filesystem verification, and IMA/EVM are part of the shared image setup. The development profile is for trusted development networks. Production console settings keep UART drivers available for connected devices. Some early firmware messages may still appear.

### 3. Build

```sh
KAS_MACHINE=imx95-15x15-lpddr4x-frdm SECURITY_PROFILE=dev \
    kas build kas-imx-secure.yml:kas-signing-keys.yml
```

Use `SECURITY_PROFILE=prod` for a production build. The default distro is `imx-secure` and the target is `imx-secure-image`.

Artifacts are written to `build/tmp/deploy/images/<MACHINE>/`:

| Artifact | Purpose |
| --- | --- |
| `imx-secure-image-<MACHINE>.rootfs.wic.gz` | Complete disk image |
| `imx-secure-image-<MACHINE>.rootfs.wic.bmap` | Block map for flashing |
| `imx-secure-image-<MACHINE>.rootfs.erofs.avbverity.gz` | Root filesystem with AVB metadata |
| `fitImage` | Signed FIT containing Linux, the bundled initramfs, and device trees |
| `imx-boot*.sign` | Signed boot containers |
| `imx-boot*.sign.fuses/` | SPSDK SRK hashes and fuse scripts |

Versioned image filenames include the security profile, for example `imx-secure-image-<MACHINE>.rootfs-<DATETIME>-prod.wic.gz`. The unversioned image links point to the latest build in that deploy directory.

### 4. Flash and boot

Unmount the SD card partitions, then write the complete image:

```sh
sudo bmaptool copy \
    build/tmp/deploy/images/imx95-15x15-lpddr4x-frdm/imx-secure-image-imx95-15x15-lpddr4x-frdm.rootfs.wic.gz \
    /dev/sdX
```

Replace `/dev/sdX` with the whole SD card device. This overwrites its contents.

On first boot, the initramfs creates the storage keys, copies the root filesystem from slot B into encrypted slot A, and formats the encrypted data volume. This takes longer than later boots. Keep power connected during this step. The migration is not power-safe.

### 5. Provision AHAB secure boot

The signing build preserves NXP firmware containers and signs the OEM containers. It also exports SRK hashes and fuse scripts next to the signed boot images.

Use the NXP provisioning procedure for the exact SoC and revision to program the matching SRK hash and close the device lifecycle. Validate the signed image and recovery procedure first. Fuse programming is irreversible. The build does not program fuses or change the device lifecycle.

See [imx-boot-sign.bbclass](classes-recipe/imx-boot-sign.bbclass) for supported AHAB families, signing options, and generated files. HABv4 signing is not implemented.

### 6. Connect with SSH

Development images allow root login without a password. Production images trust the SSH CA public key generated in step 1 and disable password login.

Sign an existing user public key with the CA, then connect using its matching private key:

```sh
ssh-keygen -s imx-secure-keys/ssh-ca/ssh-ca-ed25519.key \
    -I developer -n root -V +1d ~/.ssh/id_ed25519.pub
ssh -i ~/.ssh/id_ed25519 root@<device-ip>
```

The SSH service waits for time synchronization. Ensure the device can reach its time servers, since SSH certificate validity checks need correct time.

## Storage layout

The [WIC layout](files/wic/imx-boot-secure-bootpart.wks.in) reserves space for the bootloader before these GPT partitions:

| Partition | Default size | Purpose |
| --- | --- | --- |
| `boot_a` | 512 MiB | Initial active FIT image, mounted at `/boot` |
| `root_a` | 1024 MiB | Initial active encrypted and verified root |
| `boot_b` | 512 MiB | Inactive boot slot, mounted at `/var/boot-update` |
| `root_b` | 1024 MiB | Plain root image for first-boot migration, then inactive root slot |
| `secdata` | 512 MiB | Sealed storage key blobs, mounted at `/var/secdata` |
| `data` | 4096 MiB | Encrypted writable state, mounted at `/var/data` |

`secdata` is a plain ext4 filesystem containing protected key blobs. The root and data volumes use dm-crypt. The initramfs mounts the persistent partitions before switching to the real root.

The A/B layout provides space for updates. An update agent, slot switching policy, and rollback handling still need to be integrated for a complete OTA solution.

## Build integration

The [kas configuration](kas-imx-secure.yml) provides the complete layer set. To use an existing Yocto build, add those dependencies and this layer, select `DISTRO = "imx-secure"`, and supply the signing settings generated by the key helper. Build `imx-secure-image` as the reference image.

For a product image, start from [imx-secure-image.bb](recipes-core/images/imx-secure-image.bb) and retain its read-only root and security package setup. Machine and storage defaults are in [imx-secure.inc](conf/machine/include/imx-secure.inc).

The [Dockerfile](Dockerfile) supplies the CI build environment. The [Jenkins pipeline](Jenkinsfile) selects the machine and profile, builds with kas, and archives the image and signing outputs. Its signing credential is a gzip-compressed tar archive containing the `imx-secure-keys/` directory.

## Layer dependencies

BSP layers are pinned to NXP `LF6.18.37_2.1.0`. Other repos follow Wrynose. See [kas-imx-secure.yml](kas-imx-secure.yml) for repository URLs and exact revisions.

- openembedded-core and meta-yocto
- meta-openembedded: meta-oe, meta-python, meta-perl, meta-networking, meta-multimedia
- meta-arm and meta-arm-toolchain
- meta-freescale and meta-freescale-distro
- meta-imx: meta-imx-bsp and meta-imx-sdk
- meta-avb
- meta-security and meta-integrity

## Hardware

These boards are listed in the build pipeline:

| Board | `MACHINE` | Status |
| --- | --- | --- |
| FRDM-IMX95 | `imx95-15x15-lpddr4x-frdm` | Boot and encrypted root tested on target |
| FRDM-IMX93 | `imx93-11x11-lpddr4x-frdm` | Build target, hardware validation pending |
| FRDM-IMX91 | `imx91-11x11-lpddr4-frdm` | Build target, hardware validation pending |

Other AHAB platforms need board-specific validation of signing, OP-TEE, storage, and boot settings.

## Commercial support

Maintained by Embetrix Embedded Systems Solutions. Contact [info@embetrix.com](mailto:info@embetrix.com) for integration, provisioning, key management, and maintenance support.

## License

This layer is licensed under the [MIT License](COPYING.MIT). Included software keeps its own licenses.
