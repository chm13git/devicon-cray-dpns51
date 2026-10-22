#!/bin/bash -l

# ============================================================
# Script: 04.2_create_latbc_iconlam.sh
# Função: gera condições de contorno com ICONSUB/ICONREMAP e valida
# o GRIB2 temporário antes de publicar o arquivo final.
# Uso: $0 HH GRID INPROGF
# Dependências do 00: GRID_INGRID, GRID_LOCALGRID, GRID_TEMPLATE_LBC_SUB,
# GRID_TEMPLATE_LBC_IR, GRID_INPUTDATAREADY_DIR, GRID_INITIALCOND_DIR,
# ICONTOOLS_LIB, MPI_LAUNCH, BINARY_ICONSUB, BINARY_REMAP,
# ecflow_info(), set_tmp_grib_output() e validate_publish_grib().
# Validação: 981 mensagens para igfff00000000; 891 para os demais.
# Retornos: 11 argumentos/rodada inválidos; 12 grade inválida; 22 falha.
# ============================================================

if [ $# -ne 3 ]; then
    echo "Usage: $0 <HH> <GRID> <INPROGF>"
    exit 11
fi

HH="$1"
GRID="$2"
INPROGF="$3"

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
DATADIR="${GRID_INPUTDATAREADY_DIR[$GRID]}${HH}"
OUTDIR="${GRID_INITIALCOND_DIR[$GRID]}${HH}"

if [ ! -d "${DATADIR}" ] || [ ! -d "${OUTDIR}" ]; then
    ecflow_info "ERROR: Diretório de entrada ou saída ausente para ${GRID}/${HH}."
    exit 22
fi

if [ ! -f "${OUTDIR}/lateral_boundary.grid.nc" ]; then
    TEMPLATE="${GRID_TEMPLATE_LBC_SUB[$GRID]}"
    [ -f "${TEMPLATE}" ] || { ecflow_info "ERROR: Template ICONSUB não encontrado: ${TEMPLATE}."; exit 22; }

    sed \
        -e "s|GRIDNAME_ARG|${GRID}|g" \
        -e "s|INGRID_ARG|${INGRID}|g" \
        -e "s|LOCALGRID_ARG|${LOCALGRID}|g" \
        -e "s|DATADIR_ARG|${DATADIR}|g" \
        -e "s|OUTDIR_ARG|${OUTDIR}|g" \
        "${TEMPLATE}" > "temp_iconsub_${GRID}.sh" || exit 22

    chmod +x "temp_iconsub_${GRID}.sh" || exit 22
    "./temp_iconsub_${GRID}.sh" || exit 22

    LD_PRELOAD="${ICONTOOLS_LIB}/libcdi.so.0" \
    "${MPI_LAUNCH}" -np 1 "${BINARY_ICONSUB}" --nml NAMELIST_ICONSUB
    STATUS=$?
    if [ "${STATUS}" -ne 0 ]; then
        ecflow_info "ERROR: iconsub falhou (status ${STATUS})."
        exit "${STATUS}"
    fi
fi

TEMPLATE="${GRID_TEMPLATE_LBC_IR[$GRID]}"
FINALFILE="${OUTDIR}/${INPROGF}_lbc.grb2"
[ -f "${TEMPLATE}" ] || { ecflow_info "ERROR: Template ICONREMAP não encontrado: ${TEMPLATE}."; exit 22; }

sed \
    -e "s|FILENAME_ARG|${INPROGF}|g" \
    -e "s|GRIDNAME_ARG|${GRID}|g" \
    -e "s|INGRID_ARG|${INGRID}|g" \
    -e "s|LOCALGRID_ARG|${LOCALGRID}|g" \
    -e "s|DATADIR_ARG|${DATADIR}|g" \
    -e "s|OUTDIR_ARG|${OUTDIR}|g" \
    "${TEMPLATE}" > "temp_iconremap_${GRID}.sh" || exit 22

chmod +x "temp_iconremap_${GRID}.sh" || exit 22
"./temp_iconremap_${GRID}.sh" || exit 22

rm -f -- "${FINALFILE%.grb2}.tmp.grb2" "${FINALFILE}.tmp"
set_tmp_grib_output NAMELIST_ICONREMAP || exit 22

LD_PRELOAD="${ICONTOOLS_LIB}/libcdi.so.0" \
"${MPI_LAUNCH}" -np 1 "${BINARY_REMAP}" \
    -q --remap_nml NAMELIST_ICONREMAP \
    --input_field_nml NAMELIST_ICONREMAP_FIELDS
STATUS=$?
if [ "${STATUS}" -ne 0 ]; then
    ecflow_info "ERROR: iconremap falhou (status ${STATUS}); saída temporária preservada, se existir."
    exit "${STATUS}"
fi

if [ "${INPROGF}" = "igfff00000000" ]; then EXPECTED=981; else EXPECTED=891; fi
validate_publish_grib "${FINALFILE}" "${EXPECTED}" || exit 22

rm -f temp_*.sh raw_${GRID} raw2_${GRID} ncstorage.tmp* ml.log \
    NAMELIST_ICONREMAP NAMELIST_ICONREMAP_FIELDS
[ "${INPROGF}" != "igfff05000000" ] || rm -f NAMELIST_ICONSUB

echo "End of script 04.2."
