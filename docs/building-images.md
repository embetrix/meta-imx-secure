# Building images

[Back to README](../README.md)

Generate signing keys and build an image with kas. Start with the `dev` profile for board bring-up.

## 1. Prepare the host

Install `kas`, `openssl`, `ssh-keygen` and the host dependencies required by the Yocto release used in [kas-imx-secure.yml](../kas-imx-secure.yml). Run the following commands from the layer directory.

## 2. Generate signing keys

```sh
tools/generate-signing-keys.sh
```

The helper creates AHAB, FIT, kernel module, IMA/EVM, AVB, SSH CA and SWUpdate keys under `imx-secure-keys/`. It generates `kas-signing-keys.yml` with the signing settings and absolute key paths. Existing keys are checked and reused.

Keep private keys secure and maintain an offline backup. Run the helper again if you move the checkout or key directory to update the generated paths.

## 3. Select the machine and profile

Choose a `MACHINE` from the [tested boards](../README.md#tested-hardware). Use that value in place of `<MACHINE>` in the commands below.

`KAS_MACHINE` selects the board. `SECURITY_PROFILE` is passed to BitBake as `IMX_SECURITY_PROFILE`.

| Profile | Intended use | Access and hardening |
| --- | --- | --- |
| `dev` (default) | Bring-up and debugging | Serial access, debug tools and password login |
| `prod` | Product integration | Requires boot signing, applies kernel and userspace hardening, restricts the U-Boot console, disables the Linux serial console and serial getty and enables SSH CA authentication with password login disabled |

Both profiles include storage encryption, root filesystem verification and enforced runtime integrity checks. Use development images only on an isolated test network.

## 4. Build

> **Note:**  Read the [NXP/Freescale EULA](https://raw.githubusercontent.com/Freescale/meta-freescale/refs/heads/wrynose/EULA) before building. The kas configuration sets `ACCEPT_FSL_EULA = "1"`. Building with this configuration means you accept the EULA terms.

Replace `<MACHINE>` with a machine name from [Supported hardware](../README.md#supported-hardware):

```sh
KAS_MACHINE="<MACHINE>" SECURITY_PROFILE=dev \
    kas build kas-imx-secure.yml:kas-signing-keys.yml
```

Use `SECURITY_PROFILE=prod` for a production-profile build. The default distro is `imx-secure` and the target is `imx-secure-image-base`.

## Build artifacts

Artifacts are written to `build/tmp/deploy/images/<MACHINE>/`:

| Artifact | Purpose |
| --- | --- |
| `imx-secure-image-base-<MACHINE>.rootfs.wic.gz` | Complete disk image |
| `imx-secure-image-base-<MACHINE>.rootfs.wic.bmap` | Block map for flashing |
| `imx-secure-image-base-<MACHINE>.rootfs.erofs.avbverity.gz` | Root filesystem with AVB metadata and verity data |
| `imx-secure-image-base-<MACHINE>.rootfs.sbom-cve-check.spdx.json` | SPDX SBOM with CVE scan results, production builds only |
| `fitImage` | Signed FIT containing Linux, the bundled initramfs and device trees |
| `imx-boot*.sign` | Signed boot containers |
| `imx-boot*.fuses/` | SPSDK SRK hashes and fuse scripts |

Versioned image filenames include the security profile and Git version, for example `imx-secure-image-base-<MACHINE>.rootfs-prod_<VERSION>.wic.gz`.

See [OTA update integration](ota-updates.md) for how an update agent uses these artifacts.

Next, follow [device setup](device-setup.md) to flash the image and log in. To use an existing Yocto build, see [layer integration](layer-integration.md).
