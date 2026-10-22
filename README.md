# meta-imx-secure

Yocto Wrynose layer for NXP FRDM-IMX95 using kas

- Machine: `imx95-15x15-lpddr4x-frdm`
- Distro: `imx-secure`
- Image: `imx-secure-image`

## Build

Install kas and the Yocto host dependencies then run:

```sh
kas build kas-imx-secure.yml
```

NXP's EULA is accepted in `kas-imx-secure.yml` and root login has no password
Read `layers/meta-imx/LICENSE.txt` before building

Images: `build/tmp/deploy/images/imx95-15x15-lpddr4x-frdm/` (`.wic.gz`)

Secure boot signing and provisioning are not set up yet

License: [MIT](COPYING.MIT)
