#!/bin/bash -l
unset CDPATH

# ============================================================
# Script: 02_delete_old_iconlam.sh
#
# Função:
#   Remove arquivos de execuções anteriores do ICONLAM antes
#   do início de uma nova rodada operacional.
#
# Uso:
#   $0 HH
#   $0 HH GRID
#
# Exemplos:
#   $0 00
#   $0 00 sam
#
# Argumentos:
#   HH   - rodada do modelo: 00 ou 12
#   GRID - grade opcional: sam, sse, ant ou pen
#
# Comportamento:
#   - Com GRID informado, limpa somente a grade selecionada.
#   - Sem GRID, lê ${SCRIPTS_DIR}/runlist e limpa todas as
#     grades listadas no arquivo.
#
# Arquivos/diretórios utilizados:
#   ${OPERACIONAL_DIR}/${GRID_DIR[$GRID]}/data/
#   ${SCRIPTS_DIR}/runlist
#
# Dependências do ambiente (00_env_vars_iconlam.sh):
#   OPERACIONAL_DIR
#   SCRIPTS_DIR
#   GRID_DIR
#   ecflow_info()
#   ecflow_event()
#
# Arquivos removidos:
#   inputdataready${HH}/ICON*
#   inputdataready${HH}/igf*
#   inputdataready${HH}/raw*
#   outputdata${HH}/out*
#   outputdata${HH}/nml*
#   outputdata${HH}/NAMELIST*
#   outputdata${HH}/icon*
#   outputdata${HH}/finish*
#   outputdata${HH}/RUN*
#   initialcond${HH}/igfff*
#   initialcond${HH}/lateral*
#
# Eventos ecFlow:
#   DeletaAntigos_SAFO - sinaliza a conclusão da limpeza.
#
# Retorno:
#   0  - execução concluída com sucesso
#   11 - número de argumentos inválido
#   12 - grade inválida
#   13 - diretório da grade não encontrado
#   14 - rodada inválida
#   15 - arquivo runlist não encontrado
#   16 - falha na limpeza de uma grade
#
# Observações:
#   - O script não define ecflow_info() nem ecflow_event().
#     Essas funções devem estar disponíveis no ambiente carregado
#     pelo 00_env_vars_iconlam.sh.
#   - O comando rm utiliza curingas e não gera erro caso os
#     arquivos não existam.
# ============================================================

deloldfiles()
{
    # --------------------------------------------------------
    # deloldfiles
    #
    # Função: Remove arquivos gerados em execuções anteriores
    #         do ICONLAM para uma determinada rodada e grade.
    #
    # Uso:
    #   deloldfiles HH GRID
    #
    # Argumentos:
    #   HH   - rodada do modelo: 00 ou 12
    #   GRID - grade: sam, sse, ant ou pen
    #
    # Dependências do ambiente (00_env_vars_iconlam.sh):
    #   OPERACIONAL_DIR - diretório principal da operação
    #   GRID_DIR        - associação entre grade e diretório
    #   ecflow_info()   - envia mensagens ao ecFlow
    #
    # Diretórios utilizados:
    #   ${OPERACIONAL_DIR}/${GRID_DIR[$GRID]}/data/
    #   ├── inputdataready${HH}/
    #   ├── outputdata${HH}/
    #   └── initialcond${HH}/
    #
    # Arquivos removidos:
    #   inputdataready${HH}/
    #     ICON*
    #     igf*
    #     raw*
    #
    #   outputdata${HH}/
    #     out*
    #     nml*
    #     NAMELIST*
    #     icon*
    #     finish*
    #     RUN*
    #
    #   initialcond${HH}/
    #     igfff*
    #     lateral*
    #
    # Retorno:
    #   0  - limpeza concluída
    #   12 - grade inválida
    #   13 - diretório da grade não encontrado
    # --------------------------------------------------------

    local HH="$1"
    local GRID="$2"
    local WORKDIR="${OPERACIONAL_DIR}/${GRID_DIR[$GRID]}/data"

    if [ -z "${GRID_DIR[$GRID]+x}" ]; then
        ecflow_info "ERROR: Domínio inválido: ${GRID}. Use: sam, sse, ant ou pen."
        return 12
    fi

    if [ ! -d "${WORKDIR}" ]; then
        ecflow_info "ERROR: Diretório não encontrado: ${WORKDIR}."
        return 13
    fi

    echo "Deleting old ICON files for ${HH}, ${GRID}..."
    echo "Workdir: ${WORKDIR}"

    ecflow_info "Iniciando limpeza para ${HH}, domínio ${GRID}."

    ecflow_info "Deletando arquivos de inputdataready${HH} - ${GRID}."
    rm -f \
        "${WORKDIR}/inputdataready${HH}"/ICON* \
        "${WORKDIR}/inputdataready${HH}"/igf* \
        "${WORKDIR}/inputdataready${HH}"/raw*

    ecflow_info "Deletando arquivos de outputdata${HH} - ${GRID}."
    rm -f \
        "${WORKDIR}/outputdata${HH}"/out* \
        "${WORKDIR}/outputdata${HH}"/nml* \
        "${WORKDIR}/outputdata${HH}"/NAMELIST* \
        "${WORKDIR}/outputdata${HH}"/icon* \
        "${WORKDIR}/outputdata${HH}"/finish* \
        "${WORKDIR}/outputdata${HH}"/RUN*

    ecflow_info "Deletando arquivos de initialcond${HH} - ${GRID}."
    rm -f \
        "${WORKDIR}/initialcond${HH}"/igfff* \
        "${WORKDIR}/initialcond${HH}"/lateral*

    ecflow_info "Limpeza finalizada para ${HH}, domínio ${GRID}."
    return 0
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 HH [GRID]"
    echo "Examples:"
    echo "  $0 00"
    echo "  $0 00 sam"
    ecflow_info "ERROR: Número de argumentos inválido."
    exit 11
fi

HH="$1"
GRID="${2:-}"

if [ "${HH}" != "00" ] && [ "${HH}" != "12" ]; then
    echo "ERROR: Rodada inválida: ${HH}. Use 00 ou 12."
    ecflow_info "ERROR: Rodada inválida: ${HH}. Use 00 ou 12."
    exit 14
fi

ecflow_info "Iniciando limpeza de arquivos antigos da rodada ${HH}."

if [ -z "${GRID}" ]; then
    RUNLIST="${SCRIPTS_DIR}/runlist"

    if [ ! -f "${RUNLIST}" ]; then
        ecflow_info "ERROR: Arquivo runlist não encontrado: ${RUNLIST}."
        exit 15
    fi

    while read -r GRID; do
        [ -z "${GRID}" ] && continue

        if ! deloldfiles "${HH}" "${GRID}"; then
            ecflow_info "ERROR: Falha na limpeza do domínio ${GRID}."
            exit 16
        fi
    done < "${RUNLIST}"
else
    if ! deloldfiles "${HH}" "${GRID}"; then
        exit $?
    fi
fi

ecflow_info \
    "Processo de limpeza finalizado com sucesso." \
    "Processo finalizado em: $(date)"

ecflow_event DeletaAntigos_SAFO

echo "Old ICON files successfully deleted."
echo "Finished at: $(date)"
