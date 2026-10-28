FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Mount points for persistent partitions
dirs755 += " ${localstatedir}/data ${localstatedir}/blobs"

# meta-integrity's base-files-ima.inc appends a second securityfs line
# with weak options; our fstab already has a hardened one, so remove it.
do_install:append() {
	sed -i '/^securityfs.*defaults/d' "${D}${sysconfdir}/fstab"
}
