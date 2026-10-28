FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Enable client and supplicant debug traces in development, keep errors in production
EXTRA_OECMAKE:append = " \
    -DCFG_TEE_CLIENT_LOG_LEVEL=${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', '3', '1', d)} \
    -DCFG_TEE_SUPP_LOG_LEVEL=${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', '3', '1', d)} \
"

SRC_URI += " \
    file://tee-supplicant-storage.conf \
    file://var-blobs.mount \
"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}/tee-supplicant@.service.d
    sed -e 's|@base_bindir@|${base_bindir}|g' \
        -e 's|@sbindir@|${sbindir}|g' \
        -e 's|@localstatedir@|${localstatedir}|g' \
        ${UNPACKDIR}/tee-supplicant-storage.conf \
        > ${D}${systemd_system_unitdir}/tee-supplicant@.service.d/storage.conf
    chmod 0644 ${D}${systemd_system_unitdir}/tee-supplicant@.service.d/storage.conf
    install -m 0644 ${UNPACKDIR}/var-blobs.mount ${D}${systemd_system_unitdir}/var-blobs.mount
}

FILES:${PN} += " \
    ${systemd_system_unitdir}/tee-supplicant@.service.d \
    ${systemd_system_unitdir}/var-blobs.mount \
"
