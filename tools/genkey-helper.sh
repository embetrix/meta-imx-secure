#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Generate AHAB SRK pairs, a FIT key and a kas signing-keys fragment
# Usage: tools/genkey-helper.sh [KEY_DIR] [KAS_FRAGMENT] [KEY_TYPE] [FIT_KEY_TYPE] [PQC_KEY_TYPE]
# Defaults: imx-secure-keys, kas-signing-keys.yml, secp384r1, rsa2048 and none
# Key types can also be set with KEY_TYPE, FIT_KEY_TYPE and PQC_KEY_TYPE
# Existing keys are checked and reused, never replaced

set -eu
umask 077

die() {
    echo "Error: $*" >&2
    exit 1
}

usage() {
    echo "Usage: $0 [KEY_DIR] [KAS_FRAGMENT] [KEY_TYPE] [FIT_KEY_TYPE] [PQC_KEY_TYPE]"
    echo "Key types: secp256r1 (or prime256v1), secp384r1, secp521r1, rsa2048, rsa3072, rsa4096"
    echo "Default key type: secp384r1, overridden by KEY_TYPE or the third argument"
    echo "Choose a key type supported by your target SoC"
    echo "FIT key types: rsa2048 (default), rsa3072, rsa4096"
    echo "PQC key types: none (default), mldsa65, mldsa87"
    echo "PQC keys need OpenSSL 3.5 or newer with ML-DSA support and a supported SoC revision"
}

hsm_notice() {
    echo "For production, generate and keep private keys in a Hardware Security Module (HSM)"
    echo "This helper creates file-based keys. The current signing class requires local key files"
    echo "HSM signing needs a separate signature-provider integration"
}

generate_srk_keys() {
    srk_dir=$1
    srk_type=$2
    case "$srk_type" in
        secp256r1|prime256v1|secp384r1|secp521r1)
            curve=$srk_type
            [ "$curve" != secp256r1 ] || curve=prime256v1
            algorithm=EC
            option=-pkeyopt
            option_value="ec_paramgen_curve:$curve"
            pattern="ASN1 OID: $curve"
            ;;
        rsa2048|rsa3072|rsa4096)
            algorithm=RSA
            option=-pkeyopt
            option_value="rsa_keygen_bits:${srk_type#rsa}"
            pattern="Public-Key: (${srk_type#rsa} bit)"
            ;;
        mldsa65|mldsa87)
            algorithm="ML-DSA-${srk_type#mldsa}"
            option=-provparam
            # Native SPSDK ML-DSA keys use the standard seed format
            option_value=ml-dsa.output_formats=seed-only
            pattern="$algorithm Public-Key:"
            ;;
    esac
    mkdir -p "$srk_dir"
    for i in 0 1 2 3; do
        private="$srk_dir/srk${i}.pem"
        public="$srk_dir/srk${i}.pub"
        [ ! -L "$private" ] && [ ! -L "$public" ] || die "SRK files must not be symlinks"
        if [ -e "$private" ]; then
            echo "Checking $private ($srk_type)"
        else
            [ ! -e "$public" ] || die "$public exists without its private key"
            echo "Generating $private ($srk_type)"
            openssl genpkey -algorithm "$algorithm" "$option" "$option_value" \
                -out "$TEMP_DIR/private.pem" || die "OpenSSL cannot generate $srk_type keys in the required format"
            # Hard links publish completed files without overwriting existing keys
            ln "$TEMP_DIR/private.pem" "$private"
            rm "$TEMP_DIR/private.pem"
        fi
        openssl pkey -in "$private" -passin pass: -check -noout >/dev/null ||
            die "Invalid or encrypted private key: $private"
        openssl pkey -in "$private" -passin pass: -pubout -out "$TEMP_DIR/public.pem"
        openssl pkey -pubin -in "$TEMP_DIR/public.pem" -text -noout > "$TEMP_DIR/public.txt"
        grep -Fxq "$pattern" "$TEMP_DIR/public.txt" || die "$private must use $srk_type"
        if [ -e "$public" ]; then
            openssl pkey -pubin -in "$public" -outform DER -out "$TEMP_DIR/existing.der"
            openssl pkey -pubin -in "$TEMP_DIR/public.pem" -outform DER -out "$TEMP_DIR/derived.der"
            cmp -s "$TEMP_DIR/existing.der" "$TEMP_DIR/derived.der" ||
                die "$public does not match $private"
        else
            ln "$TEMP_DIR/public.pem" "$public"
        fi
        rm "$TEMP_DIR/public.pem"
        chmod 600 "$private"
        chmod 644 "$public"
    done
}

case "${1:-}" in
    -h|--help)
        usage
        echo
        hsm_notice
        exit 0
        ;;
esac
[ "$#" -le 5 ] || die "Usage: $0 [KEY_DIR] [KAS_FRAGMENT] [KEY_TYPE] [FIT_KEY_TYPE] [PQC_KEY_TYPE]"
command -v openssl >/dev/null 2>&1 || die "Install openssl first"

KEY_DIR=${1:-imx-secure-keys}
KAS_FRAGMENT=${2:-kas-signing-keys.yml}
KEY_TYPE=${3:-${KEY_TYPE:-secp384r1}}
FIT_KEY_TYPE=${4:-${FIT_KEY_TYPE:-rsa2048}}
PQC_KEY_TYPE=${5:-${PQC_KEY_TYPE:-none}}
case "$FIT_KEY_TYPE" in
    rsa2048|rsa3072|rsa4096) ;;
    *) usage >&2; die "Unsupported FIT key type: $FIT_KEY_TYPE" ;;
esac
case "$KEY_TYPE" in
    secp256r1|prime256v1|secp384r1|secp521r1|rsa2048|rsa3072|rsa4096) ;;
    *) usage >&2; die "Unsupported key type: $KEY_TYPE" ;;
esac
case "$PQC_KEY_TYPE" in
    none) ;;
    mldsa65|mldsa87)
        openssl list -signature-algorithms 2>/dev/null | grep -Fq "ML-DSA-${PQC_KEY_TYPE#mldsa}" ||
            die "OpenSSL does not support $PQC_KEY_TYPE. Install OpenSSL with ML-DSA support"
        ;;
    mldsa44) die "ML-DSA-44 is not supported for AHAB signing. Use mldsa65 or mldsa87" ;;
    *) usage >&2; die "Unsupported PQC key type: $PQC_KEY_TYPE" ;;
esac
# Keep generated BitBake assignments and kas paths literal
for path in "$KEY_DIR" "$KAS_FRAGMENT"; do
    case "$path" in
        ''|*[!a-zA-Z0-9_./+-]*) die "Use paths containing only letters, digits, /, ., _, + or -" ;;
        -*) die "Use ./ before a path starting with -" ;;
    esac
done
mkdir -p "$KEY_DIR"
KEY_DIR=$(cd "$KEY_DIR" && pwd -P)
case "$KEY_DIR" in
    *[!a-zA-Z0-9_./+-]*) die "The resolved key directory contains unsupported characters" ;;
esac
[ -d "$(dirname "$KAS_FRAGMENT")" ] || die "The kas fragment directory does not exist"
[ ! -L "$KAS_FRAGMENT" ] || die "The kas fragment must not be a symlink"

TEMP_DIR=$(mktemp -d "$KEY_DIR/.genkey.XXXXXX")
trap 'rm -rf "$TEMP_DIR"' EXIT
trap 'exit 1' HUP INT TERM

cat > "$TEMP_DIR/kas.yml" <<EOF
# Generated by tools/genkey-helper.sh
header:
  version: 14

local_conf_header:
  signing_keys: |
    IMX_SIGN_ENABLE = "1"
    IMX_SIGN_KEYDIR = "$KEY_DIR"
    IMX_SIGN_SRK_ID ?= "0"
EOF
# Accept the previous helper's fragment when adding FIT signing
cp "$TEMP_DIR/kas.yml" "$TEMP_DIR/kas-ahab.yml"
echo "    FIT_SIGN_ALG = \"$FIT_KEY_TYPE\"" >> "$TEMP_DIR/kas.yml"
cp "$TEMP_DIR/kas.yml" "$TEMP_DIR/kas-fit.yml"
echo "    UBOOT_SIGN_KEYDIR = \"$KEY_DIR\"" >> "$TEMP_DIR/kas.yml"
cp "$TEMP_DIR/kas.yml" "$TEMP_DIR/kas-classical.yml"
if [ "$PQC_KEY_TYPE" != none ]; then
    printf '%s\n' '    IMX_SIGN_PQC_ENABLE = "1"' \
        '    IMX_SIGN_PQC_KEYDIR = "${IMX_SIGN_KEYDIR}/mldsa"' >> "$TEMP_DIR/kas.yml"
    [ ! -L "$KEY_DIR/mldsa" ] || die "The generated PQC key directory must not be a symlink"
fi
if [ -e "$KAS_FRAGMENT" ]; then
    cmp -s "$TEMP_DIR/kas.yml" "$KAS_FRAGMENT" ||
        cmp -s "$TEMP_DIR/kas-classical.yml" "$KAS_FRAGMENT" ||
        cmp -s "$TEMP_DIR/kas-fit.yml" "$KAS_FRAGMENT" ||
        cmp -s "$TEMP_DIR/kas-ahab.yml" "$KAS_FRAGMENT" ||
        die "$KAS_FRAGMENT already exists with different settings, choose another fragment path"
fi

generate_srk_keys "$KEY_DIR" "$KEY_TYPE"
if [ "$PQC_KEY_TYPE" != none ]; then
    generate_srk_keys "$KEY_DIR/mldsa" "$PQC_KEY_TYPE"
fi

# FIT uses a separate key and certificate for U-Boot verification
private="$KEY_DIR/fit.key"
certificate="$KEY_DIR/fit.crt"
[ ! -L "$private" ] && [ ! -L "$certificate" ] || die "FIT files must not be symlinks"
if [ -e "$private" ]; then
    echo "Checking FIT key"
else
    [ ! -e "$certificate" ] || die "$certificate exists without its private key"
    echo "Generating FIT key ($FIT_KEY_TYPE)"
    openssl genpkey -algorithm RSA -pkeyopt "rsa_keygen_bits:${FIT_KEY_TYPE#rsa}" \
        -out "$TEMP_DIR/fit.key"
    ln "$TEMP_DIR/fit.key" "$private"
fi
openssl rsa -in "$private" -passin pass: -check -noout >/dev/null ||
    die "Invalid or encrypted FIT private key: $private"
openssl pkey -in "$private" -passin pass: -pubout -out "$TEMP_DIR/fit.pub"
openssl pkey -pubin -in "$TEMP_DIR/fit.pub" -text -noout > "$TEMP_DIR/fit-public.txt"
grep -Fxq "Public-Key: (${FIT_KEY_TYPE#rsa} bit)" "$TEMP_DIR/fit-public.txt" ||
    die "$private must use $FIT_KEY_TYPE"
if [ ! -e "$certificate" ]; then
    openssl req -new -x509 -sha256 -days 3650 -subj "/CN=i.MX FIT signing/" \
        -key "$private" -passin pass: -out "$TEMP_DIR/fit.crt"
    ln "$TEMP_DIR/fit.crt" "$certificate"
fi
openssl x509 -in "$certificate" -pubkey -noout > "$TEMP_DIR/fit-cert.pub"
openssl pkey -pubin -in "$TEMP_DIR/fit-cert.pub" -outform DER -out "$TEMP_DIR/fit-cert.der"
openssl pkey -pubin -in "$TEMP_DIR/fit.pub" -outform DER -out "$TEMP_DIR/fit-key.der"
cmp -s "$TEMP_DIR/fit-cert.der" "$TEMP_DIR/fit-key.der" ||
    die "$certificate does not match $private"
chmod 600 "$private"
chmod 644 "$certificate"

if [ ! -e "$KAS_FRAGMENT" ]; then
    (set -C; cat "$TEMP_DIR/kas.yml" > "$KAS_FRAGMENT")
elif ! cmp -s "$TEMP_DIR/kas.yml" "$KAS_FRAGMENT"; then
    cat "$TEMP_DIR/kas.yml" > "$KAS_FRAGMENT"
fi
echo "Keys checked in: $KEY_DIR"
echo "Kas fragment: $KAS_FRAGMENT"
echo "Build with: kas build kas-imx-secure.yml:$KAS_FRAGMENT"
echo
hsm_notice
