#!/bin/bash -l

# ============================================================
# Script: 03_currentdate_iconlam.sh
#
# Função:
#   Gera o arquivo com a data corrente da rodada operacional
#   do ICONLAM.
#
# Uso:
#   $0 HH
#
# Exemplos:
#   $0 00
#   $0 12
#
# Argumentos:
#   HH - rodada do modelo: 00 ou 12
#
# Arquivo gerado:
#   ${DATES_DIR}/currentdate${HH}
#
# Conteúdo:
#   Data corrente no formato YYYYMMDD.
#
# Dependências do ambiente (00_env_vars_iconlam.sh):
#   DATES_DIR
#   ecflow_info()
#   ecflow_event()
#
# Eventos ecFlow:
#   AtuData_SAFO - sinaliza a atualização da data.
#
# Retorno:
#   0  - arquivo gerado com sucesso
#   2  - erro na geração do arquivo
#   11 - rodada inválida
# ============================================================

if [ $# -ne 1 ] || [[ ! "$1" =~ ^(00|12)$ ]]; then
    ecflow_info "ERROR: Entre com a rodada: 00 ou 12."
    exit 11
fi

HH="$1"
FILE="${DATES_DIR}/currentdate${HH}"

if date +%Y%m%d > "${FILE}"; then
    CURRENTDATE=$(<"${FILE}")

    ecflow_info \
        "OK: Data atual da rodada ${HH}: ${CURRENTDATE}." \
        "Processo finalizado em: $(date)"

    ecflow_event AtuData_SAFO
else
    ecflow_info \
        "ERROR: Não foi possível gerar o arquivo ${FILE}." \
        "Processo finalizado em: $(date)"

    exit 2
fi
