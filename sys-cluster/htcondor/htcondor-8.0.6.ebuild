# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
CMAKE_MIN_VERSION=2.8.3
PYTHON_COMPAT=( python{2_6,2_7} )

inherit cmake-utils python-single-r1 user

DESCRIPTION="Workload management system for compute-intensive jobs"
HOMEPAGE="http://www.cs.wisc.edu/htcondor/"
SRC_URI="condor_src-${PV}-all-all.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="boinc cgroup contrib curl dmtcp doc kerberos libvirt management minimal postgres python soap ssl test X xml"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

CDEPEND=">=sys-libs/zlib-1.2.3
	>=dev-lang/perl-5.005
	>=dev-libs/libpcre-7.6
	>=dev-libs/boost-1.49.0[${PYTHON_USEDEP}]
	net-nds/openldap
	boinc? ( sci-misc/boinc )
	cgroup? ( >=dev-libs/libcgroup-0.37 )
	curl? ( >=net-misc/curl-7.31.0-p1[ssl?] )
	dmtcp? ( sys-apps/dmtcp )
	libvirt? ( >=app-emulation/libvirt-0.6.2 )
	kerberos? ( virtual/krb5 )
	X? ( x11-libs/libX11 )
	management? ( net-libs/qmf )
	postgres? ( >=dev-db/postgresql-base-8.2.4 )
	python? ( ${PYTHON_DEPS} )
	soap? ( >=net-libs/gsoap-2.7.11[ssl?] )
	ssl? ( >=dev-libs/openssl-0.9.8i )
	xml? ( >=dev-libs/libxml2-2.7.3 )"

DEPEND="${CDEPEND}
	test? ( dev-util/valgrind )"

RDEPEND="${CDEPEND}
	mail-client/mailx"

RESTRICT=fetch

S="${WORKDIR}/condor-${PV}"

pkg_setup() {
	enewgroup condor
	enewuser condor -1 "${ROOT}"bin/bash "${ROOT}var/lib/condor" condor
}

src_prepare() {
	epatch	"${FILESDIR}/condor_shadow_dlopen-${PV}.patch" \
		"${FILESDIR}/condor_config.generic.patch" \
		"${FILESDIR}/0001-Apply-the-user-s-condor_config-last-rather-than-firs.patch" \
		"${FILESDIR}/packaging_directories-${PV}.patch" \
		"${FILESDIR}/fix_sandbox_violations-${PV}.patch"
	cmake-utils_src_prepare
}

src_configure() {
	# All the hard coded -DWITH_X=OFF flags are for packages that aren't in portage
	# I also haven't included support for HAVE_VMWARE because I don't know what it requires
	local mycmakeargs="
		-DCONDOR_PACKAGE_BUILD=OFF
		-DCMAKE_INSTALL_PREFIX=${EPREFIX}/
		-DCONDOR_STRIP_PACKAGES=OFF
		-DWITH_BLAHP=OFF
		-DWITH_CAMPUSFACTORY=OFF
		-DWITH_CLUSTER_RA=OFF
		-DWITH_COREDUMPER=OFF
		-DWITH_CREAM=OFF
		-DWITH_GLOBUS=OFF
		-DWITH_LIBDELTACLOUD=OFF
		-DWITH_BLAHP=OFF
		-DWITH_QPID=OFF
		-DWITH_UNICOREGAHP=OFF
		-DWITH_VOMS=OFF
		-DWITH_WSO2=OFF
		$(cmake-utils_use_has boinc BACKFILL)
		$(cmake-utils_use_has boinc)
		$(cmake-utils_use_with cgroup LIBCGROUP)
		$(cmake-utils_use_want contrib)
		$(cmake-utils_use_with curl)
		$(cmake-utils_use_want doc MAN_PAGES)
		$(cmake-utils_use_with libvirt)
		$(cmake-utils_use_has X KBDD)
		$(cmake-utils_use_with kerberos KRB5)
		$(cmake-utils_use_with postgres POSTGRESQL)
		$(cmake-utils_use_with python PYTHON_BINDINGS)
		$(cmake-utils_use_with management)
		$(cmake-utils_use_with soap AVIARY)
		$(cmake-utils_use_with soap GSOAP)
		$(cmake-utils_use_with ssl OPENSSL)
		$(cmake-utils_use_build test TESTING)
		$(cmake-utils_use_with xml LIBXML2)"

	# Separating out the 'minimal' use flag
	#
	# PROPER tells condor to use system libraries rather than copies bundled in the source
	# PROPER is incompatible with the standard universe, because the same version of glibc
	# must be used on all the systems in the cluster - Condor will use the bundled glibc
	#
	# Possible TODO - patch the CondorConfigure.cmake to try building the standard universe
	# with the system glibc
	if use minimal
	then
		mycmakeargs+="
			-DPROPER=ON
			-DCLIPPED=ON
			-DWANT_FULL_DEPLOYMENT=OFF
			-DSTD_UNIVERSE=OFF"
	else
		mycmakeargs+="
			-DPROPER=OFF
			-DCLIPPED=OFF
			-DWANT_FULL_DEPLOYMENT=ON
			-DSTD_UNIVERSE=ON"
	fi
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	dodir /var/lib/condor
	dodir /var/log/condor
	dodir /var/run/condor
	dodir /var/lock/condor

	fperms 750 /var/lib/condor /var/log/condor
	fperms 755 /var/run/condor
	fperms 0775 /var/lock/condor
	fowners condor:condor /var/lib/condor /var/log/condor /var/run/condor
}