#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Generate signing keys by role and write their paths to a kas fragment
# Existing keys are checked and reused and not replaced

set -eu
umask 077

die() {
    echo "Error: $*" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage: $0 [options]
  --key-dir DIR        Key directory (default: imx-secure-keys)
  --kas-fragment FILE  Kas output (default: kas-signing-keys.yml)
  --ahab-type TYPE     secp256r1, prime256v1, secp384r1 (default), secp521r1,
                       rsa2048, rsa3072 or rsa4096
  --ahab-pqc-type TYPE none (default), mldsa65 or mldsa87
  --fit-type TYPE      rsa2048 (default), rsa3072 or rsa4096
  --modsign-type TYPE  secp256r1, prime256v1 (default), secp384r1, secp521r1,
                       rsa2048, rsa3072 or rsa4096
  --ima-type TYPE      Same choices as --modsign-type (default: prime256v1)
  --avb-type TYPE      rsa2048, rsa4096 (default) or rsa8192
  -h, --help           Show this help

AHAB_KEY_TYPE, AHAB_PQC_TYPE, FIT_KEY_TYPE, MODSIGN_KEY_TYPE,
IMA_KEY_TYPE and AVB_KEY_TYPE set algorithm defaults
Command-line options override these defaults

Files use role/role-algorithm.key and .crt names, or ahab/srkN-algorithm.key and .pub
Certificates use PEM, except IMA which uses DER
The SSH CA uses Ed25519 keys in OpenSSH format
The kas fragment sets the AVB algorithm to match the key size
Choose AHAB key types supported by your target SoC and revision
PQC keys need OpenSSL with ML-DSA seed-format support
EOF
}

hsm_notice() {
    echo "For production, generate and keep private keys in a Hardware Security Module (HSM)"
    echo "This helper creates file-based keys. The current signing class requires local key files"
    echo "HSM signing needs a separate signature-provider integration"
}

classical_key_type() {
    case "$2" in
        secp256r1) echo prime256v1 ;;
        prime256v1|secp384r1|secp521r1|rsa2048|rsa3072|rsa4096) echo "$2" ;;
        *) die "Unsupported $1 key type: $2" ;;
    esac
}

parse_options() {
    KEY_DIR=imx-secure-keys
    KAS_FRAGMENT=kas-signing-keys.yml
    AHAB_KEY_TYPE=${AHAB_KEY_TYPE:-secp384r1}
    FIT_KEY_TYPE=${FIT_KEY_TYPE:-rsa2048}
    AHAB_PQC_TYPE=${AHAB_PQC_TYPE:-none}
    MODSIGN_KEY_TYPE=${MODSIGN_KEY_TYPE:-prime256v1}
    IMA_KEY_TYPE=${IMA_KEY_TYPE:-prime256v1}
    AVB_KEY_TYPE=${AVB_KEY_TYPE:-rsa4096}
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            --key-dir|--kas-fragment|--ahab-type|--ahab-pqc-type|--fit-type|--modsign-type|--ima-type|--avb-type)
                [ "$#" -ge 2 ] && [ -n "$2" ] || die "Missing value for $1"
                case "$1" in
                    --key-dir) KEY_DIR=$2 ;;
                    --kas-fragment) KAS_FRAGMENT=$2 ;;
                    --ahab-type) AHAB_KEY_TYPE=$2 ;;
                    --ahab-pqc-type) AHAB_PQC_TYPE=$2 ;;
                    --fit-type) FIT_KEY_TYPE=$2 ;;
                    --modsign-type) MODSIGN_KEY_TYPE=$2 ;;
                    --ima-type) IMA_KEY_TYPE=$2 ;;
                    --avb-type) AVB_KEY_TYPE=$2 ;;
                esac
                shift 2
                ;;
            *) die "Unknown option: $1" ;;
        esac
    done
    AHAB_KEY_TYPE=$(classical_key_type AHAB "$AHAB_KEY_TYPE")
    MODSIGN_KEY_TYPE=$(classical_key_type module "$MODSIGN_KEY_TYPE")
    IMA_KEY_TYPE=$(classical_key_type IMA "$IMA_KEY_TYPE")
    case "$FIT_KEY_TYPE" in
        rsa2048|rsa3072|rsa4096) ;;
        *) die "Unsupported FIT key type: $FIT_KEY_TYPE" ;;
    esac
    case "$AHAB_PQC_TYPE" in
        none|mldsa65|mldsa87) ;;
        *) die "Unsupported PQC key type: $AHAB_PQC_TYPE. Use none, mldsa65 or mldsa87" ;;
    esac
    case "$AVB_KEY_TYPE" in
        rsa2048|rsa4096|rsa8192) ;;
        *) die "Unsupported AVB key type: $AVB_KEY_TYPE. Use rsa2048, rsa4096 or rsa8192" ;;
    esac
    FIT_BASE=fit/fit-$FIT_KEY_TYPE
    MODSIGN_BASE=modsign/modsign-$MODSIGN_KEY_TYPE
    IMA_BASE=ima/ima-$IMA_KEY_TYPE
    AVB_BASE=avb/avb-$AVB_KEY_TYPE
    SSH_CA_BASE=ssh-ca/ssh-ca-ed25519
}

check_file() {
    [ ! -L "$1" ] || die "$1 must not be a symlink"
    [ ! -e "$1" ] || [ -f "$1" ] || die "$1 must be a regular file"
}

prepare() {
    command -v openssl >/dev/null 2>&1 || die "Install openssl first"
    command -v ssh-keygen >/dev/null 2>&1 || die "Install ssh-keygen first"
    for path in "$KEY_DIR" "$KAS_FRAGMENT"; do
        case "$path" in
            ''|*[!a-zA-Z0-9_./+-]*) die "Use paths containing only letters, digits, /, ., _, + or -" ;;
            -*) die "Use ./ before a path starting with -" ;;
        esac
    done
    check_file "$KAS_FRAGMENT"
    [ -d "$(dirname "$KAS_FRAGMENT")" ] || die "The kas fragment directory does not exist"
    mkdir -p "$KEY_DIR"
    KEY_DIR=$(cd "$KEY_DIR" && pwd -P)
    case "$KEY_DIR" in
        *[!a-zA-Z0-9_./+-]*) die "The resolved key directory contains unsupported characters" ;;
    esac
    for role in ahab fit modsign ima avb ssh-ca; do
        [ ! -L "$KEY_DIR/$role" ] || die "$role directory must not be a symlink"
        [ ! -e "$KEY_DIR/$role" ] || [ -d "$KEY_DIR/$role" ] || die "$role must be a directory"
    done
    TEMP_DIR=$(mktemp -d "$KEY_DIR/.genkey.XXXXXX")
    FRAGMENT_TEMP=
    trap 'rm -rf "$TEMP_DIR"; if [ -n "$FRAGMENT_TEMP" ]; then rm -f "$FRAGMENT_TEMP"; fi' EXIT
    trap 'exit 1' HUP INT TERM
    if [ "$AHAB_PQC_TYPE" != none ]; then
        # Check the exact format before writing any keys
        generate_private "$AHAB_PQC_TYPE" "$TEMP_DIR/pqc-probe.key"
    fi
}

# One row per pair: base, algorithm, public format, subject
key_specs() (
    for i in 0 1 2 3; do
        echo "ahab/srk$i-$AHAB_KEY_TYPE|$AHAB_KEY_TYPE|PUB|AHAB"
        if [ "$AHAB_PQC_TYPE" != none ]; then
            echo "ahab/srk$i-$AHAB_PQC_TYPE|$AHAB_PQC_TYPE|PUB|AHAB"
        fi
    done
    cat <<EOF
$FIT_BASE|$FIT_KEY_TYPE|PEM|i.MX FIT signing
$MODSIGN_BASE|$MODSIGN_KEY_TYPE|PEM|i.MX module signing
$IMA_BASE|$IMA_KEY_TYPE|DER|i.MX IMA-EVM signing
$AVB_BASE|$AVB_KEY_TYPE|PEM|i.MX AVB signing
$SSH_CA_BASE|ed25519|SSH|i.MX SSH CA
EOF
)

generate_private() (
    key_type=$1
    output=$2
    case "$key_type" in
        ed25519)
            ssh-keygen -q -t ed25519 -N "" -C "Embetrix i.MX SSH CA" -f "$output"
            rm "$output.pub"
            exit 0 ;;
        prime256v1|secp384r1|secp521r1)
            set -- -algorithm EC -pkeyopt "ec_paramgen_curve:$key_type" ;;
        rsa2048|rsa3072|rsa4096|rsa8192)
            set -- -algorithm RSA -pkeyopt "rsa_keygen_bits:${key_type#rsa}" ;;
        mldsa65|mldsa87)
            set -- -algorithm "ML-DSA-${key_type#mldsa}" -provparam ml-dsa.output_formats=seed-only ;;
        *) die "Unsupported key type: $key_type" ;;
    esac
    openssl genpkey "$@" -out "$output" || die "OpenSSL cannot generate $key_type keys in the required format"
)

check_private() (
    private=$1
    key_type=$2
    if [ "$key_type" = ed25519 ]; then
        ssh-keygen -y -P "" -f "$private" > "$TEMP_DIR/derived.pub" ||
            die "Invalid or encrypted SSH CA private key: $private"
        read -r public_type public_data < "$TEMP_DIR/derived.pub"
        [ "$public_type" = ssh-ed25519 ] || die "$private must use ed25519"
        exit 0
    fi
    openssl pkey -in "$private" -passin pass: -check -noout >/dev/null ||
        die "Invalid or encrypted private key: $private"
    openssl pkey -in "$private" -passin pass: -pubout -out "$TEMP_DIR/derived.pub"
    openssl pkey -pubin -in "$TEMP_DIR/derived.pub" -text -noout > "$TEMP_DIR/public.txt"
    case "$key_type" in
        rsa*) pattern="Public-Key: (${key_type#rsa} bit)" ;;
        mldsa*) pattern="ML-DSA-${key_type#mldsa} Public-Key:" ;;
        *) pattern="ASN1 OID: $key_type" ;;
    esac
    grep -Fxq "$pattern" "$TEMP_DIR/public.txt" || die "$private must use $key_type"
)

check_pair() (
    private=$1
    public=$2
    key_type=$3
    format=$4
    check_file "$private"
    check_file "$public"
    if [ ! -e "$private" ]; then
        [ ! -e "$public" ] || die "$public exists without its private key"
        exit 0
    fi
    check_private "$private" "$key_type"
    [ -e "$public" ] || exit 0
    if [ "$format" = SSH ]; then
        ssh-keygen -l -f "$public" >/dev/null || die "Invalid SSH CA public key: $public"
        awk 'NF { print $1 " " $2 }' "$public" > "$TEMP_DIR/existing.ssh"
        awk 'NF { print $1 " " $2 }' "$TEMP_DIR/derived.pub" > "$TEMP_DIR/derived.ssh"
        cmp -s "$TEMP_DIR/existing.ssh" "$TEMP_DIR/derived.ssh" || die "$public does not match $private"
        exit 0
    elif [ "$format" = PUB ]; then
        openssl pkey -pubin -in "$public" -outform DER -out "$TEMP_DIR/existing.der"
    else
        openssl x509 -inform "$format" -in "$public" -pubkey -noout > "$TEMP_DIR/cert.pub"
        openssl pkey -pubin -in "$TEMP_DIR/cert.pub" -outform DER -out "$TEMP_DIR/existing.der"
    fi
    openssl pkey -pubin -in "$TEMP_DIR/derived.pub" -outform DER -out "$TEMP_DIR/derived.der"
    cmp -s "$TEMP_DIR/existing.der" "$TEMP_DIR/derived.der" || die "$public does not match $private"
)

# Publish completed files without overwriting existing keys
publish() (
    chmod "$3" "$1"
    ln "$1" "$2"
    rm "$1"
)

process_pair() (
    phase=$1
    base=$KEY_DIR/$2
    key_type=$3
    format=$4
    subject=$5
    private=$base.key
    public=$base.crt
    case "$format" in PUB|SSH) public=$base.pub ;; esac

    if [ "$phase" = check ]; then
        # A different filename must not silently create a replacement key
        for other in "${base%-$key_type}"-*.key "${base%-$key_type}"-*.pub "${base%-$key_type}"-*.crt; do
            [ -e "$other" ] || [ -L "$other" ] || continue
            case "${other##*/}:$key_type" in
                srk*-mldsa*:mldsa*) ;;
                srk*-mldsa*:*) continue ;;
                srk*:mldsa*) continue ;;
            esac
            [ "$other" = "$private" ] || [ "$other" = "$public" ] ||
                die "Another key type already exists: $other. Use a separate key directory"
        done
        check_pair "$private" "$public" "$key_type" "$format"
        exit 0
    fi

    mkdir -p "${base%/*}"
    if [ ! -e "$private" ]; then
        echo "Generating $private"
        generate_private "$key_type" "$TEMP_DIR/new.key"
        publish "$TEMP_DIR/new.key" "$private" 600
    fi
    if [ ! -e "$public" ]; then
        if [ "$format" = SSH ]; then
            ssh-keygen -y -P "" -f "$private" > "$TEMP_DIR/new.public"
        elif [ "$format" = PUB ]; then
            openssl pkey -in "$private" -passin pass: -pubout -out "$TEMP_DIR/new.public"
        else
            set --
            if [ "$subject" != 'i.MX FIT signing' ]; then
                set -- -addext "basicConstraints=critical,CA:FALSE" \
                    -addext "keyUsage=digitalSignature" \
                    -addext "extendedKeyUsage=critical,codeSigning" \
                    -addext "subjectKeyIdentifier=hash"
                subject="$subject/O=Embetrix"
            fi
            openssl req -new -x509 -sha256 -days 3650 -batch -subj "/CN=$subject/" \
                "$@" -key "$private" -passin pass: -outform "$format" -out "$TEMP_DIR/new.public"
        fi
        publish "$TEMP_DIR/new.public" "$public" 644
    fi
    check_pair "$private" "$public" "$key_type" "$format"
    chmod 600 "$private"
    chmod 644 "$public"
)

process_keys() (
    while IFS='|' read -r base algorithm format subject; do
        process_pair "$1" "$base" "$algorithm" "$format" "$subject"
    done < "$TEMP_DIR/specs"
)

srk_settings() (
    prefix=$1
    algorithm=$2
    printf '    %s_KEYDIR = "%s/ahab"\n' "$prefix" "$KEY_DIR"
    printf '    %s_PRIVATE_KEY = "${%s_KEYDIR}/srk${IMX_SIGN_SRK_ID}-%s.key"\n' "$prefix" "$prefix" "$algorithm"
    printf '    %s_SRK_FILES = "srk0-%s.pub srk1-%s.pub srk2-%s.pub srk3-%s.pub"\n' \
        "$prefix" "$algorithm" "$algorithm" "$algorithm" "$algorithm"
)

render_fragment() {
    cat <<EOF
# Generated by tools/generate-signing-keys.sh
header:
  version: 14

local_conf_header:
  signing_keys: |
    IMX_SIGN_ENABLE = "1"
    IMX_SIGN_SRK_ID ?= "0"
EOF
    srk_settings IMX_SIGN "$AHAB_KEY_TYPE"
    if [ "$AHAB_PQC_TYPE" != none ]; then
        echo '    IMX_SIGN_PQC_ENABLE = "1"'
        srk_settings IMX_SIGN_PQC "$AHAB_PQC_TYPE"
    fi
    cat <<EOF
    FIT_SIGN_ALG = "$FIT_KEY_TYPE"
    UBOOT_SIGN_KEYDIR = "$KEY_DIR/fit"
    UBOOT_SIGN_KEYNAME = "fit-$FIT_KEY_TYPE"
    MODSIGN_PRIVKEY ?= "$KEY_DIR/$MODSIGN_BASE.key"
    MODSIGN_X509 ?= "$KEY_DIR/$MODSIGN_BASE.crt"
    IMA_EVM_PRIVKEY ?= "$KEY_DIR/$IMA_BASE.key"
    IMA_EVM_X509 ?= "$KEY_DIR/$IMA_BASE.crt"
    AVB_SIGN_KEY ?= "$KEY_DIR/$AVB_BASE.key"
    AVB_X509 ?= "$KEY_DIR/$AVB_BASE.crt"
    AVB_ALGORITHM = "SHA256_RSA${AVB_KEY_TYPE#rsa}"
    OPENSSH_CA_PUBKEY ?= "$KEY_DIR/$SSH_CA_BASE.pub"
EOF
}

check_fragment() (
    [ -e "$KAS_FRAGMENT" ] || exit 0
    cp "$KAS_FRAGMENT" "$TEMP_DIR/original.yml"
    cmp -s "$TEMP_DIR/kas.yml" "$KAS_FRAGMENT" && exit 0
    # Allow adding PQC keys or the SSH CA setting to the current layout
    (AHAB_PQC_TYPE=none; render_fragment) > "$TEMP_DIR/without-pqc.yml"
    for candidate in "$TEMP_DIR/kas.yml" "$TEMP_DIR/without-pqc.yml"; do
        cmp -s "$candidate" "$KAS_FRAGMENT" && exit 0
        sed '/^    OPENSSH_CA_PUBKEY /d' "$candidate" > "$TEMP_DIR/without-ssh-ca.yml"
        cmp -s "$TEMP_DIR/without-ssh-ca.yml" "$KAS_FRAGMENT" && exit 0
    done
    die "$KAS_FRAGMENT already exists with different settings, choose another fragment path"
)

write_fragment() {
    check_file "$KAS_FRAGMENT"
    if [ -e "$TEMP_DIR/original.yml" ]; then
        cmp -s "$TEMP_DIR/original.yml" "$KAS_FRAGMENT" || die "$KAS_FRAGMENT changed during key generation"
    else
        [ ! -e "$KAS_FRAGMENT" ] || die "$KAS_FRAGMENT appeared during key generation"
    fi
    cmp -s "$TEMP_DIR/kas.yml" "$KAS_FRAGMENT" && return 0
    FRAGMENT_TEMP=$(mktemp "$KAS_FRAGMENT.XXXXXX")
    cat "$TEMP_DIR/kas.yml" > "$FRAGMENT_TEMP"
    if [ -e "$TEMP_DIR/original.yml" ]; then
        mv -f "$FRAGMENT_TEMP" "$KAS_FRAGMENT"
    else
        ln "$FRAGMENT_TEMP" "$KAS_FRAGMENT"
        rm "$FRAGMENT_TEMP"
    fi
    FRAGMENT_TEMP=
}

main() {
    parse_options "$@"
    prepare
    key_specs > "$TEMP_DIR/specs"
    render_fragment > "$TEMP_DIR/kas.yml"
    check_fragment
    process_keys check
    process_keys generate
    write_fragment
    echo "Keys checked in: $KEY_DIR"
    echo "Kas fragment: $KAS_FRAGMENT"
    echo "Build with: kas build kas-imx-secure.yml:$KAS_FRAGMENT"
    echo
    hsm_notice
}

main "$@"
