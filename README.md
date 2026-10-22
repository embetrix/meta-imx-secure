# meta-imx-secure

A Yocto layer that provides a security-hardened baseline for i.MX device, extending NXP layers with secure boot, verified and encrypted storage, runtime integrity and a hardened kernel and userspace.

## Build

Install kas, OpenSSL and the Yocto host dependencies, then generate the AHAB signing keys and kas fragment:

```sh
tools/genkey-helper.sh
KAS_MACHINE=<machine> kas build kas-imx-secure.yml:kas-signing-keys.yml
```

The helper checks and reuses existing keys. It defaults to P-384. Set `KEY_TYPE` when generating keys to choose another type supported by your SoC.

The generated `kas-signing-keys.yml` sets the key directory and enables signing. Keys and the fragment stay local and are not committed.
