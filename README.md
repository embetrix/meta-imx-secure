# meta-imx-secure

[![BitBake parse](https://github.com/embetrix/meta-imx-secure/actions/workflows/bitbake-parse.yml/badge.svg?branch=wrynose)](https://github.com/embetrix/meta-imx-secure/actions/workflows/bitbake-parse.yml?query=branch%3Awrynose)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](COPYING.MIT)

A Yocto layer that extends the NXP i.MX BSP with secure boot, encrypted and verified storage, integrity checks and kernel and userspace hardening.

> **NOTE:**
> Using this layer does not automatically perform irreversible provisioning. Secure boot requires OEM SRK hash fuse programming and device lifecycle closure. Storage rollback protection requires RPMB key provisioning and RPMB storage enabled. Signed images alone do not secure the device.

## Features

| Area | Description |
| --- | --- |
| Secure boot | AHAB signing with NXP SPSDK, signed Linux FIT images and a full PQC secure boot chain on supported silicon |
| Storage protection | Encrypted read-only root filesystem and writable data, AVB-verified rootfs using dm-verity with forward error correction (FEC) |
| Key protection | OP-TEE-backed kernel trusted and encrypted keys, EdgeLock Enclave cryptography and persistent key storage on supported SoCs |
| Runtime integrity | IMA/EVM signature checks and enforced kernel module signatures |
| Access control | Optional SELinux, nftables firewall, USBGuard, audit logging and OpenSSH CA authentication in production |
| Application cryptography | OpenSSL PKCS#11 integration through OP-TEE or NXP Security Middleware (SMW), experimental OP-TEE PQC |
| TPM support | OP-TEE fTPM |
| OTA updates | A/B system updates with optional SWUpdate integration for signed and encrypted bundles |
| Build and hardening | Development and production profiles, kernel and userspace hardening |
| Security scanning | SPDX SBOM generation, CVE checks and optional [Trowl](https://github.com/corefense-security/trowl) scans with advanced CVE analysis, hardening checks and secret detection |

These features support [Cyber Resilience Act (CRA)](https://digital-strategy.ec.europa.eu/en/policies/cra-manufacturers) readiness. Compliance depends on the finished product and its maintenance processes.

## Supported hardware

The layer targets NXP i.MX8 and i.MX9 boards. AHAB signing supports these SoCs:

| Family | SoCs |
| --- | --- |
| i.MX8 | i.MX8QM, i.MX8QXP, i.MX8DX, i.MX8DXL, i.MX8ULP |
| i.MX9 | i.MX91, i.MX93, i.MX95, i.MX937, i.MX943, i.MX952 |

Feature support depends on the board and BSP. Boards outside the tested list may need further adaptation.

PQC support depends on the SoC, silicon revision and container format. See [NXP's i.MX95 B0 example](https://spsdk.readthedocs.io/en/latest/examples/ahab/imx95/imx95_ahab_sign.html) and the [layer signing options](classes-recipe/imx-ahab-sign-common.bbclass). HABv4 signing is not implemented yet but is planned for the future.

### Tested hardware

These boards are tested:

| Board | `MACHINE` | Tested by |
| --- | --- | --- |
| [FRDM-IMX95](https://www.nxp.com/design/design-center/development-boards-and-designs/FRDM-IMX95) | `imx95-15x15-lpddr4x-frdm` | [embetrix](https://github.com/embetrix) |
| [FRDM-IMX93](https://www.nxp.com/design/design-center/development-boards-and-designs/FRDM-IMX93) | `imx93-11x11-lpddr4x-frdm` | [embetrix](https://github.com/embetrix) |
| [FRDM-IMX91](https://www.nxp.com/design/design-center/development-boards-and-designs/FRDM-IMX91) | `imx91-11x11-lpddr4-frdm`  | [embetrix](https://github.com/embetrix) |

Open a pull request to add a tested board.

## Documentation

| Guide | Description |
| --- | --- |
| [Building images](docs/building-images.md) | Host tools, signing keys, profiles, kas builds and build artifacts |
| [HSM signing](docs/hsm-signing.md) | AHAB signing with PKCS#11 key references and HSM keys |
| [Device setup](docs/device-setup.md) | SD card and eMMC flashing, development login and SSH certificates |
| [Boot flow](docs/boot-flow.md) | Boot authentication, A/B slot selection and initramfs |
| [Partitioning](docs/partitioning.md) | Disk offsets, partition sizes and mount points |
| [AHAB provisioning](docs/ahab-provisioning.md) | SRK fuse scripts, programming and verification |
| [OTA update integration](docs/ota-updates.md) | SWUpdate bundles, A/B slots and boot firmware selection |
| [Layer integration](docs/layer-integration.md) | Adding the layer to an existing Yocto build |

## Layer dependencies

BSP layers are pinned to NXP `LF6.18.37_2.1.0`. Other repos follow Wrynose. See [kas-imx-secure.yml](kas-imx-secure.yml) for repository URLs and exact revisions.

| Repository | Branch | Layers |
| --- | --- | --- |
| [openembedded-core](https://github.com/openembedded/openembedded-core/tree/wrynose) | `wrynose` | meta |
| [meta-openembedded](https://github.com/openembedded/meta-openembedded/tree/wrynose) | `wrynose` | meta-oe, meta-python, meta-networking and meta-multimedia |
| [meta-avb](https://github.com/embetrix/meta-avb/tree/wrynose) | `wrynose` | meta-avb |
| [meta-security](https://git.yoctoproject.org/meta-security/tree/?h=wrynose) | `wrynose` | meta-security, meta-integrity and meta-tpm (optional) |
| [meta-selinux](https://git.yoctoproject.org/meta-selinux/tree/?h=wrynose) | `wrynose` | meta-selinux (optional) |
| [meta-swupdate](https://github.com/sbabic/meta-swupdate/tree/wrynose) | `wrynose` | meta-swupdate (optional)  |
| [meta-trowl](https://github.com/corefense-security/trowl/tree/main/integrations/meta-trowl) | `main` | meta-trowl (optional) |
| [meta-arm](https://git.yoctoproject.org/meta-arm/tree/?h=wrynose) | `wrynose` | meta-arm and meta-arm-toolchain |
| [meta-freescale](https://github.com/Freescale/meta-freescale/tree/wrynose) | `wrynose` | meta-freescale |
| [meta-imx](https://github.com/nxp-imx/meta-imx/tree/wrynose-6.18.37-2.1.0) | `wrynose-6.18.37-2.1.0` | meta-imx-bsp |

## Commercial support

Maintained by [Embetrix](https://embetrix.com) Embedded Systems Solutions. Contact [info@embetrix.com](mailto:info@embetrix.com) for custom development, board support, integration, provisioning, key management and maintenance.

## Disclaimer

This layer is a starting point for product integration. The integrator is responsible for assessing threats, removing unused software and services and adapting firewall, USBGuard rules, SELinux policy, software updates and key management to the product's needs. The integrator must also check license compliance, track and address CVEs in all included software and test the full boot and recovery process. Incorrect OTP fuse programming can permanently disable a device. The maintainers accept no liability for damage caused by fuse programming, lost or leaked signing keys or misconfiguration. This layer is provided as is, without warranty. No security certification is implied. See the [MIT License](COPYING.MIT) for the warranty and liability terms.

