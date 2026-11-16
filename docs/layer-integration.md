# Layer integration

[Back to README](../README.md)

Use this guide to add the layer to an existing Yocto build. For the complete kas build steps, see [building images](building-images.md).

## Add the layer to an existing build

For an existing Yocto build, add the [layer dependencies](../README.md#layer-dependencies) listed in [kas-imx-secure.yml](../kas-imx-secure.yml) and the signing settings from the key helper. Select `DISTRO = "imx-secure"` or reuse [imx-secure-distro.inc](../conf/distro/include/imx-secure-distro.inc) in your own distro configuration:

```bitbake
require conf/distro/include/imx-secure-distro.inc
```

Use [imx-secure-image-base.bb](../recipes-core/images/imx-secure-image-base.bb) as the image base, keeping its read-only root filesystem and security packages. Machine and storage defaults are in [imx-secure.inc](../conf/machine/include/imx-secure.inc).

A [Docker](../Dockerfile) build environment and [Jenkins](../Jenkinsfile) pipeline are included for automated builds.

See [build artifacts](building-images.md#build-artifacts) for the generated files.
