# HSM signing

[Back to README](../README.md)

Sign AHAB boot images and AHAB-wrapped FIT images through PKCS#11. The private key stays in the token. FIT signature keys are configured separately.

## Hardware HSM setup

Export the four SRK public keys as `srk0.pub` through `srk3.pub` into `IMX_SIGN_KEYDIR`. Keep this directory separate from keys managed by `tools/generate-signing-keys.sh`.

Set these values in your build configuration:

```bitbake
IMX_SIGN_ENABLE = "1"
IMX_SIGN_KEYDIR = "/opt/hsm/signing/ahab"
IMX_SIGN_SRK_FILES = "srk0.pub srk1.pub srk2.pub srk3.pub"
IMX_SIGN_SRK_ID = "0"
IMX_SIGN_PKCS11_URI = "pkcs11:token=boot-signing;object=srk0;id=%01;type=private"
IMX_SIGN_PKCS11_MODULE = "/opt/hsm/lib/vendor-pkcs11.so"
IMX_SIGN_PKCS11_PIN_FILE = "/run/secrets/ahab-hsm-pin"
```

Use the HSM vendor's PKCS#11 library for the build host. Put only the PIN in the PIN file and restrict access to the build user. Container builds need access to the library, key directory, PIN file and HSM.

## Optional: use a PEM key reference

To use a PEM key reference, leave `IMX_SIGN_PKCS11_URI` empty and set `IMX_SIGN_PRIVATE_KEY` and `IMX_SIGN_PKCS11_MODULE` instead. Keep the PIN file setting. Create a reference with the provider's [uri2pem.py tool](https://github.com/openssl-projects/pkcs11-provider/blob/main/tools/uri2pem.py):

```sh
python3 uri2pem.py \
    'pkcs11:token=boot-signing;object=srk0;id=%01;type=private' \
    --out /opt/hsm/signing/ahab/srk0.pem
```

For SoftHSM, set `IMX_SIGN_PKCS11_MODULE = "softhsm"`.

## SoftHSM example

Install SoftHSM, OpenSC (`pkcs11-tool`) and OpenSSL on the host. From the layer directory, run:

```sh
tools/generate-softhsm-ahab-keys.py
```

The script uses host tools to create four ECDSA P-384 keys in a new token:

- `imx-softhsm-ahab/`: token store, public keys, config and random user and SO PIN files
- `kas-softhsm-ahab.yml`: AHAB signing settings for the build

Use `--ahab-type rsa4096` for RSA or `--module /path/to/libsofthsm2.so` for a custom host library. Existing outputs are never overwritten. Use `--key-dir` and `--kas-fragment` to choose new output paths.

Build with both signing fragments. `kas-signing-keys.yml` supplies the keys for FIT, module signing, IMA, AVB and SWUpdate. Create it with `tools/generate-signing-keys.sh` if needed:

```sh
kas build kas-imx-secure.yml:kas-signing-keys.yml:kas-softhsm-ahab.yml
```

Keep the SoftHSM fragment last so its AHAB settings override the file key settings. It configures AHAB only and disables AHAB PQC signing.

## Limitations

- ECDSA and RSA-PSS only, with SHA-256, SHA-384 or SHA-512. ML-DSA needs local key files
- URIs need `type=private`, `token` or `serial`, and `object` or `id`. No query parameters or embedded PINs
- The HSM key must match the public key selected by `IMX_SIGN_SRK_ID`
- PEM references must stay inside `IMX_SIGN_KEYDIR`, with no `;` or `=` in their paths

Continue with [building images](building-images.md#3-select-the-machine-and-profile). See [AHAB provisioning](ahab-provisioning.md) for SRK fuse setup.
