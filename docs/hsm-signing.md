# HSM signing

[Back to README](../README.md)

Sign AHAB boot images and FIT wrappers using an HSM. A `PKCS#11 PROVIDER URI` PEM file points to the key. The private key stays on the HSM.

## Create a key reference

Create the reference with the provider's [uri2pem.py tool](https://github.com/openssl-projects/pkcs11-provider/blob/main/tools/uri2pem.py):

```sh
python3 uri2pem.py \
    'pkcs11:token=boot-signing;object=srk0;id=%01;type=private' \
    --out /opt/hsm/signing/ahab/srk0.pem
```

Export the matching public key to `srk0.pub`. Keep `srk0.pub` through `srk3.pub` and the reference PEM in the same directory, separate from keys managed by `tools/generate-signing-keys.sh`.

## Configure the build

Set these values in your build configuration:

```bitbake
IMX_SIGN_ENABLE = "1"
IMX_SIGN_KEYDIR = "/opt/hsm/signing/ahab"
IMX_SIGN_PRIVATE_KEY = "srk0.pem"
IMX_SIGN_SRK_ID = "0"
IMX_SIGN_PKCS11_MODULE = "/opt/hsm/lib/vendor-pkcs11.so"
IMX_SIGN_PKCS11_PIN_FILE = "/run/secrets/ahab-hsm-pin"
```

Use the HSM vendor's PKCS#11 library for the build host. Put only the PIN in the PIN file and restrict access to the build user. Container builds need access to the library, key directory, PIN file and HSM.

## Limitations

- Supported keys: ECDSA and RSA-PSS with SHA-256, SHA-384 or SHA-512, depending on the chip and HSM. ML-DSA keys still need local files
- The URI needs `type=private`, a `token` or `serial`, and an `object` or `id`. Use percent encoding for labels and binary IDs. Optional `manufacturer` and `model` fields are supported. Other fields and query parameters, including PINs, are rejected
- Reference PEM files must stay inside `IMX_SIGN_KEYDIR`. Their paths must not contain `;` or `=`
- The HSM key must match the public key selected by `IMX_SIGN_SRK_ID`. Update the reference and public key files when rotating keys so BitBake sees the change

Continue with [building images](building-images.md#3-select-the-machine-and-profile). See [AHAB provisioning](ahab-provisioning.md) for SRK fuse setup.
