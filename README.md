# meta-imx-secure

Minimal OE-Core layer for the NXP FRDM-IMX95, using Yocto Wrynose and kas.

- Machine: `imx95-15x15-lpddr4x-frdm`
- Distro: `imx-secure`
- Image: `imx-secure-image`

## Build

With kas and the Yocto host dependencies installed, run from this directory:

```sh
kas build kas.yml
```

The configuration accepts NXP's EULA and enables passwordless root login for
bring-up. Review `sources/meta-imx/LICENSE.txt` before building.

Images: `build/tmp/deploy/images/imx95-15x15-lpddr4x-frdm/` (`.wic.gz`).

Secure boot signing and provisioning are not implemented yet.

License: [MIT](COPYING.MIT).
