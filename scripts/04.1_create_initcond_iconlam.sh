#!/bin/bash -l

# ============================================================
# Script: 04.1_create_initcond_iconlam.sh
# Função: gera a condição inicial com ICONREMAP e valida o GRIB2
# antes de substituir o arquivo final.
# Uso: $0 HH GRID
# Dependências do 00: GRID_INGRID, GRID_LOCALGRID, GRID_TEMPLATE_IC_IR,
# GRID_INPUTDATAREADY_DIR, GRID_INITIALCOND_DIR, ICONTOOLS_LIB,
# MPI_LAUNCH, BINARY_REMAP, ecflow_info(), set_tmp_grib_output() e
# validate_publish_grib(). Validação: 1033 mensagens GRIB2.
# Retornos: 11 argumentos/rodada inválidos; 12 grade inválida; 22 falha.
# ============================================================

if [ $# -ne 2 ]; then
    echo "Usage: $0 <HH> <GRID>"
    exit 11
fi

HH="$1"
GRID="$2"

if [[ ! "${HH}" =~ ^(00|12)$ ]]; then
    ecflow_info "ERROR: Rodada inválida: ${HH}. Use 00 ou 12."
    exit 11
fi
if [ -z "${GRID_DIR[$GRID]+x}" ]; then
    ecflow_info "ERROR: Grade inválida: ${GRID}."
    exit 12
fi

INGRID="${GRID_INGRID[$GRID]}"
LOCALGRID="${GRID_LOCALGRID[$GRID]}"
TEMPLATE="${GRID_TEMPLATE_IC_IR[$GRID]}"
DATADIR="${GRID_INPUTDATAREADY_DIR[$GRID]}${HH}"
OUTDIR="${GRID_INITIALCOND_DIR[$GRID]}${HH}"
ICFILE="igfff00000000"
FINALFILE="${OUTDIR}/${ICFILE}.grb2"

if [ ! -f "${TEMPLATE}" ] || [ ! -d "${DATADIR}" ] || [ ! -d "${OUTDIR}" ]; then
    ecflow_info "ERROR: Template ou diretório de entrada/saída ausente para ${GRID}/${HH}."
    exit 22
fi

sed \
    -e "s|GRIDNAME_ARG|${GRID}|g" \
    -e "s|INGRID_ARG|${INGRID}|g" \
    -e "s|LOCALGRID_ARG|${LOCALGRID}|g" \
    -e "s|DATADIR_ARG|${DATADIR}|g" \
    -e "s|ICFILE_ARG|${ICFILE}|g" \
    -e "s|OUTDIR_ARG|${OUTDIR}|g" \
    "${TEMPLATE}" > "temp_tmpl_create_ic_nml_ir_${GRID}.sh" || exit 22

chmod +x "temp_tmpl_create_ic_nml_ir_${GRID}.sh" || exit 22
"./temp_tmpl_create_ic_nml_ir_${GRID}.sh" || exit 22

rm -f -- "${FINALFILE%.grb2}.tmp.grb2" "${FINALFILE}.tmp"
set_tmp_grib_output NAMELIST_ICONREMAP || exit 22

LD_PRELOAD="${ICONTOOLS_LIB}/libcdi.so.0" \
"${MPI_LAUNCH}" -np 1 "${BINARY_REMAP}" \
    -vvv --remap_nml NAMELIST_ICONREMAP \
    --input_field_nml NAMELIST_ICONREMAP_FIELDS
STATUS=$?
if [ "${STATUS}" -ne 0 ]; then
    ecflow_info "ERROR: iconremap falhou (status ${STATUS}); saída temporária preservada, se existir."
    exit "${STATUS}"
fi

validate_publish_grib "${FINALFILE}" 1033 || exit 22
rm -f temp_*.sh raw_${GRID} raw2_${GRID} ncstorage.tmp* ml.log \
    NAMELIST_ICONREMAP NAMELIST_ICONREMAP_FIELDS

echo "End of script 04.1."
