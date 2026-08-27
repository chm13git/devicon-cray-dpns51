#!/bin/bash -l

compiler_list=("intelOneAPI2021" "intel2019" "gcc12.2" "gcc12.3" "intel2020.4")
mpi_list=("mpt2.24" "mpich" "openmpi" "mpiintel")
icon_version_list=("2024.10" "2025.04")

# Step 1 - Retrieving parameters
if [ $# -ne 1 ] && [ $# -ne 2 ] && [ $# -ne 3 ];then
	echo "Enter the compiler (${compiler_list[*]}) and/or (${mpi_list[*]})!"
        echo "$0 ${compiler_list[0]}"
	echo or
	echo "$0 ${compiler_list[0]} ${mpi_list[0]}"
	echo or
	echo "$0 ${compiler_list[0]} ${mpi_list[0]} ${icon_version_list[1]}"
        exit 11
fi

COMPILER=$1
MPI=$2
VERSION=$3

if [ -z $MPI ] && [ -z $VERSION ];then # entra aqui se MPI e VERSION forem vazios
	MPI="mpiintel"
	VERSION="2024.10"
elif [ -z $VERSION ];then # entra aqui se MPI for vazio
	VERSION="2024.10"
else
	sleep 1
fi

#echo "Usando MPI: $MPI"
#echo "Usando versão: $VERSION"

# Setting common dirs and bins
export ICONMODEL_DIR='/home/opicon/operacional/binaries/iconmodel'
export anaconda_dir='/home/opicon/anaconda3/bin'
export ICONTOOLS_ROOT='/home/opicon/operacional/binaries/icontools'
export SCRIPTS_DIR='/home/opicon/operacional/scripts'
export CDO='/usr/local/bin/cdo'
export DATES_DIR='/home/opicon/operacional/currentdates'
export BKP_DIR='/data2/backup/backup_icon'

if [ $COMPILER == "intel2019" ]; then
	module unload /usr/share/modules/modulefiles/gcc/gcc-12.2.0
	module load /usr/share/modules/modulefiles/intel/intel_2019.5-compilers
	install_dir='/home/devicon/instalacao-intel2019.5'

	export ECCODES_DEFINITION_PATH=${install_dir}/libraries/definitions.edzw-2.21.0-1:${install_dir}/libraries/share/eccodes/definitions
	#export GRIB_DEFINITION_PATH=/home/devicon/instalacao-intel2019.5/libraries/definitions.edzw-2.21.0-1:/home/devicon/instalacao-intel2019.5/libraries/share/eccodes/definitions

	export LD_LIBRARY_PATH=${install_dir}/libraries/lib:/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/compiler/lib/intel64_lin:$LD_LIBRARY_PATH
	export PATH=${install_dir}/libraries/bin:${anaconda_dir}:$PATH:.

	export ICONTOOLS_DIR='/home/opicon/operacional/binaries/icontools/dwdicontools_2.4.12'
	export BINARY_ICONSUB="$ICONTOOLS_DIR/iconsub"
	export BINARY_REMAP="$ICONTOOLS_DIR/iconremap"

	export MPIBIN_ICONTOOLS='/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/mpi/intel64/bin/mpirun'

	export MODEL_DIR="${install_dir}/binaries/icon-2.6.6"
	export MPIBIN_ICONMODEL="${install_dir}/libraries/bin/mpiexec"
	export BINARY_ICONMODEL="$ICONMODEL_DIR/icon_2.6.6_intel_ecrad_O3" # choose your model version here

elif [ $COMPILER == "intelOneAPI2021" ]; then
module unload /usr/share/modules/modulefiles/gcc/gcc-12.2.0
module unload intel/intel_2019.5-compilers
        export ICONTOOLS_DIR='/home/opicon/operacional/binaries/icontools/dwd_icon_tools-2.6.0'
        export BINARY_ICONSUB="$ICONTOOLS_DIR/iconsub"
        export BINARY_REMAP="$ICONTOOLS_DIR/iconremap"
        export MPIBIN_ICONTOOLS='/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/mpi/intel64/bin/mpirun'
        export MPIBIN_ICONMODEL="${install_dir}/libraries/bin/mpiexec"
        export BINARY_ICONMODEL="$ICONMODEL_DIR/icon-model-release-2024.10-public" # choose your model version here

elif [ $COMPILER == "gcc12.2" ]; then
	module unload /usr/share/modules/modulefiles/intel/intel_2019.5-compilers
	module load /usr/share/modules/modulefiles/gcc/gcc-12.2.0
	install_dir='/home/devicon/instalacao-gcc-12.2.0'

	if [ $MPI == "openmpi" ];then # entra aqui se digitar um segundo arg 'openmpi'
		export ecradpath="${install_dir}/binaries/icon-model-release-2024.07-public/externals/ecrad/data"
		export ana_varnames_map_file="${install_dir}/binaries/icon-model-release-2024.07-public/run/ana_varnames_map_file.txt"
		export latbc_varnames_map_file="${install_dir}/binaries/icon-model-release-2024.07-public/run/dict.latbc"

		export ECCODES_DEFINITION_PATH="${install_dir}/libraries/definitions.edzw-2.32.0-1:${install_dir}/libraries/eccodes-2.32.0-Source/share/eccodes/definitions"

		#export LD_LIBRARY_PATH=/opt/gcc-12.2.0/lib64:$install_dir/libraries_mpich/lib64:$LD_LIBRARY_PATH
		export LIBS_PATH="/opt/gcc-12.2.0/lib64:$install_dir/libraries/zlib-1.3.1/lib:$install_dir/libraries/szip-2.1.1/lib64:$install_dir/libraries/curl-8.9.1/lib64:$install_dir/libraries/openmpi-4.0.2/lib64:$install_dir/libraries/hdf5-1.14.4-3/lib64:$install_dir/libraries/netcdf-c-4.9.2/lib64:$install_dir/libraries/netcdf-fortran-4.6.1/lib64:$install_dir/libraries/libaec-v1.1.3/lib64:$install_dir/libraries/eccodes-2.32.0-Source/lib64:$install_dir/libraries/libxml2-2.9.14/lib64:$install_dir/libraries/OpenBLAS-0.3.28/lib"
		export LD_LIBRARY_PATH=${LIBS_PATH}:$LD_LIBRARY_PATH
		export PATH="$install_dir/libraries/curl-8.9.1/bin:$install_dir/libraries/openmpi-4.0.2/bin:$install_dir/libraries/hdf5-1.14.4-3/bin:$install_dir/libraries/netcdf-c-4.9.2/bin:$install_dir/libraries/eccodes-2.32.0-Source/bin:$PATH:."

		export ICONTOOLS_DIR='/home/opicon/operacional/binaries/icontools/dwdicontools_2.6.0'
		export BINARY_ICONSUB="$ICONTOOLS_DIR/iconsub"
		export BINARY_REMAP="$ICONTOOLS_DIR/iconremap"

		export MPIBIN_ICONTOOLS="$install_dir/libraries/openmpi-4.0.2/bin/mpiexec"
	
		export MPIBIN_ICONMODEL="$install_dir/libraries/openmpi-4.0.2/bin/mpiexec"
		export BINARY_ICONMODEL="$ICONMODEL_DIR/icon_2024.07_gcc_openmpi_O3" # choose your model version here
	else # entra aqui se não digitar um segundo arg, ou seja, se $MPI for vazia
		export ecradpath="${install_dir}/binaries_mpich/icon-model-release-2024.07-public/externals/ecrad/data"
		export ana_varnames_map_file="${install_dir}/binaries_mpich/icon-model-release-2024.07-public/run/ana_varnames_map_file.txt"
		export latbc_varnames_map_file="${install_dir}/binaries_mpich/icon-model-release-2024.07-public/run/dict.latbc"

		export ECCODES_DEFINITION_PATH="${install_dir}/libraries_mpich/definitions.edzw-2.32.0-1:${install_dir}/libraries_mpich/eccodes-2.32.0-Source/share/eccodes/definitions"

		#export LD_LIBRARY_PATH=/opt/gcc-12.2.0/lib64:$install_dir/libraries_mpich/lib64:$LD_LIBRARY_PATH
		export LIBS_PATH="/opt/gcc-12.2.0/lib64:$install_dir/libraries_mpich/zlib-1.3.1/lib:$install_dir/libraries_mpich/szip-2.1.1/lib64:$install_dir/libraries_mpich/curl-8.9.1/lib64:$install_dir/libraries_mpich/mpich-4.2.2/lib64:$install_dir/libraries_mpich/hdf5-1.14.4-3/lib64:$install_dir/libraries_mpich/netcdf-c-4.9.2/lib64:$install_dir/libraries_mpich/netcdf-fortran-4.6.1/lib64:$install_dir/libraries_mpich/libaec-v1.1.3/lib64:$install_dir/libraries_mpich/eccodes-2.32.0-Source/lib64:$install_dir/libraries_mpich/libxml2-2.9.14/lib64:$install_dir/libraries_mpich/OpenBLAS-0.3.28/lib"
		export LD_LIBRARY_PATH=${LIBS_PATH}:$LD_LIBRARY_PATH
		export PATH="$install_dir/libraries_mpich/curl-8.9.1/bin:$install_dir/libraries_mpich/mpich-4.2.2/bin:$install_dir/libraries_mpich/hdf5-1.14.4-3/bin:$install_dir/libraries_mpich/netcdf-c-4.9.2/bin:$install_dir/libraries_mpich/eccodes-2.32.0-Source/bin:$PATH:."

		export ICONTOOLS_DIR='/home/opicon/operacional/binaries/icontools/dwdicontools_2.6.0'
		export BINARY_ICONSUB="$ICONTOOLS_DIR/iconsub"
		export BINARY_REMAP="$ICONTOOLS_DIR/iconremap"

		export MPIBIN_ICONTOOLS="$install_dir/libraries_mpich/mpich-4.2.2/bin/mpiexec"
	
		export MPIBIN_ICONMODEL="$install_dir/libraries_mpich/mpich-4.2.2/bin/mpiexec"
		export BINARY_ICONMODEL="$ICONMODEL_DIR/icon_2024.07_gcc_mpich_O3" # choose your model version here
	fi
elif [ $COMPILER == "gcc12.3" ]; then
	module unload /usr/share/modules/modulefiles/intel/intel_2019.5-compilers
	module load /usr/share/modules/modulefiles/gcc/gcc-12.3.0
	install_dir='/home/devicon/gcc12.3.0_install'

	if [ $MPI == "openmpi" ];then # entra aqui se digitar um segundo arg 'openmpi'
		export ecradpath="${install_dir}/binaries/icon-model-release-2024.07-public/externals/ecrad/data"
		export ana_varnames_map_file="${install_dir}/binaries/icon-model-release-2024.07-public/run/ana_varnames_map_file.txt"
		export latbc_varnames_map_file="${install_dir}/binaries/icon-model-release-2024.07-public/run/dict.latbc"

		export ECCODES_DEFINITION_PATH="${install_dir}/libraries/definitions.edzw-2.32.0-1:${install_dir}/libraries/eccodes-2.32.0-Source/share/eccodes/definitions"

		#export LD_LIBRARY_PATH=/opt/gcc-12.2.0/lib64:$install_dir/libraries_mpich/lib64:$LD_LIBRARY_PATH
		export LIBS_PATH="/opt/gcc-12.3.0/lib64:$install_dir/libraries/zlib-1.3.1/lib:$install_dir/libraries/szip-2.1.1/lib64:$install_dir/libraries/curl-8.9.1/lib64:$install_dir/libraries/openmpi-4.0.2/lib64:$install_dir/libraries/hdf5-1.14.4-3/lib64:$install_dir/libraries/netcdf-c-4.9.2/lib64:$install_dir/libraries/netcdf-fortran-4.6.1/lib64:$install_dir/libraries/libaec-v1.1.3/lib64:$install_dir/libraries/eccodes-2.32.0-Source/lib64:$install_dir/libraries/libxml2-2.9.14/lib64:$install_dir/libraries/OpenBLAS-0.3.28/lib"
		export LD_LIBRARY_PATH=${LIBS_PATH}:$LD_LIBRARY_PATH
		export PATH="$install_dir/libraries/curl-8.9.1/bin:$install_dir/libraries/openmpi-4.0.2/bin:$install_dir/libraries/hdf5-1.14.4-3/bin:$install_dir/libraries/netcdf-c-4.9.2/bin:$install_dir/libraries/eccodes-2.32.0-Source/bin:$PATH:."

		export ICONTOOLS_DIR='/home/opicon/operacional/binaries/icontools/dwdicontools_2.6.0'
		export BINARY_ICONSUB="$ICONTOOLS_DIR/iconsub"
		export BINARY_REMAP="$ICONTOOLS_DIR/iconremap"

		export MPIBIN_ICONTOOLS="$install_dir/libraries/openmpi-4.0.2/bin/mpiexec"
	
		export MPIBIN_ICONMODEL="$install_dir/libraries/openmpi-4.0.2/bin/mpiexec"
		export BINARY_ICONMODEL="$ICONMODEL_DIR/icon_2024.07_gcc_openmpi_O3" # choose your model version here
	else # entra aqui se não digitar um segundo arg, ou seja, se $MPI for vazia
		export ecradpath="${install_dir}/binaries_mpich/icon-model-release-2024.07-public/externals/ecrad/data"
		export ana_varnames_map_file="${install_dir}/binaries_mpich/icon-model-release-2024.07-public/run/ana_varnames_map_file.txt"
		export latbc_varnames_map_file="${install_dir}/binaries_mpich/icon-model-release-2024.07-public/run/dict.latbc"

		export ECCODES_DEFINITION_PATH="${install_dir}/libraries_mpich/definitions.edzw-2.32.0-1:${install_dir}/libraries_mpich/eccodes-2.32.0-Source/share/eccodes/definitions"

		#export LD_LIBRARY_PATH=/opt/gcc-12.2.0/lib64:$install_dir/libraries_mpich/lib64:$LD_LIBRARY_PATH
		export LIBS_PATH="/opt/gcc-12.3.0/lib64:$install_dir/libraries_mpich/zlib-1.3.1/lib:$install_dir/libraries_mpich/szip-2.1.1/lib64:$install_dir/libraries_mpich/curl-8.9.1/lib64:$install_dir/libraries_mpich/mpich-4.2.3/lib64:$install_dir/libraries_mpich/hdf5-1.14.4-3/lib64:$install_dir/libraries_mpich/netcdf-c-4.9.2/lib64:$install_dir/libraries_mpich/netcdf-fortran-4.6.1/lib64:$install_dir/libraries_mpich/libaec-v1.1.3/lib64:$install_dir/libraries_mpich/eccodes-2.32.0-Source/lib64:$install_dir/libraries_mpich/libxml2-2.9.14/lib64:$install_dir/libraries_mpich/OpenBLAS-0.3.28/lib"
		export LD_LIBRARY_PATH=${LIBS_PATH}:$LD_LIBRARY_PATH
		export PATH="$install_dir/libraries_mpich/curl-8.9.1/bin:$install_dir/libraries_mpich/mpich-4.2.3/bin:$install_dir/libraries_mpich/hdf5-1.14.4-3/bin:$install_dir/libraries_mpich/netcdf-c-4.9.2/bin:$install_dir/libraries_mpich/eccodes-2.32.0-Source/bin:$PATH:."

		export ICONTOOLS_DIR='/home/opicon/operacional/binaries/icontools/dwdicontools_2.6.0'
		export BINARY_ICONSUB="$ICONTOOLS_DIR/iconsub"
		export BINARY_REMAP="$ICONTOOLS_DIR/iconremap"

		export MPIBIN_ICONTOOLS="$install_dir/libraries_mpich/mpich-4.2.3/bin/mpiexec"
	
		export MPIBIN_ICONMODEL="$install_dir/libraries_mpich/mpich-4.2.3/bin/mpiexec"
		export BINARY_ICONMODEL="$ICONMODEL_DIR/icon_2024.07_gcc12.3.0_mpich4.2.3_O3" # choose your model version here
	fi
elif [ $COMPILER == "intel2020.4" ]; then
	module unload /usr/share/modules/modulefiles/intel/intel_2019.5-compilers
        module load /usr/share/modules/modulefiles/intel/intel_2020.4-compilers
        install_dir='/home/devicon/intel2020.4_install'

        if [ $MPI == "mpiintel" ];then # entra aqui se arg='mpiintel'
		if [ "$VERSION" = "2024.10" ];then
			libs_dir="$install_dir/libs_mpiintel"
                	export ecradpath="${install_dir}/Bins-sources_mpiintel/icon-model-release-2024.10-public/externals/ecrad/data"
                	export ana_varnames_map_file="${install_dir}/Bins-sources_mpiintel/icon-model-release-2024.10-public/run/ana_varnames_map_file.txt"
                	export latbc_varnames_map_file="${install_dir}/Bins-sources_mpiintel/icon-model-release-2024.10-public/run/dict.latbc"

                	export ECCODES_DEFINITION_PATH="${install_dir}/libs_mpiintel/definitions.edzw-2.24.2-1:${install_dir}/libs_mpiintel/eccodes-2.24.0-Source/share/eccodes/definitions"

                	export LIBS_PATH="$libs_dir/zlib-1.3.1/lib:$libs_dir/szip-2.1.1/lib64:$libs_dir/curl-8.9.1/lib64:/opt/intel/intel_2020.4/compilers_and_libraries_2020.4.304/linux/mpi/intel64/lib:$libs_dir/hdf5-1.14.4-3/lib64:$libs_dir/netcdf-c-4.9.2/lib64:$libs_dir/netcdf-fortran-4.6.1/lib64:$libs_dir/libaec-v1.1.3/lib64:$libs_dir/jasper-version-2.0.33/lib64:$libs_dir/openjpeg-2.4.0/lib:$libs_dir/eccodes-2.24.0-Source/lib64:$libs_dir/libxml2-2.9.14/lib64"
                	export LD_LIBRARY_PATH=${LIBS_PATH}:$LD_LIBRARY_PATH
                	export BINS_PATH="/home/devicon/intel2020.4_install/libs_mpiintel/curl-8.9.1/bin:/opt/intel/intel_2020.4/compilers_and_libraries_2020.4.304/linux/mpi/intel64/bin:/home/devicon/intel2020.4_install/libs_mpiintel/hdf5-1.14.4-3/bin:/home/devicon/intel2020.4_install/libs_mpiintel/netcdf-c-4.9.2/bin:/home/devicon/intel2020.4_install/libs_mpiintel/jasper-version-2.0.33/bin:/home/devicon/intel2020.4_install/libs_mpiintel/openjpeg-2.4.0/bin:/home/devicon/intel2020.4_install/libs_mpiintel/eccodes-2.24.0-Source/bin:."
                	export PATH=${BINS_PATH}:${anaconda_dir}:$PATH

                	export ICONTOOLS_DIR='/home/opicon/operacional/binaries/icontools/dwdicontools_2.6.0_intel2020.4'
                	export BINARY_ICONSUB="$ICONTOOLS_DIR/iconsub"
                	export BINARY_REMAP="$ICONTOOLS_DIR/iconremap"

                	export MPIBIN_ICONTOOLS="/opt/intel/intel_2020.4/compilers_and_libraries_2020.4.304/linux/mpi/intel64/bin/mpiexec"
                	export MPIBIN_ICONMODEL="/opt/intel/intel_2020.4/compilers_and_libraries_2020.4.304/linux/mpi/intel64/bin/mpiexec"

			export MODEL_DIR="${install_dir}/Bins-sources_mpiintel/icon-model-release-2024.10-public"
                	export BINARY_ICONMODEL="$ICONMODEL_DIR/icon_2024.10_intel2020.4_mpiintel_O3" # choose your model version here
		elif [ "$VERSION" = "2025.04" ];then
			src_dir=$install_dir/src
			build_dir=$install_dir/build
			export MODEL_DIR=$src_dir/icon-model-2025.04
			export ecradpath="$MODEL_DIR/externals/ecrad/data"
			export ana_varnames_map_file="$MODEL_DIR/run/ana_varnames_map_file.txt"
			export latbc_varnames_map_file="$MODEL_DIR/run/dict.latbc"
			export ECCODES_DEFINITION_PATH="$build_dir/definitions.edzw-2.30.2-1:$src_dir/eccodes-2.30.2-Source/definitions"
			export LIBS_PATH="$build_dir/zlib-1.3.1/lib:$build_dir/szip-2.1.1/lib64:$I_MPI_ROOT/intel64/lib:$build_dir/hdf5-1.14.4-3/lib64:$build_dir/netcdf-c-4.9.2/lib64:$build_dir/netcdf-fortran-4.6.1/lib64:$build_dir/libaec-v1.1.3/lib64:$build_dir/jasper-version-2.0.33/lib64:$build_dir/openjpeg-2.4.0/lib:$build_dir/eccodes-2.30.2-Source/lib64:$build_dir/libxml2-2.9.14/lib64"
			export LD_LIBRARY_PATH=${LIBS_PATH}:$LD_LIBRARY_PATH
			export BINS_PATH="$I_MPI_ROOT/intel64/bin:$build_dir/hdf5-1.14.4-3/bin:$build_dir/netcdf-c-4.9.2/bin:$build_dir/jasper-version-2.0.33/bin:$build_dir/openjpeg-2.4.0/bin:$build_dir/eccodes-2.30.2-Source/bin"
			export PATH="${BINS_PATH}:${anaconda_dir}:$PATH:."
			export ICONTOOLS_DIR="$ICONTOOLS_ROOT/dwdicontools_2.6.0_intel2020.4"
                	export BINARY_ICONSUB="$ICONTOOLS_DIR/iconsub"
                	export BINARY_REMAP="$ICONTOOLS_DIR/iconremap"

                	export MPIBIN_ICONTOOLS="$I_MPI_ROOT/intel64/bin/mpiexec"
                	export MPIBIN_ICONMODEL="$I_MPI_ROOT/intel64/bin/mpiexec"

                	export BINARY_ICONMODEL="$ICONMODEL_DIR/icon_2025.04_intel2020.4_mpiintel_O3" # choose your model version here
		else
			echo Error! Version not found! Choose between $icon_version_list[@].
			exit 2
		fi

        elif [ $MPI == "mpich" ];then # entra aqui se arg='mpich'
		libs_dir="$install_dir/libs_mpich"
                export ecradpath="${install_dir}/Bins-sources_mpich/icon-model-release-2024.10-public/externals/ecrad/data"
                export ana_varnames_map_file="${install_dir}/Bins-sources_mpich/icon-model-release-2024.10-public/run/ana_varnames_map_file.txt"
                export latbc_varnames_map_file="${install_dir}/Bins-sources_mpich/icon-model-release-2024.10-public/run/dict.latbc"

                export ECCODES_DEFINITION_PATH="${libs_dir}/definitions.edzw-2.30.2-1:${libs_dir}/eccodes-2.30.2-Source/share/eccodes/definitions"

                export LIBS_PATH="$libs_dir/zlib-1.3.1/lib:$libs_dir/szip-2.1.1/lib64:${libs_dir}/mpich-4.2.3/lib64:$libs_dir/hdf5-1.14.4-3/lib64:$libs_dir/netcdf-c-4.9.2/lib64:$libs_dir/netcdf-fortran-4.6.1/lib64:$libs_dir/libaec-v1.1.3/lib64:$libs_dir/jasper-version-2.0.33/lib64:$libs_dir/openjpeg-2.4.0/lib:$libs_dir/eccodes-2.30.2-Source/lib64:$libs_dir/libxml2-2.9.14/lib64"
                export LD_LIBRARY_PATH=${LIBS_PATH}:$LD_LIBRARY_PATH
                export BINS_PATH="$libs_dir/mpich-4.2.3/bin:${libs_dir}/hdf5-1.14.4-3/bin:${libs_dir}/netcdf-c-4.9.2/bin:${libs_dir}/jasper-version-2.0.33/bin:${libs_dir}/openjpeg-2.4.0/bin:${libs_dir}/eccodes-2.30.2-Source/bin:$PATH:."
                export PATH=${BINS_PATH}:${anaconda_dir}:$PATH

                export ICONTOOLS_DIR='/home/opicon/operacional/binaries/icontools/dwdicontools_2.6.0_intel2020.4_mpich'
                export BINARY_ICONSUB="$ICONTOOLS_DIR/iconsub"
                export BINARY_REMAP="$ICONTOOLS_DIR/iconremap"
                export MPIBIN_ICONTOOLS="${libs_dir}/mpich-4.2.3/bin/mpiexec"

		export MODEL_DIR="${install_dir}/Bins-sources_mpich/icon-model-release-2024.10-public"
                export MPIBIN_ICONMODEL="${libs_dir}/mpich-4.2.3/bin/mpiexec"
                export BINARY_ICONMODEL="$ICONMODEL_DIR/icon_2024.10_intel2020.4_mpich_O3" # choose your model version here
	else
		echo Error! $MPI not found.
		exit 33
	fi

else
	echo "Compiler $COMPILER not listed. Try one of the following: ${compiler_list[*]}"
	exit 22
fi
