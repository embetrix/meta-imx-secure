# meta-imx-secure

A Yocto layer that provides a security-hardened baseline for i.MX device, extending NXP layers with secure boot, verified and encrypted storage, runtime integrity and a hardened kernel and userspace.

## Build

Install kas and the Yocto host dependencies then run:

```sh
KAS_MACHINE=<machine> kas build kas-imx-secure.yml
```
