# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit check-reqs eutils mount-boot
MY_PN="debian-sources"
SLOT="$PV/$PVR"
CKV=4.14.12
ZFSV=0.7.6
KV_FULL=${CKV}-${PVR}
EXTRAVERSION=-2
MODVER=${CKV}${EXTRAVERSION}-debian
KERNEL_ARCHIVE="linux_${CKV}.orig.tar.xz"
PATCH_ARCHIVE="linux_${CKV}${EXTRAVERSION}.debian.tar.xz"
SPL_P="spl-${ZFSV}"
ZFS_P="zfs-${ZFSV}"
RESTRICT="binchecks strip mirror"
# based on : http://packages.ubuntu.com/maverick/linux-image-2.6.35-22-server
LICENSE="GPL-2"
KEYWORDS="*"
IUSE="+build +symlink +genkernel-initramfs dracut-initramfs"
REQUIRED_USE="genkernel-initramfs? ( symlink ) dracut-initramfs? ( symlink )"
DEPEND="build? ( >=sys-kernel/genkernel-3.4.40.7 )
		genkernel-initramfs? ( >=sys-kernel/genkernel-3.4.40.7[cryptsetup] )
		dracut-initramfs?  ( >=sys-kernel/dracut-0.4.6 )
		dev-libs/elfutils"
RDEPEND="!=sys-kernel/debian-sources-4.11.11"
DESCRIPTION="Debian Sources (with optional automatic building of kernel and/or initramfs)"
HOMEPAGE="http://www.debian.org"
SRC_URI="
	mirror://funtoo/${KERNEL_ARCHIVE} mirror://funtoo/${PATCH_ARCHIVE}
	https://github.com/zfsonlinux/zfs/releases/download/${ZFS_P}/${SPL_P}.tar.gz
	https://github.com/zfsonlinux/zfs/releases/download/${ZFS_P}/${ZFS_P}.tar.gz
"

S="${WORKDIR}/linux-${CKV}"
SPL_S="${WORKDIR}/${SPL_P}"
ZFS_S="${WORKDIR}/${ZFS_P}"

get_patch_list() {
	[[ -z "${1}" ]] && die "No patch series file specified"
	local patch_series="${1}"
	while read line ; do
		if [[ "${line:0:1}" != "#" ]] ; then
			echo "${line}"
		fi
	done < "${patch_series}"
}

_rootfs_zfs() {
	has_version "sys-fs/zfs[rootfs]"
}

_build_initramfs() {
	use genkernel-initramfs && return 0
	use dracut-initramfs && return 0
	return 1
}

pkg_pretend() {
	# Ensure we have enough disk space to compile
	if use build ; then
		CHECKREQS_DISK_BUILD="20G"

		check-reqs_pkg_setup
	fi
}

pkg_setup() {
	export REAL_ARCH="$ARCH"
	unset ARCH; unset LDFLAGS #will interfere with Makefile if set
}

src_prepare() {

	cd "${S}"
	for debpatch in $( get_patch_list "${WORKDIR}/debian/patches/series" ); do
		epatch -p1 "${WORKDIR}/debian/patches/${debpatch}"
	done
	# end of debian-specific stuff...

	# do not include debian devs certificates
	rm -rf "${WORKDIR}"/debian/certs

	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${EXTRAVERSION}-debian:" Makefile || die
	sed	-i -e 's:#export\tINSTALL_PATH:export\tINSTALL_PATH:' Makefile || die
	rm -f .config >/dev/null
	cp -a "${WORKDIR}"/debian "${T}"
	make -s mrproper || die "make mrproper failed"
	#make -s include/linux/version.h || die "make include/linux/version.h failed"
	cd "${S}"
	cp -aR "${WORKDIR}"/debian "${S}"/debian

	## XFS LIBCRC kernel config fixes, FL-823
	epatch "${FILESDIR}"/debian-sources-3.14.4-xfs-libcrc32c-fix.patch

	## do not configure debian devs certs.
	epatch "${FILESDIR}"/${MY_PN}-4.5.2-certs.patch

	## FL-3381. enable IKCONFIG
	epatch "${FILESDIR}"/${MY_PN}-4.13.10-ikconfig.patch
	
	## FL-4424: enable legacy support for MCELOG.
	epatch "${FILESDIR}"/${MY_PN}-4.13.10-mcelog.patch

	# Apply user patches after stock patches and before building .config.
	eapply_user

	local opts
	opts="standard"
	local myarch="amd64"
	[ "$REAL_ARCH" = "x86" ] && myarch="i386" && opts="$opts 686-pae"
	export KERN_ARCH="$myarch"
	export INST_DIR="usr/src/linux-${P}"
	export BUILD_SUB="build-${KERN_ARCH}"
	cp "${FILESDIR}"/config-extract . || die
	chmod +x config-extract || die
	./config-extract ${myarch} ${opts} || die

	# Copy our config somewhere safe before doing make mrproper.
	cp .config "${T}"/config || die

	# Clean up and prepare for compiling.
	einfo "Preparing kernel sources:"
	make -s mrproper || die "make mrproper failed"
	cp "${T}"/config .config || die
	cp -a "${T}"/debian debian || die
	yes "" | make oldconfig || die
	make -s prepare scripts || die

	einfo "Configuring ${SPL_P}:"
	cd "${SPL_S}"
	econf \
		--enable-linux-builtin=yes \
		--with-linux="${S}" \
		--with-linux-obj="${S}" \
		--libdir="${EPREFIX}/$(get_libdir)" \
		--bindir="${EPREFIX}/bin" \
		--sbindir="${EPREFIX}/sbin" \
		--includedir="${EPREFIX}/usr/include" \
		--datarootdir="${EPREFIX}/usr/share" \
	|| die "Could not configure SPL!"
	elog "Installing ${SPL_P} kernel components into kernel sources at: ${S}"
	./copy-builtin "${S}" || die "Could not copy install SPL sources in kernel!"
	
	einfo "Configuring ${ZFS_P}:"
	cd "${ZFS_S}"
	econf \
		--enable-linux-builtin=yes \
		--with-linux="${S}" \
		--with-linux-obj="${S}" \
		--with-spl="${SPL_S}" \
		--with-spl-obj="${SPL_S}" \
		--libdir="${EPREFIX}/$(get_libdir)" \
		--bindir="${EPREFIX}/bin" \
		--sbindir="${EPREFIX}/sbin" \
		--includedir="${EPREFIX}/usr/include" \
		--datarootdir="${EPREFIX}/usr/share" \
	|| die "Could not configure SPL!"
	elog "Installing ${ZFS_P} kernel components into kernel sources at: ${S}"
	./copy-builtin "${S}" || die "Could not copy install SPL sources in kernel!"
}

src_compile() {
	einfo "Compiling SPL."
	cd "${SPL_S}" && emake || die "Failed to compile SPL!"

	einfo "Compiling ZFS."
	cd "${ZFS_S}" && emake || die "Failed to compile ZFS!"

	einfo "Rebuilding .config with ZFS options."
	cd "${S}"
	cat >> .config <<-EOF
		# Enable spl and zfs in the kernel.
		CONFIG_SPL=y
		CONFIG_ZFS=y
	EOF
	yes "" | make oldconfig || die
	make -s prepare scripts || die
}

src_install() {
	# copy sources into place:
	einfo "Copying sources and installing zfs tools."
	dodir /usr/src
	cp -a "${S}" "${D}/${INST_DIR}" || die
	cp -a "${SPL_S}" "${D}/usr/src/${SPL_P}-${MODVER}" || die
	cd "${SPL_S}" && emake install DESTDIR="${D}" INSTALL_MOD_PATH="${INSTALL_MOD_PATH:-${EROOT}}" || die
	cp -a "${ZFS_S}" "${D}/usr/src/${ZFS_P}-${MODVER}" || die
	cd "${ZFS_S}" && emake install DESTDIR="${D}" INSTALL_MOD_PATH="${INSTALL_MOD_PATH:-${EROOT}}" || die
	cd "${D}" && find \( -iname *.la -o -iname *.a \) -delete || die "Couldn't remove libtool files!"
}

_postinst_genkernel() {
	use build || return
	DEFAULT_KERNEL_SOURCE="${ROOT}${INST_DIR}" CMD_KERNEL_DIR="${ROOT}${INST_DIR}" genkernel ${GKARGS} \
		--oldconfig\
		--save-config \
		--fullname="genkernel-${REAL_ARCH}-${MODVER}" \
		--kerneldir="${ROOT}${INST_DIR}" \
		--makeopts="${MAKEOPTS}" \
		--logfile="${ROOT}var/log/genkernel-kernel.log" \
		--bootdir="${ROOT}boot" \
		--module-prefix="${ROOT}" \
		kernel || die "genkernel kernel failed"

	cd "${ROOT}lib/modules/${MODVER}" && find -iname *.ko -exec strip --strip-debug {} \; || die "Couldn't strip modules!"
}

pkg_postinst() {
	# Install kernel and modules if requested.
	_postinst_genkernel

	# Strip modules

	# Handle /usr/src/linux symlink
	if use symlink ; then
		if [[ -h "${ROOT}usr/src/linux" ]]; then
			rm "${ROOT}usr/src/linux"
			ln -sf "linux-${P}" "${ROOT}usr/src/linux"
		else
			ewarn "/usr/src/linux is not a symlink."
			ewarn "Please rename the directory before creating a link."
		fi
	elif use build ; then
		elog "Please make symlink from /usr/src/linux to linux-${P} before"
		elog "building any packages which depend on the kernel soure code!"
	fi

	# Run depmod against our newly installed modules if they exist.
	if [ -e "${ROOT}lib/modules/${MODVER}" ]; then
		depmod -a "${MODVER}"
	fi

	local rebuild
	rebuild="@module-rebuild"
	has_version "sys-fs/zfs[rootfs]" && rebuild+=" spl zfs zfs-kmod"
	elog "Please run \"emerge ${rebuild} --exclude ${PN}\" to rebuild packages compiled against the kernel source."
	_build_initramfs && elog "Then run \"emerge --config ${PN}\" to generate the initramfs(s)."
}

# Build an initramfs using genkernel.
_initramfs_genkernel() {
	genkernel_img="${ROOT}${INST_DIR}/genkernel-${REAL_ARCH}-${MODVER}"
	if ! [ -e "${genkernel_img}" ] ; then
		genkernel ${GKARGS} \
			--kerneldir="${ROOT}${INST_DIR}" \
			--fullname="genkernel-${REAL_ARCH}-${MODVER}" \
			--makeopts="${MAKEOPTS}" \
			--bootdir="${ROOT}"boot \
			--disklabel \
			--lvm \
			--luks \
			--mdadm \
			$(_rootfs_zfs && printf -- "--zfs") \
			--iscsi \
			--module-prefix="${ROOT}" \
			--logfile="${ROOT}var/log/genkernel-initramfs.log" \
			initramfs || die "genkernel initramfs generation failed"
	else
		elog "Genkernel intramfs already exists at '${genkernel_img}', please rename this file to build a new initramfs."
	fi
}

# Build an initramfs using dracut.
_initramfs_dracut() {
	dracut_img="${ROOT}boot/initramfs-dracut-${REAL_ARCH}-${MODVER}"
	if ! [ -e "${dracut_img}" ] ; then
		dracut "${dracut_img}" "${MODVER}" || die "dracut initramfs generation failed"
	else
		elog "Dracut initramfs already exists at '${dracut_img}', please rename this file to build a new initramfs."
	fi
}

pkg_config() {
	if [ -e "${ROOT}lib/modules/${MODVER}" ]; then
		depmod -a "${MODVER}"

		if ! [[ -h "${ROOT}"usr/src/linux ]] || [[ "$(readlink -f "${ROOT}usr/src/linux")" != "${ROOT}${INST_DIR}" ]] ; then
			elog "${ROOT}usr/src/linux is not a symlink to ${ROOT}${INST_DIR}."
			elog "Any modules installed from external packages may not match the kernel!"
			if _rootfs_zfs ; then ewarn "Cowardly refusing to build initramfs with likely-broken zfs support with root on zfs!" ; die ; fi
		fi
	fi
	use genkernel-initramfs && _initramfs_genkernel
	use dracut-initramfs && _initramfs_dracut
}

