#!/bin/bash -l

# Run ICON-LAM
# Author: CT(T) Neris

if [ $# -ne 1 ] && [ $# -ne 2 ] && [ $# -ne 3 ]; then
    echo "Usage: $0 <HH> [GRID] [DATE]"
    exit 11
fi

HH="$1" && echo HH = $HH
GRID="${2:-sam}" && echo GRID = $GRID
CURRDATE="${3:-$(<"${DATES_DIR}/currentdate${HH}")}" && echo CURRDATE = $CURRDATE

if [ -z "${GRID_DIR[$GRID]+x}" ]; then
    echo "ERROR: Invalid domain '${GRID}'."
    exit 12
fi

# ============================================================
# Configuration
# ============================================================

DOMAIN="${GRID_DIR[$GRID]}"
MODEL="${BINARY_ICONMODEL}"
MPIEXEC="${MPI_LAUNCH}"

LOCALGRID="${GRID_LOCALGRID[$GRID]}"
RADGRID="${GRID_RADGRID[$GRID]}"
EXTPARGRID="${GRID_EXTPAR[$GRID]}"
TEMPLATE="${GRID_TEMPLATE_ICON[$GRID]}"

LBCDIR="${GRID_INITIALCOND_DIR[$GRID]}${HH}"
OUTDIR="${GRID_OUTPUTDATA_DIR[$GRID]}${HH}"

LBCGRID="${LBCDIR}/lateral_boundary.grid.nc"
ICFILE="${LBCDIR}/igfff00000000.grb2"
RUNNODES="${GRID_WORKDIR[$GRID]}/const/icon_model_nodes.txt"

FORECAST_TIME="${GRID_FPROG[$GRID]}"
HSTART="$(date -u -d "${CURRDATE} ${HH}:00:00" '+%Y-%m-%dT%H:%M:%SZ')"
HSTOP="$(date -u -d "${HSTART} + ${FORECAST_TIME} hours" '+%Y-%m-%dT%H:%M:%SZ')"

# ============================================================
# Check node configuration
# ============================================================

if [ ! -f "${RUNNODES}" ]; then
    echo "ERROR: Node configuration file not found:"
    echo "${RUNNODES}"
    exit 22
fi

HOST_LIST=""
NUM_TOTAL_PROCS=0

while IFS=: read -r NODE NPROCS; do

    # Ignore empty lines and comments
    [ -z "${NODE}" ] && continue
    [[ "${NODE}" =~ ^[[:space:]]*# ]] && continue

    # Remove leading/trailing spaces
    NODE="$(echo "${NODE}" | xargs)"
    NPROCS="$(echo "${NPROCS}" | xargs)"

    if [ -z "${NODE}" ] || ! [[ "${NPROCS}" =~ ^[0-9]+$ ]] || [ "${NPROCS}" -eq 0 ]; then
        echo "ERROR: Invalid entry in ${RUNNODES}:"
        echo "${NODE}:${NPROCS}"
        exit 22
    fi

    if [ -n "${HOST_LIST}" ]; then
        HOST_LIST+=","
    fi

    HOST_LIST+="${NODE}:${NPROCS}"
    NUM_TOTAL_PROCS=$((NUM_TOTAL_PROCS + NPROCS))

done < "${RUNNODES}"

if [ "${NUM_TOTAL_PROCS}" -eq 0 ]; then
    echo "ERROR: No MPI processes configured in ${RUNNODES}."
    exit 22
fi

echo "MPI configuration:"
echo "  Hosts : ${HOST_LIST}"
echo "  Total : ${NUM_TOTAL_PROCS} processes"

# ============================================================
# Check required files
# ============================================================

if [ ! -f "${LBCGRID}" ]; then
    ecflow_info Info1 "ERROR! LBC grid not found: ${LBCGRID}"
    exit 22
fi

if [ ! -f "${ICFILE}" ]; then
    ecflow_info Info1 "ERROR! Initial condition not found: ${ICFILE}"
    exit 22
fi

# ============================================================
# Check nodes
# ============================================================

ecflow_info Info1 "Verificando disponibilidade dos nós..."
ecflow_info Info2 "Nós: ${HOST_LIST}"

for NODE in $(echo "${HOST_LIST}" | tr ',' ' ' | cut -d: -f1); do

    if ! ssh "${NODE}" "hostname" > /dev/null 2>&1; then
        ecflow_info Info1 "ERROR! Nó ${NODE} não está acessível."
        exit 22
    fi

done

# ============================================================
# Create ICON namelist
# ============================================================

cd "${OUTDIR}" || exit 22

sed \
    -e "s|HH_ARG|${HH}|g" \
    -e "s|GRIDNAME_ARG|${GRID}|g" \
    -e "s|DATE_ARG|${CURRDATE}|g" \
    -e "s|HSTART_ARG|${HSTART}|g" \
    -e "s|HSTOP_ARG|${HSTOP}|g" \
    -e "s|ICFILE_ARG|${ICFILE}|g" \
    -e "s|LBCDIR_ARG|${LBCDIR}|g" \
    -e "s|LBCGRID_ARG|${LBCGRID}|g" \
    -e "s|LOCALGRID_ARG|${LOCALGRID}|g" \
    -e "s|RADGRID_ARG|${RADGRID}|g" \
    -e "s|EXTPAR_ARG|${EXTPARGRID}|g" \
    "${TEMPLATE}" > "temp_create_icon_nml_${GRID}.sh"

chmod +x "temp_create_icon_nml_${GRID}.sh"
"./temp_create_icon_nml_${GRID}.sh"

# ============================================================
# Rename output
# ============================================================

"${SCRIPTS_DIR}/05.1_renameoutput_iconlam.sh" \
    "${HH}" \
    "${GRID}" \
    0 \
    "${FORECAST_TIME}" \
    "${CURRDATE}" \
    > "${SCRIPTS_DIR}/logs/rename_${GRID}_${HH}.log" 2>&1 &

# ============================================================
# Run ICON
# ============================================================

ecflow_info Info1 "Iniciando execução do ICON..."
ecflow_info Info2 "Data/Hora: $(date)"
ecflow_info Info2 "Domínio: ${GRID}"
ecflow_info Info2 "Nós: ${HOST_LIST}"
ecflow_info Info2 "Processos MPI: ${NUM_TOTAL_PROCS}"

time "${MPIEXEC}" \
    --host "${HOST_LIST}" \
    -np "${NUM_TOTAL_PROCS}" \
    "${MODEL}"

RET=$?

if [ "${RET}" -ne 0 ]; then
    ecflow_info Info1 "ERROR! ICON terminou com erro. Código: ${RET}"
    exit "${RET}"
fi

ecflow_info Info1 "ICON finalizado com sucesso."

# ============================================================
# Cleanup
# ============================================================

rm -f \
    "temp_create_icon_nml_${GRID}.sh" \
    NAMELIST_ICON \
    NAMELIST_ICON_FIELDS

exit 0
