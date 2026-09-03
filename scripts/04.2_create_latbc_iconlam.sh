#!/bin/bash -l

# Create lateral boundary ICONSUB/ICONREMAP namelists
# Author: CT(T) Neris

if [ $# -ne 3 ]; then
    echo "Usage: $0 <HH> <GRID> <INPROGF>"
    exit 11
fi

HH="$1"
GRID="$2"
INPROGF="$3"

# ------------------------------------------------------------
# Domain
# ------------------------------------------------------------

if [ -z "${GRID_DIR[$GRID]+x}" ]; then
    echo "ERROR: Invalid domain '${GRID}'."
    exit 12
fi

INGRID="${GRID_INGRID[$GRID]}"
LOCALGRID="${GRID_LOCALGRID[$GRID]}"

DATADIR="${GRID_INPUTDATAREADY_DIR[$GRID]}${HH}"
OUTDIR="${GRID_INITIALCOND_DIR[$GRID]}${HH}"

# ------------------------------------------------------------
# ICONSUB
# ------------------------------------------------------------

if [ ! -f "${OUTDIR}/lateral_boundary.grid.nc" ]; then

    TEMPLATE="${GRID_TEMPLATE_LBC_SUB[$GRID]}"

    sed \
        -e "s|GRIDNAME_ARG|${GRID}|g" \
        -e "s|INGRID_ARG|${INGRID}|g" \
        -e "s|LOCALGRID_ARG|${LOCALGRID}|g" \
        -e "s|DATADIR_ARG|${DATADIR}|g" \
        -e "s|OUTDIR_ARG|${OUTDIR}|g" \
        "${TEMPLATE}" > "temp_iconsub_${GRID}.sh"

    chmod +x "temp_iconsub_${GRID}.sh"
    "./temp_iconsub_${GRID}.sh"

    # Retirar o LD_PRELOAD após recompilação do DWDICONTOOLS
    # com o LIBCDI correto.
    LD_PRELOAD="${ICONTOOLS_LIB}/libcdi.so.0" \
    "${MPI_LAUNCH}" -np 1 "${BINARY_ICONSUB}" \
        --nml NAMELIST_ICONSUB

fi

# ------------------------------------------------------------
# ICONREMAP
# ------------------------------------------------------------

TEMPLATE="${GRID_TEMPLATE_LBC_IR[$GRID]}"

sed \
    -e "s|FILENAME_ARG|${INPROGF}|g" \
    -e "s|GRIDNAME_ARG|${GRID}|g" \
    -e "s|INGRID_ARG|${INGRID}|g" \
    -e "s|LOCALGRID_ARG|${LOCALGRID}|g" \
    -e "s|DATADIR_ARG|${DATADIR}|g" \
    -e "s|OUTDIR_ARG|${OUTDIR}|g" \
    "${TEMPLATE}" > "temp_iconremap_${GRID}.sh"

chmod +x "temp_iconremap_${GRID}.sh"
"./temp_iconremap_${GRID}.sh"

# Retirar o LD_PRELOAD após recompilação do DWDICONTOOLS
# com o LIBCDI correto.
LD_PRELOAD="${ICONTOOLS_LIB}/libcdi.so.0" \
"${MPI_LAUNCH}" -np 1 "${BINARY_REMAP}" \
    -q \
    --remap_nml NAMELIST_ICONREMAP \
    --input_field_nml NAMELIST_ICONREMAP_FIELDS

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

rm -f temp_*.sh \
      raw_${GRID} raw2_${GRID} \
      ncstorage.tmp* ml.log \
      NAMELIST_ICONREMAP \
      NAMELIST_ICONREMAP_FIELDS

if [ "${INPROGF}" = "igfff05000000" ]; then
    rm -f NAMELIST_ICONSUB
fi
