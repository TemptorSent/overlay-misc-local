# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )
#inherit eutils linux-info multilib-build unpacker
inherit multilib-build unpacker

DESCRIPTION="New generation AMD closed-source drivers for Southern Islands (HD7730 Series) and newer chipsets"
# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )
#inherit eutils linux-info multilib-build unpacker
inherit multilib-build unpacker

DESCRIPTION="New generation AMD closed-source drivers for Southern Islands (HD7730 Series) and newer chipsets"
HOMEPAGE="http://support.amd.com/en-us/kb-articles/Pages/AMDGPU-PRO-Driver-for-Linux-Release-Notes.aspx"
PKG_VER=17.50
PKG_REV=511655
PKG_VER_STRING=${PKG_VER}-${PKG_REV}
SRC_URI="https://www2.ati.com/drivers/linux/ubuntu/amdgpu-pro-${PKG_VER_STRING}.tar.xz"

RESTRICT="fetch strip"

# The binary blobs include binaries for other open sourced packages, we don't want to include those parts, if they are
# selected, they should come from portage.
IUSE="+gles2 +opencl +opengl +vdpau +vulkan"

LICENSE="AMD GPL-2 QPL-1.0"
KEYWORDS="~amd64"
SLOT="1"

RDEPEND="
	>=app-eselect/eselect-opengl-1.0.7
	app-eselect/eselect-opencl
	dev-libs/openssl[${MULTILIB_USEDEP}]
	dev-util/cunit
	>=media-libs/gst-plugins-base-1.6.0[${MULTILIB_USEDEP}]
	>=media-libs/gstreamer-1.6.0[${MULTILIB_USEDEP}]
	media-libs/libomxil-bellagio
	!vulkan? ( >=media-libs/mesa-17.2.0[openmax] )
	vulkan? ( >=media-libs/mesa-17.2.0[openmax,-vulkan] media-libs/vulkan-loader )
	opencl? ( >=sys-devel/gcc-5.2.0 )
	>=sys-devel/lld-5.0.0
	>=sys-devel/llvm-5.0.0
	<=sys-kernel/gentoo-sources-4.11.0
	>=sys-libs/ncurses-5.0.0:5[${MULTILIB_USEDEP},tinfo]
	=x11-base/xorg-drivers-1.19
	=x11-base/xorg-server-1.19*[glamor]
	>=x11-libs/libdrm-2.4.82
	x11-libs/libX11[${MULTILIB_USEDEP}]
	x11-libs/libXext[${MULTILIB_USEDEP}]
	x11-libs/libXinerama[${MULTILIB_USEDEP}]
	x11-libs/libXrandr[${MULTILIB_USEDEP}]
	x11-libs/libXrender[${MULTILIB_USEDEP}]
	x11-proto/inputproto
	x11-proto/xf86miscproto
	x11-proto/xf86vidmodeproto
	x11-proto/xineramaproto
"
DEPEND="
	>=sys-kernel/linux-firmware-20161205
"

S="${WORKDIR}"

pkg_nofetch() {
	einfo "Please download"
	einfo "  - ${PN}_${PV}.tar.xz"
	einfo "from ${HOMEPAGE} and place them in ${DISTDIR}"
}

unpack_deb() {
	echo ">>> Unpacking ${1##*/} to ${PWD}"
	unpack $1
	unpacker ./data.tar*
	rm -f debian-binary {control,data}.tar*
}

src_unpack() {
	default
	
	unpack_deb "amdgpu-pro-${PKG_VER_STRING}/amdgpu-pro-core_${PKG_VER_STRING}_all.deb"
	unpack_deb "amdgpu-pro-${PKG_VER_STRING}/amdgpu-pro_${PKG_VER_STRING}_amd64.deb"
	use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/amdgpu-pro_${PKG_VER_STRING}_i386.deb"
	unpack_deb "amdgpu-pro-${PKG_VER_STRING}/amdgpu-pro-lib32_${PKG_VER_STRING}_amd64.deb"
	unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgl1-amdgpu-pro-appprofiles_${PKG_VER_STRING}_all.deb"
	unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libdrm-amdgpu-utils_2.4.82-${PKG_REV}_amd64.deb"
	
	if use opencl ; then
		# Install clinfo
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/clinfo-amdgpu-pro_${PKG_VER_STRING}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/clinfo-amdgpu-pro_${PKG_VER_STRING}_amd64.deb"
		
		# Install OpenCL components
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/opencl-amdgpu-pro_${PKG_VER_STRING}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/opencl-amdgpu-pro_${PKG_VER_STRING}_i386.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/opencl-amdgpu-pro-icd_${PKG_VER_STRING}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/opencl-amdgpu-pro-icd_${PKG_VER_STRING}_i386.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libopencl1-amdgpu-pro_${PKG_VER_STRING}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libopencl1-amdgpu-pro_${PKG_VER_STRING}_i386.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/hsa-ext-amdgpu-pro-finalize_1.1.6-${PKG_REV}_amd64.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/hsa-ext-amdgpu-pro-image_1.1.6-${PKG_REV}_amd64.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/hsa-runtime-tools-amdgpu-pro_1.1.6-${PKG_REV}_amd64.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/hsa-runtime-tools-amdgpu-pro-dev_1.1.6-${PKG_REV}_amd64.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/rocm-amdgpu-pro_${PKG_VER_STRING}_amd64.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/rocm-amdgpu-pro-icd_${PKG_VER_STRING}_amd64.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/rocm-amdgpu-pro-opencl_${PKG_VER_STRING}_amd64.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/rocm-amdgpu-pro-opencl-dev_${PKG_VER_STRING}_amd64.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/rocr-amdgpu-pro_1.1.6-${PKG_REV}_amd64.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/rocr-amdgpu-pro-dev_1.1.6-${PKG_REV}_amd64.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/roct-amdgpu-pro_1.0.7-${PKG_REV}_amd64.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/roct-amdgpu-pro-dev_1.0.7-${PKG_REV}_amd64.deb"
		
	fi
	
	if use vulkan ; then
		# Install Vulkan driver
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/vulkan-amdgpu-pro_${PKG_VER_STRING}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/vulkan-amdgpu-pro_${PKG_VER_STRING}_i386.deb"
	fi
	
	if use opengl ; then
		# Install OpenGL
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libdrm-amdgpu-amdgpu1_2.4.82-${PKG_REV}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libdrm-amdgpu-amdgpu1_2.4.82-${PKG_REV}_i386.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libdrm-amdgpu-radeon1_2.4.82-${PKG_REV}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libdrm-amdgpu-radeon1_2.4.82-${PKG_REV}_i386.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgl1-amdgpu-pro-glx_${PKG_VER_STRING}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgl1-amdgpu-pro-glx_${PKG_VER_STRING}_i386.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgl1-amdgpu-pro-ext_${PKG_VER_STRING}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgl1-amdgpu-pro-ext_${PKG_VER_STRING}_i386.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgl1-amdgpu-pro-dri_${PKG_VER_STRING}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgl1-amdgpu-pro-dri_${PKG_VER_STRING}_i386.deb"
		
		# Install GBM
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgbm1-amdgpu-pro-base_${PKG_VER_STRING}_all.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgbm1-amdgpu-pro_${PKG_VER_STRING}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgbm1-amdgpu-pro_${PKG_VER_STRING}_i386.deb"
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgbm1-amdgpu-pro-dev_${PKG_VER_STRING}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgbm1-amdgpu-pro-dev_${PKG_VER_STRING}_i386.deb"
	fi
	
	if use gles2 ; then
		# Install GLES2
		unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgles2-amdgpu-pro_${PKG_VER_STRING}_amd64.deb"
		use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libgles2-amdgpu-pro_${PKG_VER_STRING}_i386.deb"
	fi
	
	# Install EGL libs
	unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libegl1-amdgpu-pro_${PKG_VER_STRING}_amd64.deb"
	use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/libegl1-amdgpu-pro_${PKG_VER_STRING}_i386.deb"

	# Install xorg drivers
	unpack_deb "amdgpu-pro-${PKG_VER_STRING}/xserver-xorg-amdgpu-video-amdgpu_1.4.0-${PKG_REV}_amd64.deb"
	use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/xserver-xorg-amdgpu-video-amdgpu_1.4.0-${PKG_REV}_i386.deb"
	
	# Install gstreamer OpenMAX plugin
	unpack_deb "amdgpu-pro-${PKG_VER_STRING}/gst-omx-amdgpu_1.0.0.1-${PKG_REV}_amd64.deb"
	use abi_x86_32 && unpack_deb "amdgpu-pro-${PKG_VER_STRING}/gst-omx-amdgpu_1.0.0.1-${PKG_REV}_i386.deb"
}

src_prepare() {
	cat << EOF > "${T}/91-drm_pro-modeset.rules" || die
KERNEL=="controlD[0-9]*", SUBSYSTEM=="drm", MODE="0600"
EOF

	cat << EOF > "${T}/01-amdgpu-pro.conf" || die
"${EPREFIX}"/usr/$(get_libdir)/gbm
"${EPREFIX}"/usr/lib32/gbm
EOF

	cat << EOF > "${T}/10-device.conf" || die
Section "Device"
	Identifier  "My graphics card"
	Driver      "amdgpu"
	BusID       "PCI:1:0:0"
	Option      "AccelMethod" "glamor"
	Option      "DRI" "3"
	Option		"TearFree" "on"
EndSection
EOF

	cat << EOF > "${T}/10-screen.conf" || die
Section "Screen"
		Identifier      "Screen0"
		DefaultDepth    24
		SubSection      "Display"
				Depth   24
		EndSubSection
EndSection
EOF

	cat << EOF > "${T}/10-monitor.conf" || die
Section "Monitor"
	Identifier   "My monitor"
	VendorName   "BrandName"
	ModelName    "ModelName"
	Option       "DPMS"   "true"
EndSection
EOF

	if use vulkan ; then
		cat << EOF > "${T}/amd_icd64.json" || die
{
   "file_format_version": "1.0.0",
	   "ICD": {
		   "library_path": ""${EPREFIX}"/usr/$(get_libdir)/vulkan/vendors/amdgpu-pro/amdvlk64.so",
		   "abi_versions": "0.9.0"
	   }
}
EOF

		if use abi_x86_32 ; then
			cat << EOF > "${T}/amd_icd32.json" || die
{
   "file_format_version": "1.0.0",
	   "ICD": {
		   "library_path": ""${EPREFIX}"/usr/lib32/vulkan/vendors/amdgpu-pro/amdvlk32.so",
		   "abi_versions": "0.9.0"
	   }
}
EOF
		fi
	fi

	eapply_user
}

src_install() {
	insinto "${EPREFIX}"/lib/udev/rules.d/
	doins "${T}/91-drm_pro-modeset.rules"
	insinto "${EPREFIX}"/etc/ld.so.conf.d
	doins "${T}/01-amdgpu-pro.conf"
	insinto "${EPREFIX}"/etc/X11/xorg.conf.d
	doins "${T}/10-screen.conf"
	doins "${T}/10-monitor.conf"
	doins "${T}/10-device.conf"
	insinto "${EPREFIX}"/etc/amd/
	doins etc/amd/amdapfxx.blb
	
	into "${EPREFIX%/}"/usr
	dobin opt/amdgpu/bin/amdgpu_test
	dobin opt/amdgpu/bin/kms-steal-crtc
	dobin opt/amdgpu/bin/kmstest
	dobin opt/amdgpu/bin/kms-universal-planes
	dobin opt/amdgpu/bin/modeprint
	dobin opt/amdgpu/bin/modetest
	dobin opt/amdgpu/bin/proptest
	dobin opt/amdgpu/bin/vbltest
	
	if use opencl ; then
		# Install clinfo
		into "${EPREFIX}"/usr
		dobin opt/amdgpu-pro/bin/clinfo
		
		# Install OpenCL components
		insinto /etc/OpenCL/vendors
		doins etc/OpenCL/vendors/amdocl64.icd
		doins etc/OpenCL/vendors/amdocl-rocr64.icd
		
		exeinto "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libamdocl*
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libOpenCL.so.1
		dosym libOpenCL.so.1 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libOpenCL.so
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libhsa-ext-finalize64.so.1.0.0
		dosym libhsa-ext-finalize64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-ext-finalize64.so.1.0
		dosym libhsa-ext-finalize64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-ext-finalize64.so.1
		dosym libhsa-ext-finalize64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-ext-finalize64.so
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libhsa-ext-image64.so.1.0.0
		dosym libhsa-ext-image64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-ext-image64.so.1.0
		dosym libhsa-ext-image64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-ext-image64.so.1
		dosym libhsa-ext-image64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-ext-image64.so
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libhsa-runtime-tools64.so.1.0.0
		dosym libhsa-runtime-tools64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-runtime-tools64.so.1.0
		dosym libhsa-runtime-tools64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-runtime-tools64.so.1
		dosym libhsa-runtime-tools64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-runtime-tools64.so
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libamdocl-rocr64.so
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libcltrace.so
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libhsa-runtime64.so.1.0.0
		dosym libhsa-runtime64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-runtime64.so.1.0
		dosym libhsa-runtime64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-runtime64.so.1
		dosym libhsa-runtime64.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsa-runtime64.so
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libhsakmt.so.1.0.0
		dosym libhsakmt.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsakmt.so.1.0
		dosym libhsakmt.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsakmt.so.1
		dosym libhsakmt.so.1.0.0 "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/libhsakmt.so
		
		insinto "${EPREFIX}"/usr/lib64/OpenCL/vendors/amdgpu-pro/include/CL
		doins opt/amdgpu-pro/include/CL/*
		
		insinto "${EPREFIX}"/usr/include/hsa
		doins opt/amdgpu-pro/include/hsa/*
		
		insinto "${EPREFIX}"/usr/include/libhsakmt
		doins opt/amdgpu-pro/include/libhsakmt/*
		
		insinto "${EPREFIX}"/usr/include/libhsakmt/linux
		doins opt/amdgpu-pro/include/libhsakmt/linux/*

		insinto "${EPREFIX}"/usr/lib64/pkgconfig
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/pkgconfig/roc*
		
		if use abi_x86_32 ; then
			# Install 32 bit OpenCL ICD
			insinto /etc/OpenCL/vendors
			doins etc/OpenCL/vendors/amdocl32.icd
			exeinto "${EPREFIX}"/usr/lib32/OpenCL/vendors/amdgpu-pro
			doexe opt/amdgpu-pro/lib/i386-linux-gnu/libamdocl*
			
			# Install 32 bit OpenCL library
			doexe opt/amdgpu-pro/lib/i386-linux-gnu/libOpenCL.so.1
			dosym libOpenCL.so.1 "${EPREFIX}"/usr/lib32/OpenCL/vendors/amdgpu-pro/libOpenCL.so

			# Install pkgconfig files for 32 bit OpenCL
			insinto "${EPREFIX}"/usr/lib32/pkgconfig
			doexe opt/amdgpu-pro/lib/i386-linux-gnu/pkgconfig/roc*
		fi
	fi
	
	if use vulkan ; then
		# Install Vulkan driver
		insinto /etc/vulkan/icd.d
		doins "${T}/amd_icd64.json"
		exeinto "${EPREFIX}"/usr/lib64/vulkan/vendors/amdgpu-pro
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/amdvlk64.so

		if use abi_x86_32 ; then
			# Install Vulkan driver
			insinto /etc/vulkan/icd.d
			doins "${T}/amd_icd32.json"
			exeinto "${EPREFIX}"/usr/lib32/vulkan/vendors/amdgpu-pro
			doexe opt/amdgpu-pro/lib/i386-linux-gnu/amdvlk32.so
		fi
	fi
	
	if use opengl ; then
		# Install OpenGL
		exeinto "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/lib
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libGL.so.1.2
		dosym libGL.so.1.2 "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/lib/libGL.so.1
		dosym libGL.so.1.2 "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/lib/libGL.so
		exeinto "${EPREFIX}"/usr/lib64/opengl/amdgpu/lib
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0
		dosym libdrm_amdgpu.so.1.0.0 "${EPREFIX}"/usr/lib64/opengl/amdgpu/lib/libdrm_amdgpu.so.1
		dosym libdrm_amdgpu.so.1.0.0 "${EPREFIX}"/usr/lib64/opengl/amdgpu/lib/libdrm_amdgpu.so
		exeinto "${EPREFIX}"/usr/lib64/opengl/radeon/lib
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1
		dosym libdrm_radeon.so.1.0.1 "${EPREFIX}"/usr/lib64/opengl/radeon/lib/libdrm_radeon.so.1
		dosym libdrm_radeon.so.1.0.1 "${EPREFIX}"/usr/lib64/opengl/radeon/lib/libdrm_radeon.so
		insinto /etc/amd/
		doins etc/amd/amdrc
		exeinto "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/extensions
		doexe opt/amdgpu-pro/lib/xorg/modules/extensions/libglx.so
		exeinto "${EPREFIX}"/usr/lib64/opengl/amdgpu/dri
		doexe usr/lib/x86_64-linux-gnu/dri/amdgpu_dri.so
		dosym ../opengl/amdgpu/dri/amdgpu_dri.so "${EPREFIX}"/usr/lib64/dri/amdgpu_dri.so
		dosym ../../opengl/amdgpu/dri/amdgpu_dri.so "${EPREFIX}"/usr/lib64/x86_64-linux-gnu/dri/amdgpu_dri.so
		
		if use abi_x86_32 ; then
			# Install 32 bit OpenGL
			exeinto "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib
			doexe opt/amdgpu-pro/lib/i386-linux-gnu/libGL.so.1.2
			dosym libGL.so.1.2 "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib/libGL.so.1
			dosym libGL.so.1.2 "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib/libGL.so
			exeinto "${EPREFIX}"/usr/lib32/opengl/amdgpu/lib
			doexe opt/amdgpu/lib/i386-linux-gnu/libdrm_amdgpu.so.1.0.0
			dosym libdrm_amdgpu.so.1.0.0 "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib/libdrm_amdgpu.so.1
			dosym libdrm_amdgpu.so.1.0.0 "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib/libdrm_amdgpu.so
			exeinto "${EPREFIX}"/usr/lib32/opengl/radeon/lib
			doexe opt/amdgpu/lib/i386-linux-gnu/libdrm_radeon.so.1.0.1
			dosym libdrm_radeon.so.1.0.1 "${EPREFIX}"/usr/lib32/opengl/radeon/lib/libdrm_radeon.so.1
			dosym libdrm_radeon.so.1.0.1 "${EPREFIX}"/usr/lib32/opengl/radeon/lib/libdrm_radeon.so
			exeinto "${EPREFIX}"/usr/lib32/opengl/amdgpu/dri
			doexe usr/lib/i386-linux-gnu/dri/amdgpu_dri.so
			dosym ../opengl/amdgpu/dri/amdgpu_dri.so "${EPREFIX}"/usr/lib32/dri/amdgpu_dri.so
			dosym ../../opengl/amdgpu/dri/amdgpu_dri.so "${EPREFIX}"/usr/lib64/i386-linux-gnu/dri/amdgpu_dri.so
		fi	
		
		# Install GBM
		exeinto "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/lib
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libgbm.so.1.0.0
		dosym libgbm.so.1.0.0 "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/lib/libgbm.so.1
		dosym libgbm.so.1.0.0 "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/lib/libgbm.so
		exeinto "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/gbm
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/gbm/gbm_amdgpu.so
		dosym gbm_amdgpu.so "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/gbm/libdummy.so
		dosym opengl/amdgpu-pro/gbm "${EPREFIX}"/usr/lib64/gbm
		insinto /etc/gbm/
		doins etc/gbm/gbm.conf
		insinto "${EPREFIX}"/usr/lib64/pkgconfig
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/pkgconfig/gbm.pc

		if use abi_x86_32 ; then
			# Install GBM
			exeinto "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib
			doexe opt/amdgpu-pro/lib/i386-linux-gnu/libgbm.so.1.0.0
			dosym libgbm.so.1.0.0 "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib/libgbm.so.1
			dosym libgbm.so.1.0.0 "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib/libgbm.so
			exeinto "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/gbm
			doexe opt/amdgpu-pro/lib/i386-linux-gnu/gbm/gbm_amdgpu.so
			dosym gbm_amdgpu.so "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/gbm/libdummy.so
			dosym opengl/amdgpu-pro/gbm "${EPREFIX}"/usr/lib32/gbm
			insinto "${EPREFIX}"/usr/lib32/pkgconfig
			doexe opt/amdgpu-pro/lib/i386-linux-gnu/pkgconfig/gbm.pc
		fi
	fi
	
	if use gles2 ; then
		# Install GLES2
		exeinto "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/lib
		doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libGLESv2.so.2
		dosym libGLESv2.so.2 "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/lib/libGLESv2.so

		if use abi_x86_32 ; then
			exeinto "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib
			doexe opt/amdgpu-pro/lib/i386-linux-gnu/libGLESv2.so.2
			dosym libGLESv2.so.2 "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib/libGLESv2.so
		fi
	fi
	
	# Install EGL libs
	exeinto "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/lib
	doexe opt/amdgpu-pro/lib/x86_64-linux-gnu/libEGL.so.1
	dosym libEGL.so.1 "${EPREFIX}"/usr/lib64/opengl/amdgpu-pro/lib/libEGL.so

	if use abi_x86_32 ; then
		exeinto "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib
		doexe opt/amdgpu-pro/lib/i386-linux-gnu/libEGL.so.1
		dosym libEGL.so.1 "${EPREFIX}"/usr/lib32/opengl/amdgpu-pro/lib/libEGL.so
	fi
	
	# Install xorg drivers
	exeinto "${EPREFIX}"/usr/lib64/opengl/amdgpu/modules/drivers
	doexe opt/amdgpu/lib/xorg/modules/drivers/amdgpu_drv.so
	
	# Install gstreamer OpenMAX plugin
	insinto /etc/xdg/
	doins etc/xdg/gstomx.conf
	exeinto "${EPREFIX}"/usr/lib64/gstreamer-1.0/
	doexe opt/amdgpu/lib/x86_64-linux-gnu/gstreamer-1.0/libgstomx.so
	if use abi_x86_32 ; then
		exeinto "${EPREFIX}"/usr/lib32/gstreamer-1.0/
		doexe opt/amdgpu/lib/i386-linux-gnu/gstreamer-1.0/libgstomx.so
	fi
	
	# Link for hardcoded path
	dosym "${EPREFIX}"/usr/share/libdrm/amdgpu.ids "${EPREFIX}"/opt/amdgpu-pro/share/libdrm/amdgpu.ids
}

pkg_prerm() {
	einfo "pkg_prerm"
	if use opengl ; then
		"${EROOT}"/usr/bin/eselect opengl set --use-old xorg-x11
	fi

	if use opencl ; then
		"${EROOT}"/usr/bin/eselect opencl set --use-old mesa
	fi
}

pkg_postinst() {
	einfo "pkg_postinst"
	if use opengl ; then
		"${EROOT}"/usr/bin/eselect opengl set --use-old amdgpu-pro
	fi

	if use opencl ; then
		"${EROOT}"/usr/bin/eselect opencl set --use-old amdgpu-pro
	fi
}
