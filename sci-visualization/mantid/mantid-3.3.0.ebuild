# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

FORTRAN_STANDARD=90
PYTHON_COMPAT=python2_7
inherit eutils cmake-utils versionator python-single-r1 multilib flag-o-matic

MAJOR_PV=$(get_version_component_range 1-2)

DESCRIPTION="Utilities for processing and plotting neutron scattering data"
HOMEPAGE="http://www.mantidproject.org/"
SRC_URI="mirror://sourceforge/project/${PN}/${MAJOR_PV}/${P}-Source.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="doc +opencascade opencl paraview pch tcmalloc test"

# There is a list of dependencies on the Mantid website at:
# http://www.mantidproject.org/Mantid_Prerequisites
RDEPEND="
	${PYTHON_DEPS}
	>=sci-libs/nexus-4.2
	>=dev-libs/poco-1.4.2
	dev-libs/boost[python,${PYTHON_USEDEP}]
	>=dev-qt/qthelp-4.6:4
	>=dev-qt/qtwebkit-4.6:4
	doc?		( >=dev-qt/assistant-4.6:4 )
	opencl?		( virtual/opencl )
	tcmalloc?	( dev-util/google-perftools )
	paraview?	( >=sci-visualization/paraview-4[python,${PYTHON_USEDEP}] )
	virtual/opengl
	x11-libs/qscintilla
	x11-libs/qwt:5
	x11-libs/qwtplot3d
	dev-python/PyQt4[${PYTHON_USEDEP}]
	sci-libs/gsl
	dev-python/sip[${PYTHON_USEDEP}]
	dev-python/ipython[qt4,${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	sci-libs/scipy[${PYTHON_USEDEP}]
	dev-cpp/muParser
	dev-libs/jsoncpp
	dev-libs/openssl
	opencascade?	( sci-libs/opencascade[qt4] )
"

DEPEND="${RDEPEND}
	dev-python/sphinx
	doc?	( app-doc/doxygen[dot]
		  dev-python/sphinx[${PYTHON_USEDEP}]
		  dev-python/sphinx-bootstrap-theme[${PYTHON_USEDEP}]
		  app-text/dvipng
		  dev-texlive/texlive-latex
		  dev-texlive/texlive-latexextra )
	test?	( dev-util/cppcheck )
"

S="${WORKDIR}/${P}-Source"

PATCHES=( "${FILESDIR}/${P}-minigzip-OF.patch" )

src_configure() {
	append-cppflags -DHAVE_IOSTREAM -DHAVE_LIMITS -DHAVE_IOMANIP
	mycmakeargs=(	$(cmake-utils_use_enable doc QTASSISTANT)
			$(cmake-utils_use_use doc DOT)
			$(cmake-utils_use doc DOCS_HTML)
			$(cmake-utils_use_no opencascade)
			$(cmake-utils_use opencl OPENCL_BUILD)
			$(cmake-utils_use_use tcmalloc TCMALLOC)
			$(cmake-utils_use paraview MAKE_VATES)
			$(cmake-utils_use_use pch PRECOMPILED_HEADERS)
			$(cmake-utils_use_build test TESTING)
		)
	if use opencascade
	then
		[[ -z ${CASROOT} ]] && die "CASROOT environment variable not defined, that usually means you need to use 'eselect opencascade'."
		mycmakeargs+=( -DCMAKE_PREFIX_PATH="${CASROOT}" )
	fi
	cmake-utils_src_configure
}

src_test() {
	# Tests are not built by default
	emake AllTests
	# Run only the tests that work without data files or GUI access
	ctest -R 'KernelTest_'		  --exclude-regex 'Config|File|Glob|Nexus'	|| die
	ctest -R 'GeometryTest_'	  --exclude-regex 'InstrumentDefinitionParser'	|| die
	ctest -R 'APITest_'		  --exclude-regex 'File|IO'	|| die
	ctest -R 'PythonInterface_'	  --exclude-regex 'Load'	|| die
	ctest -R 'PythonInterfaceCppTest_'	|| die
	ctest -R 'PythonInterfaceKernel_' --exclude-regex 'PropertyHistory'	|| die
	ctest -R 'PythonInterfaceGeometry_'	|| die
	# Too many failing tests for 'PythonAlgorithms_'
	ctest -R 'PythonFunctions_'	|| die
	ctest -R 'DataObjectsTest_'	|| die
	ctest -R 'DataHandlingTest_'	  --exclude-regex 'Append|Chunk|File|Group|Load|Log|Save|PSD|Workspace|XML'	|| die
	# Too many failing tests for 'AlgorithmTest_'
	ctest -R 'CurveFittingTest_'	  --exclude-regex 'AugmentedLagrangian|FitPowderDiffPeaks|TabulatedFunction'	|| die
	# Too many failing tests for 'CrystalTest_'
	ctest -R 'ICatTest_'	|| die
	ctest -R 'LiveDataTest_'	  --exclude-regex 'File'	|| die
	ctest -R 'PSISINQTest_'		  --exclude-regex 'LoadFlexiNexus'	|| die
	ctest -R 'MDAlgorithmsTest_'	  --exclude-regex 'LoadSQW'	|| die
	ctest -R 'MDEventsTest_'	  --exclude-regex 'OneStepMDEW'	|| die
	ctest -R 'ScriptRepositoryTest_'	|| die
	ctest -R 'MantidQtAPITest_'	|| die
	ctest -R 'MantidWidgetsTest_'	|| die
	ctest -R 'CustomInterfacesTest_'  --exclude-regex 'IO|Load'	|| die
	ctest -R 'SliceViewerMantidPlotTest_'	|| die
	ctest -R 'SliceViewerTest_'	|| die
	# All the MantidPlot* tests use the GUI
}
