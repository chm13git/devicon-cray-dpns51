#!/bin/bash -l
unset CDPATH

module purge
module load gcc/gcc14-14.2.0.module

# ============================================================
# Available configurations
# ============================================================

compiler_list=("gcc14" "intel2020.4")
mpi_list=("openmpi" "mpiintel")
icon_version_list=("2025.04" "2026.04")

# ============================================================
# Retrieve parameters
#
# Usage:
#
#   ./set_env.sh <compiler>
#   ./set_env.sh <compiler> <mpi>
#   ./set_env.sh <compiler> <mpi> <icon_version>
#
# Examples:
#
#   ./set_env.sh gcc14
#   ./set_env.sh gcc14 openmpi
#   ./set_env.sh gcc14 openmpi 2025.04
# ============================================================

if [ $# -lt 1 ] || [ $# -gt 3 ]; then
    #echo "Usage:"
    #echo "  $0 <compiler> [mpi] [icon_version]"
    #echo
    #echo "Available compilers:"
    #echo "  ${compiler_list[*]}"
    #echo
    #echo "Available MPI:"
    #echo "  ${mpi_list[*]}"
    #echo
    #echo "Available ICON versions:"
    #echo "  ${icon_version_list[*]}"
    exit 11
fi

COMPILER="$1"

MPI="${2:-}"
VERSION="${3:-}"

# ============================================================
# Default configuration
# ============================================================

if [ -z "${MPI}" ]; then
    MPI="openmpi"
fi

if [ -z "${VERSION}" ]; then
    VERSION="2025.04"
fi

# ============================================================
# Validate compiler
# ============================================================

if [[ ! " ${compiler_list[*]} " =~ " ${COMPILER} " ]]; then
    #echo "Error: compiler '${COMPILER}' not found."
    #echo "Available compilers: ${compiler_list[*]}"
    exit 12
fi

# ============================================================
# Validate MPI
# ============================================================

if [[ ! " ${mpi_list[*]} " =~ " ${MPI} " ]]; then
    #echo "Error: MPI '${MPI}' not found."
    #echo "Available MPI: ${mpi_list[*]}"
    exit 13
fi

# ============================================================
# Validate ICON version
# ============================================================

if [[ ! " ${icon_version_list[*]} " =~ " ${VERSION} " ]]; then
    #echo "Error: ICON version '${VERSION}' not found."
    #echo "Available ICON versions: ${icon_version_list[*]}"
    exit 14
fi

# ============================================================
# Common directories
# ============================================================

export OPERACIONAL_DIR="/home/devicon/operacional"

export ICONMODEL_DIR="${OPERACIONAL_DIR}/binaries/iconmodel"
export ICONTOOLS_ROOT="${OPERACIONAL_DIR}/binaries/icontools"
export SCRIPTS_DIR="${OPERACIONAL_DIR}/scripts"
export DATES_DIR="${OPERACIONAL_DIR}/currentdates"

# ============================================================
# GCC 14.2.0
# ============================================================

export GCC_ROOT="/apps/compilers/gcc/gcc14-14.2.0"
export GCC_WRAPPERS="${GCC_ROOT}/wrappers"
export GCC_LIB="${GCC_ROOT}/usr/lib64"
export GCC_LIB_GCC="${GCC_ROOT}/usr/lib64/gcc/x86_64-suse-linux/14"

# ============================================================
# OpenMPI 5.0.10
# ============================================================

export OPENMPI_ROOT="/apps/libs/GCC14/openmpi-5.0.10"

# ============================================================
# Python 3.12.11
# ============================================================

export PYTHON_ROOT="/apps/python/3.12.11"

# ============================================================
# AOCL 5.2.0
# ============================================================

export AOCL_ROOT="/apps/amd/5.2.0/gcc"
export AOCL_LIB="${AOCL_ROOT}/lib_LP64"

# ============================================================
# Common environment
# ============================================================

export PATH="${GCC_WRAPPERS}:${GCC_ROOT}/usr/bin:${PYTHON_ROOT}/bin:${PATH}"

export LD_LIBRARY_PATH="${AOCL_LIB}:${GCC_LIB}:${GCC_LIB_GCC}:${PYTHON_ROOT}/lib:${LD_LIBRARY_PATH-}"

export LIBRARY_PATH="${GCC_LIB}:${GCC_LIB_GCC}:${AOCL_LIB}:${LIBRARY_PATH-}"

# ============================================================
# GCC 14.2.0 + OpenMPI 5.0.10
# ============================================================

if [ "${COMPILER}" = "gcc14" ]; then

    # --------------------------------------------------------
    # GCC
    # --------------------------------------------------------

    export PATH="${OPENMPI_ROOT}/bin:${PATH}"

    export LD_LIBRARY_PATH="${OPENMPI_ROOT}/lib:${OPENMPI_ROOT}/lib64:${LD_LIBRARY_PATH}"

    export LIBRARY_PATH="${OPENMPI_ROOT}/lib:${OPENMPI_ROOT}/lib64:${LIBRARY_PATH}"

    export PKG_CONFIG_PATH="${OPENMPI_ROOT}/lib/pkgconfig:${OPENMPI_ROOT}/lib64/pkgconfig:${PKG_CONFIG_PATH-}"

    export CMAKE_PREFIX_PATH="${OPENMPI_ROOT}:${CMAKE_PREFIX_PATH-}"

    export PYTHONPATH="${OPENMPI_ROOT}/lib/python3.12/site-packages:${OPENMPI_ROOT}/lib64/python3.12/site-packages:${PYTHONPATH-}"

    # --------------------------------------------------------
    # MPI
    # --------------------------------------------------------

    if [ "${MPI}" = "openmpi" ]; then

        export CC="mpicc"
        export CXX="mpicxx"
        export FC="mpif90"

        export MPI_LAUNCH="${OPENMPI_ROOT}/bin/mpiexec"

    else

        #echo "Error: MPI '${MPI}' is not configured for compiler '${COMPILER}'."
        #echo "Available configuration: gcc14 + openmpi"
        exit 15

    fi

    # --------------------------------------------------------
    # Compiler flags
    # --------------------------------------------------------

    export CFLAGS="-g1 -march=native -fPIC"
    export CXXFLAGS="-g1 -march=native -O2 -fPIC"

    export ICON_CFLAGS="-O3"
    export ICON_BUNDLED_CFLAGS="-O2"

    export CPPFLAGS="-I${OPENMPI_ROOT}/include \
-I${OPENMPI_ROOT}/include/libxml2"

    export FCFLAGS="-I${OPENMPI_ROOT}/include \
-fimplicit-none \
-fmax-identifier-length=63 \
-fall-intrinsics \
-fbacktrace \
-fbounds-check \
-fstack-protector-all \
-finit-real=nan \
-finit-integer=-2147483648 \
-finit-character=127 \
-Wall \
-Wcharacter-truncation \
-Wunderflow \
-Wunused-parameter \
-Wno-surprising \
-g1 \
-march=native \
-fPIC"

    # --------------------------------------------------------
    # ICON Fortran flags
    # --------------------------------------------------------

    export ICON_FCFLAGS="-O2 -std=f2008 -fmodule-private"

    export ICON_OCEAN_FCFLAGS="-O3 -fno-tree-loop-vectorize -std=f2008 -fmodule-private"
    export ICON_OCEAN_PATH="src/hamocc:src/ocean:src/sea_ice"

    export ICON_DACE_FCFLAGS="-O2 -std=f2018 -fmodule-private"
    export ICON_DACE_PATH="externals/dace"

    export ICON_ECRAD_FCFLAGS="-O2 -fmodule-private"
    export ICON_SCT_FCFLAGS="-O2 -fmodule-private"
    export ICON_HD_FCFLAGS="-O2"

    # --------------------------------------------------------
    # Linker
    # --------------------------------------------------------

    export LDFLAGS="-L${OPENMPI_ROOT}/lib \
-L${OPENMPI_ROOT}/lib64 \
-L${GCC_LIB} \
-L${GCC_LIB_GCC} \
-L${AOCL_LIB} \
-Wl,-rpath,${AOCL_LIB} \
-Wl,-rpath,${OPENMPI_ROOT}/lib \
-Wl,-rpath,${OPENMPI_ROOT}/lib64 \
-Wl,-rpath,${PYTHON_ROOT}/lib \
-Wl,-rpath,${GCC_LIB} \
-Wl,-rpath,${GCC_LIB_GCC} \
-Wl,--disable-new-dtags"

    # --------------------------------------------------------
    # Libraries
    # --------------------------------------------------------

    export LIBS="-Wl,--as-needed \
-leccodes_f90 \
-leccodes \
-lnetcdff \
-lnetcdf \
-lhdf5_hl_fortran \
-lhdf5_fortran \
-lhdf5_hl \
-lhdf5 \
-lsz \
-laec \
-lxml2 \
-lz \
-ldl \
-lm \
-lstdc++ \
-lflame \
-lblis \
-lcdi \
-pthread"

    # --------------------------------------------------------
    # ICON Tools
    # --------------------------------------------------------

    export ICONTOOLS_DIR="${ICONTOOLS_ROOT}/dwdicontools_2.6.0"

    export BINARY_ICONSUB="${ICONTOOLS_DIR}/iconsub"
    export BINARY_REMAP="${ICONTOOLS_DIR}/iconremap"

fi

# ============================================================
# Intel 2020.4
# ============================================================

if [ "${COMPILER}" = "intel2020.4" ]; then

    #echo "Intel 2020.4 configuration has not yet been defined."
    #echo "Please configure the Intel environment before using it."

    exit 16

fi

# ============================================================
# ICON version
# ============================================================

case "${VERSION}" in

    2025.04)

        export MODEL_DIR="${OPERACIONAL_DIR}/src/icon-model-2025.04"

        export ecradpath="${MODEL_DIR}/externals/ecrad/data"
        export ana_varnames_map_file="${MODEL_DIR}/run/ana_varnames_map_file.txt"
        export latbc_varnames_map_file="${MODEL_DIR}/run/dict.latbc"

        export BINARY_ICONMODEL="${ICONMODEL_DIR}/icon_2025.04_${COMPILER}_${MPI}_O3"

        ;;

    2026.04)

        export MODEL_DIR="${OPERACIONAL_DIR}/src/icon-model-2026.04"

        export ecradpath="${MODEL_DIR}/externals/ecrad/data"
        export ana_varnames_map_file="${MODEL_DIR}/run/ana_varnames_map_file.txt"
        export latbc_varnames_map_file="${MODEL_DIR}/run/dict.latbc"

        export BINARY_ICONMODEL="${ICONMODEL_DIR}/icon_2026.04_${COMPILER}_${MPI}_O3"

        ;;

    *)

        #echo "Error: ICON version '${VERSION}' not configured."
        exit 17

        ;;

esac
