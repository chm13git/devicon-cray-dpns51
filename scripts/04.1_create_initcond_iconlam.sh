#!/bin/bash
#
# Script for creating the NAMELIST_ICONREMAP and 
# NAMELIST_ICONREMAP_FIELDS files for the analysis data.
#
# Author: CT(T) Neris
# 
#
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 1 - Retrieving parameters
if [ $# -ne 3 ];then
        echo "Enter the run (00, 12), grid (sam, sse, ant, pen) and run type (ope/exp)!"
        echo "script 00 sam ope"
        exit 11
fi

HH=$1
GRID=$2
RUNTYPE=$3

# Analysis file is always the same, switch if it ever changes!
icfile="igfff00000000"

#-----------------------------------------------------------------------------
# DWD icon tools binaries

# Script to export the binaries according to the chosen compiler
#source /home/opicon/operacional/scripts/00_env_vars_iconlam.sh intel2019
#source /home/opicon/operacional/scripts/00_env_vars_iconlam.sh intel2020.4 mpiintel
#source /home/opicon/operacional/scripts/00_env_vars_iconlam.sh intel2020.4 mpich
source /home/opicon/operacional/scripts/00_env_vars_iconlam.sh intel2020.4 mpiintel 2025.04

BINARY_REMAP=$BINARY_REMAP
MPIRUN=$MPIBIN_ICONTOOLS

#-----------------------------------------------------------------------------
# Step 2 - Defining grid specifics vars
case $GRID in
	sam)
	workdir="/home/opicon/operacional/sam6.5"
	ingrid="$workdir/const/grid_files/icon_grid_bras_sam_R03B07_20231113_tiles.nc"
	localgrid="$workdir/const/grid_files/ICON-SAM6.5_DOM01.nc"
	tmpl="$workdir/const/tmpl_create_ic_nml_ir_sam6.5"
	;;
	sse)
	workdir="/home/opicon/operacional/sse2.1"
	ingrid="$workdir/const/grid_files/icon_grid_bras_sam_R03B07_20231113_tiles.nc"
	localgrid="$workdir/const/grid_files/sse2.1_DOM01.nc"
	tmpl="$workdir/const/tmpl_create_ic_nml_ir_sse2.1"
	;;
	ant)
	workdir="/home/opicon/operacional/ant6.5"
	ingrid="$workdir/const/grid_files/icon_grid_bras_ant_R03B07_20231113_tiles.nc"
	localgrid="$workdir/const/grid_files/ICONLAM-ANT6.5_DOM01.nc"
	tmpl="$workdir/const/tmpl_create_ic_nml_ir_ant6.5"
	;;
	pen)
	workdir="/home/opicon/operacional/pen2.1"
	ingrid="$workdir/const/grid_files/icon_grid_bras_ant_R03B07_20231113_tiles.nc"
	localgrid="$workdir/const/grid_files/ICON-ANT2km_DOM01.nc"
	tmpl="$workdir/const/tmpl_create_ic_nml_ir_pen2.1"
esac

# I/O Dirs depend on workdir var, defined in the CASE above.
if [ $RUNTYPE == 'ope' ];then
	datadir="$workdir/data/inputdataready$HH"
	indir="$workdir/data/inputdata${HH}"
	outdir="$workdir/data/initialcond$HH"
else # dirs to experimental runs
	datadir="$workdir/data/exprun_inputdataready$HH"
	indir="$workdir/data/exprun_inputdata${HH}"
	outdir="$workdir/data/exprun_initialcond$HH"
fi

#-----------------------------------------------------------------------------
# Step 3 - Generating and running script to create NAMELISTS_ICONREMAP

cat $tmpl							> raw2_$GRID
cat raw2_$GRID | sed -e 's|GRIDNAME_ARG|'$GRID'|g'		> raw_$GRID
cat raw_$GRID | sed -e 's|INGRID_ARG|'$ingrid'|g'		> raw2_$GRID
cat raw2_$GRID | sed -e 's|LOCALGRID_ARG|'$localgrid'|g'	> raw_$GRID
cat raw_$GRID | sed -e 's|DATADIR_ARG|'$datadir'|g'		> raw2_$GRID
cat raw2_$GRID | sed -e 's|ICFILE_ARG|'$icfile'|g'		> raw_$GRID
cat raw_$GRID | sed -e 's|OUTDIR_ARG|'$outdir'|g'		> raw2_$GRID

# Renaming and running script to create NAMELISTS_ICONREMAP
mv raw2_$GRID temp_tmpl_create_ic_nml_ir_$GRID.sh
chmod 755 temp_tmpl_create_ic_nml_ir_$GRID.sh

./temp_tmpl_create_ic_nml_ir_$GRID.sh

# Running iconremap
echo MPIRUN 	  == ${MPIRUN}
echo BINARY_REMAP == ${BINARY_REMAP}
${MPIRUN} -np 1 ${BINARY_REMAP} -vvv --remap_nml NAMELIST_ICONREMAP --input_field_nml NAMELIST_ICONREMAP_FIELDS  2>&1

#-----------------------------------------------------------------------------
# clean-up
rm -f temp_*.sh raw_$GRID raw2_$GRID ncstorage.tmp* ml.log NAMELIST_ICONREMAP NAMELIST_ICONREMAP_FIELDS

date
echo "End of script 04.1!"
