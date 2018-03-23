# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit check-reqs eutils mount-boot

SLOT=$PVR
CKV=4.14.12
KV_FULL=${PN}-${PVR}
EXTRAVERSION=-2
MODVER=${CKV}${EXTRAVERSION}-debian
KERNEL_ARCHIVE="linux_${PV}.orig.tar.xz"
PATCH_ARCHIVE="linux_${PV}${EXTRAVERSION}.debian.tar.xz"
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
SRC_URI="mirror://funtoo/${KERNEL_ARCHIVE} mirror://funtoo/${PATCH_ARCHIVE}"
S="$WORKDIR/linux-${CKV}"

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
	use genkernel-initramfs || use dracut-initramfs
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
	epatch "${FILESDIR}"/${PN}-4.5.2-certs.patch

	## FL-3381. enable IKCONFIG
	epatch "${FILESDIR}"/${PN}-4.13.10-ikconfig.patch
	
	## FL-4424: enable legacy support for MCELOG.
	epatch "${FILESDIR}"/${PN}-4.13.10-mcelog.patch
	
	local opts
	opts="standard"
	local myarch="amd64"
	[ "$REAL_ARCH" = "x86" ] && myarch="i386" && opts="$opts 686-pae"
	export KERN_ARCH="$myarch"
	cp "${FILESDIR}"/config-extract . || die
	chmod +x config-extract || die
	./config-extract ${myarch} ${opts} || die
	cp .config "${T}"/config || die
	make -s mrproper || die "make mrproper failed"
	#make -s include/linux/version.h || die "make include/linux/version.h failed"
}

src_compile() {
	use build || return
	install -d "${WORKDIR}"/out/{lib,boot}
	install -d "${T}"/{cache,twork}
	install -d "${WORKDIR}"/build
	DEFAULT_KERNEL_SOURCE="${S}" CMD_KERNEL_DIR="${S}" genkernel ${GKARGS} \
		--no-save-config \
		--kernel-config="${T}"/config \
		--fullname="genkernel-${KERN_ARCH}-${MODVER}" \
		--build-src="${S}" \
		--build-dst="${WORKDIR}"/build \
		--makeopts="${MAKEOPTS}" \
		--cachedir="${T}"/cache \
		--tempdir="${T}"/twork \
		--logfile="${WORKDIR}"/genkernel.log \
		--bootdir="${WORKDIR}"/out/boot \
		--module-prefix="${WORKDIR}"/out \
		kernel || die "genkernel kernel failed"
}

src_install() {
	# copy sources into place:
	dodir /usr/src
	cp -a "${S}" "${D}"/usr/src/linux-${P} || die
	cd "${D}"/usr/src/linux-${P}
	# prepare for real-world use and 3rd-party module building:
	make mrproper || die
	cp "${T}"/config .config || die
	cp -a "${T}"/debian debian || die
	yes "" | make oldconfig || die
	# if we didn't use genkernel, we're done. The kernel source tree is left in
	# an unconfigured state - you can't compile 3rd-party modules against it yet.
	use build || return
	make prepare || die
	make scripts || die
	# OK, now the source tree is configured to allow 3rd-party modules to be
	# built against it, since we want that to work since we have a binary kernel
	# built.
	cp -a "${WORKDIR}"/out/* "${D}"/ || die "couldn't copy output files into place"
	# module symlink fixup:
	rm -f "${D}"/lib/modules/*/source || die
	rm -f "${D}"/lib/modules/*/build || die
	cd "${D}"/lib/modules
	# module strip:
	find -iname *.ko -exec strip --strip-debug {} \;
	# back to the symlink fixup:
	local moddir="$(ls -d [234]*)"
	ln -s /usr/src/linux-${P} "${D}"/lib/modules/${moddir}/source || die
	ln -s /usr/src/linux-${P} "${D}"/lib/modules/${moddir}/build || die

	# Fixes FL-14
	cp "${WORKDIR}/build/System.map" "${D}/usr/src/linux-${P}/" || die
	cp "${WORKDIR}/build/Module.symvers" "${D}/usr/src/linux-${P}/" || die

}

_initramfs_genkernel() {
	genkernel ${GKARGS} \
		--fullname="genkernel-${KERN_ARCH}-${MODVER}" \
		--makeopts="${MAKEOPTS}" \
		--bootdir="${ROOT}"boot \
		--disklabel \
		--lvm \
		--luks \
		--mdadm \
		$(_rootfs_zfs && printf -- "--zfs") \
		--iscsi \
		--module-prefix="${ROOT}" \
		initramfs || die "genkernel initramfs generation failed"
}

_initramfs_dracut() {

	dracut ${ROOT}boot/initramfs-dracut-${KERN_ARCH}-${MODVER} $MODVER || die "dracut initramfs generation failed"
}

pkg_postinst() {
	if use symlink ; then
		if [[ -h "${ROOT}"usr/src/linux ]]; then
			rm "${ROOT}"usr/src/linux
			ln -sf linux-${P} "${ROOT}"usr/src/linux
		else
			ewarn "/usr/src/linux is not a symlink."
			ewarn "Please rename the directory before creating a link."
		fi
	elif use build ; then
		elog "Please make symlink from /usr/src/linux to linux-${P} before"
		elog "building any packages which depend on the kernel soure code!"
	fi

	if [ -e ${ROOT}lib/modules ]; then
		depmod -a $MODVER
	fi

	local rebuild
	rebuild="@module-rebuild"
	has_version "sys-fs/zfs[rootfs]" && rebuild+=" spl zfs zfs-kmod"
	elog "Please run \"emerge ${rebuild} --exclude ${PN}\" to rebuild packages compiled against the kernel source."
	_build_initramfs && log "Then run \"emerge --config ${PN}\" to generate the initramfs(s)."
}

pkg_config() {
	if [ -e ${ROOT}lib/modules ]; then
		depmod -a $MODVER

		if ! [[ -h "${ROOT}"usr/src/linux ]] || [[ "$(readlink -f "${ROOT}usr/src/linux")" != "${ROOT}usr/src/linux-$P" ]] ; then
			elog "${ROOT}usr/src/linux is not a symlink to ${ROOT}usr/src/linux-${P}."
			elog "Any modules installed from external packages may not match the kernel!"
			if _rootfs_zfs ; then ewarn "Cowardly refusing to build initramfs with likely-broken zfs support with root on zfs!" ; die ; fi
		fi
	fi
	use genkernel-initramfs && _initramfs_genkernel
	use dracut-initramfs && _initramfs_dracut
}

