#!/bin/bash -l

unset CDPATH

# ============================================================
# Arguments
# ============================================================

COMPILER="${1:-}"
MPI="${2:-openmpi}"
VERSION="${3:-2025.04}"

[[ -z "${COMPILER}" ]] && exit 11

# ============================================================
# Operational directories
# ============================================================

export OPERACIONAL_DIR="/home/devicon/operacional"
export ICONMODEL_DIR="${OPERACIONAL_DIR}/binaries/iconmodel"
export SCRIPTS_DIR="${OPERACIONAL_DIR}/scripts"
export DATES_DIR="${OPERACIONAL_DIR}/currentdates"
export ICONTOOLS_DIR="/home/alana/Doutorado/dwd_icon_tools-2.8.2/icontools"
export ICONTOOLS_LIB="${ICONTOOLS_DIR}/../externals/libcdi/src/.libs"

# ============================================================
# Domains
# ============================================================

declare -A GRID_DIR=(
    [sam]="sam6.5"
    [sse]="sse2.1"
    [ant]="ant6.5"
    [pen]="pen2.1"
)

declare -A GRID_FPROG=(
    [sam]=120
    [sse]=48
    [ant]=120
    [pen]=48
)

# ------------------------------------------------------------
# Grid files
# ------------------------------------------------------------

declare -A GRID_INGRID=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/const/grid_files/icon_grid_bras_sam_R03B07_20231113_tiles.nc"
    [sse]="${OPERACIONAL_DIR}/sse2.1/const/grid_files/icon_grid_bras_sam_R03B07_20231113_tiles.nc"
    [ant]="${OPERACIONAL_DIR}/ant6.5/const/grid_files/icon_grid_bras_ant_R03B07_20231113_tiles.nc"
    [pen]="${OPERACIONAL_DIR}/pen2.1/const/grid_files/icon_grid_bras_ant_R03B07_20231113_tiles.nc"
)

declare -A GRID_LOCALGRID=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/const/grid_files/ICON-SAM6.5_DOM01.nc"
    [sse]="${OPERACIONAL_DIR}/sse2.1/const/grid_files/sse2.1_DOM01.nc"
    [ant]="${OPERACIONAL_DIR}/ant6.5/const/grid_files/ICONLAM-ANT6.5_DOM01.nc"
    [pen]="${OPERACIONAL_DIR}/pen2.1/const/grid_files/ICON-ANT2km_DOM01.nc"
)

declare -A GRID_EXTPAR=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/const/grid_files/external_parameter_icon_ICON-SAM6.5_DOM01_tiles.nc"
    [sse]="${OPERACIONAL_DIR}/sse2.1/const/grid_files/external_parameter_icon_sse2.1_DOM01_tiles.nc"
    [ant]="${OPERACIONAL_DIR}/ant6.5/const/grid_files/external_parameter_icon_ICONLAM-ANT6.5_DOM01_tiles.nc"
    [pen]="${OPERACIONAL_DIR}/pen2.1/const/grid_files/ICON-ANT2km_DOM01_external_parameter.nc"
)

declare -A GRID_RADGRID=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/const/grid_files/ICON-SAM6.5_DOM01.parent.nc"
    [sse]="${OPERACIONAL_DIR}/sse2.1/const/grid_files/sse2.1_DOM01.parent.nc"
    [ant]="${OPERACIONAL_DIR}/ant6.5/const/grid_files/ICONLAM-ANT6.5_DOM01.parent.nc"
    [pen]="${OPERACIONAL_DIR}/pen2.1/const/grid_files/ICON-ANT2km_DOM01.parent.nc"
)

# ------------------------------------------------------------
# Templates
# ------------------------------------------------------------

declare -A GRID_TEMPLATE_IC_IR=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/const/tmpl_create_ic_nml_ir_sam6.5"
    [sse]="${OPERACIONAL_DIR}/sse2.1/const/tmpl_create_ic_nml_ir_sse2.1"
    [ant]="${OPERACIONAL_DIR}/ant6.5/const/tmpl_create_ic_nml_ir_ant6.5"
    [pen]="${OPERACIONAL_DIR}/pen2.1/const/tmpl_create_ic_nml_ir_pen2.1"
)

declare -A GRID_TEMPLATE_LBC_SUB=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/const/tmpl_create_lbc_nml_ir_sub_sam6.5"
    [sse]="${OPERACIONAL_DIR}/sse2.1/const/tmpl_create_lbc_nml_ir_sub_sse2.1"
    [ant]="${OPERACIONAL_DIR}/ant6.5/const/tmpl_create_lbc_nml_ir_sub_ant6.5"
    [pen]="${OPERACIONAL_DIR}/pen2.1/const/tmpl_create_lbc_nml_ir_sub_pen2.1"
)

declare -A GRID_TEMPLATE_LBC_IR=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/const/tmpl_create_lbc_nml_ir_sam6.5"
    [sse]="${OPERACIONAL_DIR}/sse2.1/const/tmpl_create_lbc_nml_ir_sse2.1"
    [ant]="${OPERACIONAL_DIR}/ant6.5/const/tmpl_create_lbc_nml_ir_ant6.5"
    [pen]="${OPERACIONAL_DIR}/pen2.1/const/tmpl_create_lbc_nml_ir_pen2.1"
)

declare -A GRID_TEMPLATE_ICON=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/const/tmpl_create_icon_nml_sam6.5"
    [sse]="${OPERACIONAL_DIR}/sse2.1/const/tmpl_create_icon_nml_sse2.1"
    [ant]="${OPERACIONAL_DIR}/ant6.5/const/tmpl_create_icon_nml_ant6.5"
    [pen]="${OPERACIONAL_DIR}/pen2.1/const/tmpl_create_icon_nml_pen2.1"
)

# ------------------------------------------------------------
# Data directories
# ------------------------------------------------------------

declare -A GRID_WORKDIR=(
    [sam]="${OPERACIONAL_DIR}/sam6.5"
    [sse]="${OPERACIONAL_DIR}/sse2.1"
    [ant]="${OPERACIONAL_DIR}/ant6.5"
    [pen]="${OPERACIONAL_DIR}/pen2.1"
)

declare -A GRID_INPUTDATA_DIR=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/data/inputdata"
    [sse]="${OPERACIONAL_DIR}/sse2.1/data/inputdata"
    [ant]="${OPERACIONAL_DIR}/ant6.5/data/inputdata"
    [pen]="${OPERACIONAL_DIR}/pen2.1/data/inputdata"
)

declare -A GRID_INPUTDATAREADY_DIR=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/data/inputdataready"
    [sse]="${OPERACIONAL_DIR}/sse2.1/data/inputdataready"
    [ant]="${OPERACIONAL_DIR}/ant6.5/data/inputdataready"
    [pen]="${OPERACIONAL_DIR}/pen2.1/data/inputdataready"
)

declare -A GRID_INITIALCOND_DIR=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/data/initialcond"
    [sse]="${OPERACIONAL_DIR}/sse2.1/data/initialcond"
    [ant]="${OPERACIONAL_DIR}/ant6.5/data/initialcond"
    [pen]="${OPERACIONAL_DIR}/pen2.1/data/initialcond"
)

declare -A GRID_OUTPUTDATA_DIR=(
    [sam]="${OPERACIONAL_DIR}/sam6.5/data/outputdata"
    [sse]="${OPERACIONAL_DIR}/sse2.1/data/outputdata"
    [ant]="${OPERACIONAL_DIR}/ant6.5/data/outputdata"
    [pen]="${OPERACIONAL_DIR}/pen2.1/data/outputdata"
)

# ------------------------------------------------------------
# Output characteristics
# ------------------------------------------------------------

declare -A GRID_NVARML=(
    [sam]=34
    [sse]=33
    [ant]=33
    [pen]=26
)

declare -A GRID_NVARPL=(
    [sam]=104
    [sse]=48
    [ant]=104
    [pen]=48
)

declare -A GRID_PROG_INT=(
    [sam]=3
    [sse]=1
    [ant]=3
    [pen]=1
)

# ============================================================
# Backup
# ============================================================

BACKUP_RSYNC_HOST="admbackup@dpns42"

declare -A GRID_BACKUP_DIR=(
    [sam]="/data2/backup/backup_icon/bkp_output_iconlam/sam"
    [sse]="/data2/backup/backup_icon/bkp_output_iconlam/sse"
    [ant]="/data2/backup/backup_icon/bkp_output_iconlam/ant"
    [pen]="/data2/backup/backup_icon/bkp_output_iconlam/pen"
)

declare -A GRID_BACKUP_MIN_GRIB=(
    [sam]=4437829451
    [sse]=4400000000
    [ant]=805176483
    [pen]=680000000
)

declare -A GRID_BACKUP_MIN_VRF_ML=(
    [sam]=7170221808
    [sse]=2240940896
    [ant]=3280924848
    [pen]=400532088
)

declare -A GRID_BACKUP_MIN_VRF_PL=(
    [sam]=13680028264
    [sse]=4270016624
    [ant]=6260677544
    [pen]=763023444
)

declare -A GRID_BACKUP_MIN_VRF=(
    [sam]=20807229908
    [sse]=6510140060
    [ant]=9540586708
    [pen]=1160746812
)

declare -A GRID_BACKUP_MIN_WAVE=(
    [sam]=125000000
    [sse]=2000000
    [ant]=2000000
    [pen]=0
)

declare -A GRID_BACKUP_MIN_WAVE_PS=(
    [sam]=400000
    [sse]=0
    [ant]=0
    [pen]=0
)

declare -A GRID_HAS_WAVE=(
    [sam]=1
    [sse]=1
    [ant]=1
    [pen]=0
)

declare -A GRID_HAS_WAVE_PS=(
    [sam]=1
    [sse]=0
    [ant]=0
    [pen]=0
)
# ============================================================
# Aliases
# ============================================================

for GRID in sam sse ant pen; do
    alias "icondata${GRID}00"="ls -ltrh ${GRID_INPUTDATA_DIR[$GRID]}00/"
    alias "icondata${GRID}12"="ls -ltrh ${GRID_INPUTDATA_DIR[$GRID]}12/"

    alias "init${GRID}00"="ls -ltrh ${GRID_INITIALCOND_DIR[$GRID]}00/"
    alias "init${GRID}12"="ls -ltrh ${GRID_INITIALCOND_DIR[$GRID]}12/"

    alias "inputready${GRID}00"="ls -ltrh ${GRID_INPUTDATAREADY_DIR[$GRID]}00/"
    alias "inputready${GRID}12"="ls -ltrh ${GRID_INPUTDATAREADY_DIR[$GRID]}12/"

    alias "out${GRID}00"="ls -ltrh --full-time ${GRID_OUTPUTDATA_DIR[$GRID]}00/"
    alias "out${GRID}12"="ls -ltrh --full-time ${GRID_OUTPUTDATA_DIR[$GRID]}12/"
done

alias nodes_icon="ls -ltr ${OPERACIONAL_DIR}/*/const/icon_model_nodes.txt"

# ============================================================
# Common functions
# ============================================================

# Exibe mensagens no terminal e tenta atualizar os rótulos do ecFlow.
# A indisponibilidade do ecFlow não afeta o processamento.
ecflow_info()
{
    local MSG_INFO1="$1"
    local MSG_INFO2="${2:-Data/Hora: $(date)}"

    echo "${MSG_INFO1}"
    command -v ecflow_client >/dev/null 2>&1 || return 0

    ecflow_client --label=Info1 "${MSG_INFO1}" >/dev/null 2>&1 || true
    ecflow_client --label=Info2 "${MSG_INFO2}" >/dev/null 2>&1 || true
    return 0
}

# Envia um evento ao ecFlow, sem tornar sua indisponibilidade fatal.
ecflow_event()
{
    command -v ecflow_client >/dev/null 2>&1 || return 0
    ecflow_client --event "$1" >/dev/null 2>&1 || true
    return 0
}

log_icon()
{
    tail -f "${SCRIPTS_DIR}/logs/05_${1}_${2}_$(cat "${DATES_DIR}/currentdate${1}")_ope.log"
}

check_file_size()
{
    local FILE="$1"
    local REFERENCE="$2"
    local OP="$3"
    local DESCRIPTION="$4"
    local SIZE

    if [ -f "${FILE}" ]; then
        SIZE=$(stat -c %s "${FILE}")
    else
        ecflow_info \
            "WAIT: ${DESCRIPTION} | Arquivo: ${FILE} | Status: NÃO EXISTE | Referência: ${OP} ${REFERENCE} bytes"
        return 1
    fi

    case "${OP}" in
        ge)
            if [ "${SIZE}" -ge "${REFERENCE}" ]; then
                ecflow_info \
                    "OK: ${DESCRIPTION} | Arquivo: ${FILE} | Tamanho: ${SIZE} bytes | Referência: >= ${REFERENCE} bytes"
                return 0
            fi
            ;;
        gt)
            if [ "${SIZE}" -gt "${REFERENCE}" ]; then
                ecflow_info \
                    "OK: ${DESCRIPTION} | Arquivo: ${FILE} | Tamanho: ${SIZE} bytes | Referência: > ${REFERENCE} bytes"
                return 0
            fi
            ;;
        *)
            ecflow_info \
                "ERROR: Operador inválido '${OP}'. Valores aceitos: ge ou gt."
            return 1
            ;;
    esac

    ecflow_info \
        "WAIT: ${DESCRIPTION} | Arquivo: ${FILE} | Tamanho: ${SIZE} bytes | Referência: ${OP} ${REFERENCE} bytes"
    return 1
}


check_remote_file_size()
{
    local FILE="$1"
    local REFERENCE="$2"
    local OP="$3"
    local DESCRIPTION="$4"
    local SIZE

    SIZE=$(ssh -o BatchMode=yes \
                -o ConnectTimeout=10 \
                "${BACKUP_RSYNC_HOST}" \
                stat -c %s -- "${FILE}" 2>/dev/null)

    if [ -z "${SIZE}" ]; then
        ecflow_info \
            "WAIT: ${DESCRIPTION} | Arquivo: ${BACKUP_RSYNC_HOST}:${FILE} | Status: NÃO EXISTE | Referência: ${OP} ${REFERENCE} bytes"
        return 1
    fi

    case "${OP}" in
        ge)
            if [ "${SIZE}" -ge "${REFERENCE}" ]; then
                ecflow_info \
                    "OK: ${DESCRIPTION} | Arquivo: ${BACKUP_RSYNC_HOST}:${FILE} | Tamanho: ${SIZE} bytes | Referência: >= ${REFERENCE} bytes"
                return 0
            fi
            ;;
        gt)
            if [ "${SIZE}" -gt "${REFERENCE}" ]; then
                ecflow_info \
                    "OK: ${DESCRIPTION} | Arquivo: ${BACKUP_RSYNC_HOST}:${FILE} | Tamanho: ${SIZE} bytes | Referência: > ${REFERENCE} bytes"
                return 0
            fi
            ;;
        *)
            ecflow_info \
                "ERROR: Operador inválido '${OP}'. Valores aceitos: ge ou gt."
            return 1
            ;;
    esac

    ecflow_info \
        "WAIT: ${DESCRIPTION} | Arquivo: ${BACKUP_RSYNC_HOST}:${FILE} | Tamanho: ${SIZE} bytes | Referência: ${OP} ${REFERENCE} bytes"
    return 1
}

# GRIB2 validation helpers for 04 preprocessing scripts: 
# set_tmp_grib_output
# validate_publish_grib
set_tmp_grib_output()
{
    local NML="$1"
    [ -f "${NML}" ] || { ecflow_info "ERROR: Namelist não encontrado: ${NML}."; return 1; }
    sed -i -E "/^[[:space:]]*out_filename[[:space:]]*=/ {
        s/\.tmp\.grb2(['\"])/\.grb2\1/g
        s/\.grb2(['\"])/\.tmp\.grb2\1/
    }" "${NML}" || return 1
    grep -Eq "^[[:space:]]*out_filename[[:space:]]*=.*\.tmp\.grb2['\"]" "${NML}" || {
        ecflow_info "ERROR: Não foi possível configurar saída temporária em ${NML}."
        return 1
    }
}

validate_publish_grib()
{
    local FINAL="$1" EXPECTED="$2" TMP="" COUNT="" GRIB_COUNT
    if [ -f "${FINAL%.grb2}.tmp.grb2" ]; then
        TMP="${FINAL%.grb2}.tmp.grb2"
    elif [ -f "${FINAL}.tmp" ]; then
        TMP="${FINAL}.tmp"
    elif [ -f "${FINAL%.grb2}.tmp" ]; then
        TMP="${FINAL%.grb2}.tmp"
    else
        ecflow_info "ERROR: Arquivo GRIB2 temporário não encontrado para ${FINAL}."
        return 1
    fi
    GRIB_COUNT=$(command -v grib_count 2>/dev/null)
    if [ -z "${GRIB_COUNT}" ] || [ ! -x "${GRIB_COUNT}" ]; then
        ecflow_info "ERROR: grib_count não encontrado; arquivo mantido: ${TMP}."
        return 1
    fi
    COUNT=$("${GRIB_COUNT}" "${TMP}" 2>&1) || {
        ecflow_info "ERROR: grib_count falhou para ${TMP}: ${COUNT}"
        return 1
    }
    COUNT=$(printf '%s\n' "${COUNT}" | awk 'NF {value=$NF} END {print value}')
    if [[ ! "${COUNT}" =~ ^[0-9]+$ ]]; then
        ecflow_info "ERROR: Resultado inválido do grib_count para ${TMP}: ${COUNT}."
        return 1
    fi
    echo "Validação GRIB2: ${TMP} -> ${COUNT} mensagens (esperado: ${EXPECTED})."
    if [ "${COUNT}" != "${EXPECTED}" ]; then
        ecflow_info "ERROR: ${TMP} contém ${COUNT} mensagens; esperado: ${EXPECTED}. Arquivo final preservado."
        return 1
    fi
    mv -f -- "${TMP}" "${FINAL}" || { ecflow_info "ERROR: Falha ao publicar ${FINAL}."; return 1; }
    ecflow_info "GRIB2 validado e publicado: ${FINAL} (${COUNT} mensagens)."
}
# ============================================================
# Other executables
# ============================================================

export PBZIP2="/apps/pbzip2/pbzip2-1.1.13/bin/pbzip2"

# ============================================================
# Compiler / MPI
# ============================================================

case "${COMPILER}" in

    gcc14)

        [[ "${MPI}" = "openmpi" ]] || exit 15

        export GCC_ROOT="/apps/compilers/gcc/gcc14-14.2.0"
        export OPENMPI_ROOT="/apps/libs/GCC14/openmpi-5.0.10"
        export PYTHON_ROOT="/apps/python/3.12.11"
        export AOCL_ROOT="/apps/amd/5.2.0/gcc"

        export GCC_LIB="${GCC_ROOT}/usr/lib64"
        export GCC_LIB_GCC="${GCC_ROOT}/usr/lib64/gcc/x86_64-suse-linux/14"
        export AOCL_LIB="${AOCL_ROOT}/lib_LP64"

        export CC="mpicc"
        export CXX="mpicxx"
        export FC="mpif90"
        export MPI_LAUNCH="${OPENMPI_ROOT}/bin/mpiexec"

        export PATH="${OPENMPI_ROOT}/bin:${GCC_ROOT}/wrappers:${GCC_ROOT}/usr/bin:${PYTHON_ROOT}/bin:/apps/nco/5.3.9/bin:${PATH}"

        export LD_LIBRARY_PATH="${OPENMPI_ROOT}/lib:${OPENMPI_ROOT}/lib64:${AOCL_LIB}:${GCC_LIB}:${GCC_LIB_GCC}:${PYTHON_ROOT}/lib:${LD_LIBRARY_PATH-}"

        export LIBRARY_PATH="${OPENMPI_ROOT}/lib:${OPENMPI_ROOT}/lib64:${AOCL_LIB}:${GCC_LIB}:${GCC_LIB_GCC}:${LIBRARY_PATH-}"

        export PKG_CONFIG_PATH="${OPENMPI_ROOT}/lib/pkgconfig:${OPENMPI_ROOT}/lib64/pkgconfig:${PKG_CONFIG_PATH-}"

        export CMAKE_PREFIX_PATH="${OPENMPI_ROOT}:${CMAKE_PREFIX_PATH-}"

        export PYTHONPATH="${OPENMPI_ROOT}/lib/python3.12/site-packages:${OPENMPI_ROOT}/lib64/python3.12/site-packages:${PYTHONPATH-}"

	export ECCODES_DEFINITION_PATH="/apps/libs/GCC14/openmpi-5.0.10/definitions.edzw-2.47.0-1:/apps/libs/GCC14/openmpi-5.0.10/eccodes-2.47.0/share/eccodes/definitions"

        export CFLAGS="-g1 -march=native -fPIC"
        export CXXFLAGS="-g1 -march=native -O2 -fPIC"

        export ICON_CFLAGS="-O3"
        export ICON_BUNDLED_CFLAGS="-O2"

        export CPPFLAGS="-I${OPENMPI_ROOT}/include -I${OPENMPI_ROOT}/include/libxml2"

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

        export ICON_FCFLAGS="-O2 -std=f2008 -fmodule-private"
        export ICON_OCEAN_FCFLAGS="-O3 -fno-tree-loop-vectorize -std=f2008 -fmodule-private"
        export ICON_OCEAN_PATH="src/hamocc:src/ocean:src/sea_ice"

        export ICON_DACE_FCFLAGS="-O2 -std=f2018 -fmodule-private"
        export ICON_DACE_PATH="externals/dace"

        export ICON_ECRAD_FCFLAGS="-O2 -fmodule-private"
        export ICON_SCT_FCFLAGS="-O2 -fmodule-private"
        export ICON_HD_FCFLAGS="-O2"

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

	export BINARY_ICONSUB="${ICONTOOLS_DIR}/iconsub"
	export BINARY_REMAP="${ICONTOOLS_DIR}/iconremap"
        ;;

    intel2020.4)
        exit 16
        ;;

    *)
        exit 12
        ;;
esac

# ============================================================
# ICON version
# ============================================================

case "${VERSION}" in

    2025.04|2026.04)

        export MODEL_DIR="/home/alana/Doutorado/icon-model-git"

        export ecradpath="${MODEL_DIR}/externals/ecrad/data"
        export ana_varnames_map_file="${MODEL_DIR}/run/ana_varnames_map_file.txt"
        export latbc_varnames_map_file="${MODEL_DIR}/run/dict.latbc"

        export BINARY_ICONMODEL="${ICONMODEL_DIR}/icon_${VERSION}_${COMPILER}_${MPI}_O3"
        ;;

    *)
        exit 14
        ;;
esac
