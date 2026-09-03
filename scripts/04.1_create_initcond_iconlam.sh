#!/bin/bash -l

# Create NAMELIST_ICONREMAP and NAMELIST_ICONREMAP_FIELDS
# Author: CT(T) Neris

if [ $# -ne 2 ]; then
    echo "Usage: $0 <HH> <GRID>"
    exit 11
fi

HH="$1"
GRID="$2"

if [ -z "${GRID_DIR[$GRID]+x}" ]; then
    echo "ERROR: Invalid domain '${GRID}'."
    exit 12
fi

INGRID="${GRID_INGRID[$GRID]}"
LOCALGRID="${GRID_LOCALGRID[$GRID]}"
TEMPLATE="${GRID_TEMPLATE_IC_IR[$GRID]}"

DATADIR="${GRID_INPUTDATAREADY_DIR[$GRID]}${HH}"
OUTDIR="${GRID_INITIALCOND_DIR[$GRID]}${HH}"

ICFILE="igfff00000000"

# ------------------------------------------------------------
# Create namelists
# ------------------------------------------------------------

sed \
    -e "s|GRIDNAME_ARG|${GRID}|g" \
    -e "s|INGRID_ARG|${INGRID}|g" \
    -e "s|LOCALGRID_ARG|${LOCALGRID}|g" \
    -e "s|DATADIR_ARG|${DATADIR}|g" \
    -e "s|ICFILE_ARG|${ICFILE}|g" \
    -e "s|OUTDIR_ARG|${OUTDIR}|g" \
    "${TEMPLATE}" > "temp_tmpl_create_ic_nml_ir_${GRID}.sh"

chmod +x "temp_tmpl_create_ic_nml_ir_${GRID}.sh"
"./temp_tmpl_create_ic_nml_ir_${GRID}.sh"

# ------------------------------------------------------------
# Run ICONREMAP
# ------------------------------------------------------------

# Retirar o LD_PRELOAD após recompilação do DWDICONTOOLS
# com o LIBCDI correto.
LD_PRELOAD="${ICONTOOLS_LIB}/libcdi.so.0" \
"${MPI_LAUNCH}" -np 1 "${BINARY_REMAP}" \
    -vvv \
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
