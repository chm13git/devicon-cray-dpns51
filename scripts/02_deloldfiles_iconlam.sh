#!/bin/bash -l
unset CDPATH

# Loading environment and vars
#conda activate ecflow

# Delete old ICON operational run files
#
# Usage:
#   $0 HH
#   $0 HH GRID
#
# Examples:
#   $0 00
#   $0 00 sam
#
# GRID: sam | sse | ant | pen

ecflow_info()
{
    local label="$1"
    local message="$2"

    echo "${message}"
    ecflow_client --label="${label}" "${message}" > /dev/null 2>&1
}

deloldfiles()
{
    local HH="$1"
    local GRID="$2"
    local WORKDIR

    case "${GRID}" in
        sam)
            WORKDIR="${OPERACIONAL_DIR}/sam6.5/data"
            ;;
        sse)
            WORKDIR="${OPERACIONAL_DIR}/sse2.1/data"
            ;;
        ant)
            WORKDIR="${OPERACIONAL_DIR}/ant6.5/data"
            ;;
        pen)
            WORKDIR="${OPERACIONAL_DIR}/pen2.1/data"
            ;;
        *)
            echo "ERROR! Invalid grid: ${GRID}"
            echo "Valid grids: sam, sse, ant, pen"
            ecflow_info "Info1" "FATAL ERROR. Domínio inválido: ${GRID}."
            ecflow_info "Info2" "Script abortado em: $(date)"
            return 12
            ;;
    esac

    if [ ! -d "${WORKDIR}" ]; then
        echo "ERROR! Workdir not found: ${WORKDIR}"
        ecflow_info "Info1" "FATAL ERROR. Diretório não encontrado: ${WORKDIR}."
        ecflow_info "Info2" "Script abortado em: $(date)"
        return 13
    fi

    ecflow_info "Info1" "Iniciando limpeza para ${HH}, domínio ${GRID}."
    ecflow_info "Info2" "Processo iniciado em: $(date)"

    echo "Deleting old ICON files for ${HH}, ${GRID}..."
    echo "Workdir: ${WORKDIR}"

    ecflow_info "Info1" "Deletando arquivos de inputdataready${HH} - ${GRID}."
    rm -f "${WORKDIR}/inputdataready${HH}"/ICON*
    rm -f "${WORKDIR}/inputdataready${HH}"/igf*
    rm -f "${WORKDIR}/inputdataready${HH}"/raw*

    ecflow_info "Info1" "Deletando arquivos de outputdata${HH} - ${GRID}."
    rm -f "${WORKDIR}/outputdata${HH}"/out*
    rm -f "${WORKDIR}/outputdata${HH}"/nml*
    rm -f "${WORKDIR}/outputdata${HH}"/NAMELIST*
    rm -f "${WORKDIR}/outputdata${HH}"/icon*
    rm -f "${WORKDIR}/outputdata${HH}"/finish*
    rm -f "${WORKDIR}/outputdata${HH}"/RUN*

    ecflow_info "Info1" "Deletando arquivos de initialcond${HH} - ${GRID}."
    rm -f "${WORKDIR}/initialcond${HH}"/igfff*
    rm -f "${WORKDIR}/initialcond${HH}"/lateral*

    ecflow_info "Info1" "Limpeza finalizada para ${HH}, domínio ${GRID}."
    ecflow_info "Info2" "Domínio ${GRID} finalizado em: $(date)"
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 HH [GRID]"
    echo "Examples:"
    echo "  $0 00"
    echo "  $0 00 sam"
    ecflow_info "Info1" "FATAL ERROR. Número de argumentos inválido."
    ecflow_info "Info2" "Script abortado em: $(date)"
    exit 11
fi

HH="$1"
GRID="${2:-}"

if [ "${HH}" != "00" ] && [ "${HH}" != "12" ]; then
    echo "ERROR! Invalid run: ${HH}"
    echo "Valid runs: 00 or 12"
    ecflow_info "Info1" "FATAL ERROR. Rodada inválida: ${HH}. Use 00 ou 12."
    ecflow_info "Info2" "Script abortado em: $(date)"
    exit 14
fi

ecflow_info "Info1" "Iniciando limpeza de arquivos antigos da rodada ${HH}."
ecflow_info "Info2" "Processo iniciado em: $(date)"

if [ -z "${GRID}" ]; then
    RUNLIST="${SCRIPTS_DIR}/runlist"

    if [ ! -f "${RUNLIST}" ]; then
        echo "ERROR! runlist not found: ${RUNLIST}"
        ecflow_info "Info1" "FATAL ERROR. Arquivo runlist não encontrado: ${RUNLIST}."
        ecflow_info "Info2" "Script abortado em: $(date)"
        exit 15
    fi

    gridslist=$(cat "${RUNLIST}")
    ecflow_info "Info1" "Executando limpeza para a lista: ${gridslist}."

    while read -r GRID; do
        [ -z "${GRID}" ] && continue
        deloldfiles "${HH}" "${GRID}"
    done < "${RUNLIST}"
else
    deloldfiles "${HH}" "${GRID}"
fi

ecflow_info "Info1" "Processo de limpeza finalizado com sucesso."
ecflow_info "Info2" "Processo finalizado em: $(date)"

echo "Old ICON files successfully deleted."
echo "Finished at: $(date)"

ecflow_client --event DeletaAntigos_SAFO > /dev/null 2>&1
