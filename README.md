# meta-imx-secure

A Yocto layer that provides a security-hardened baseline for i.MX device, extending NXP layers with secure boot, verified and encrypted storage, runtime integrity and a hardened kernel and userspace.

## Build

Install kas, OpenSSL and the Yocto host dependencies, then generate the AHAB and FIT signing keys and kas fragment:

```sh
tools/genkey-helper.sh
KAS_MACHINE=<machine> kas build kas-imx-secure.yml:kas-signing-keys.yml
```

The helper checks and reuses existing keys. AHAB defaults to P-384. Set `KEY_TYPE` when generating keys to choose another type supported by your SoC. FIT uses a separate RSA-2048 key and certificate, `fit.key` and `fit.crt`. Set `FIT_KEY_TYPE` to `rsa3072` or `rsa4096` to use a larger FIT key.

The generated `kas-signing-keys.yml` sets `IMX_SIGN_KEYDIR` for AHAB and `UBOOT_SIGN_KEYDIR` for FIT and enables signing. The helper puts both sets of keys in the chosen directory, but the two settings are independent. Keys and the fragment stay local and are not committed.

Run the helper again to add FIT keys to an existing key directory. It keeps the AHAB keys and updates the generated fragment. With `IMX_SIGN_ENABLE = "1"`, the build signs FIT configurations and embeds a required verification key in U-Boot before AHAB signs `imx-boot`. Deploy the updated bootloader and `fitImage` together.
