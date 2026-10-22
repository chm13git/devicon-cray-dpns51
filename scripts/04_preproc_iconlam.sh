#!/bin/bash -lx

# ============================================================
# Script: 04_preproc_iconlam.sh
# Função: verifica a data dos arquivos de entrada e coordena a geração
# das condições iniciais e de contorno do ICONLAM.
# Uso: $0 HH | $0 HH GRID | $0 HH GRID IPROG FPROG [DATE]
# Dependências do 00: OPERACIONAL_DIR, GRID_DIR, GRID_FPROG, SCRIPTS_DIR,
# DATES_DIR, ecflow_info() e ecflow_event(). Os scripts 04.1 e 04.2
# validam os GRIB2 gerados antes de publicar os arquivos finais.
# ============================================================

preproc()
{
    # Aguarda icon_new e os arquivos de previsão, valida data de referência
    # e chama 04.1/04.2. Retorna 22 em caso de timeout ou falha subordinada.
    local HH="$1" GRID="$2" IPROG="$3" FPROG="$4" DATE="$5"
    local WORKDIR="${OPERACIONAL_DIR}/${GRID_DIR[$GRID]}/data"
    local INDIR="${WORKDIR}/inputdata${HH}" DATADIR="${WORKDIR}/inputdataready${HH}"
    local DATETIME="${DATE}${HH}" SLEEP=30 MAX=720 i prog FILEN FLAG REFDATE

    [ "${IPROG}" = "default" ] && IPROG=0
    [ "${FPROG}" = "default" ] && FPROG="${GRID_FPROG[$GRID]}"
    cd "${DATADIR}" || { ecflow_info "ERROR: Diretório não encontrado: ${DATADIR}."; return 22; }

    for ((i=1; i<=MAX; i++)); do
        ecflow_info "Verificando icon_new para ${GRID}: ${DATETIME}."
        cp -f "${INDIR}/icon_new.bz2" . 2>/dev/null
        [ ! -f icon_new.bz2 ] || bunzip2 -f icon_new.bz2
        if [ -f icon_new ] && [ "$(head -1 icon_new)$(head -2 icon_new | tail -1)" = "${DATETIME}" ]; then
            echo "$(date) - The data reception has already started" > "ICONDATA_${DATETIME}"
            break
        fi
        rm -f icon_new
        sleep "${SLEEP}"
    done

    if [ "${i}" -gt "${MAX}" ]; then
        ecflow_info "ERROR: Esperei o arquivo icon_new por 6 horas para ${GRID}."
        return 22
    fi

    for ((prog=IPROG; prog<=FPROG; prog+=3)); do
        ecflow_info "Iniciando pré-processamento do prog ${prog}."
        ecflow_client --meter=progress "${prog}" >/dev/null 2>&1
        FILEN=$(printf "igfff%02d%02d0000" $((prog / 24)) $((prog % 24)))
        FLAG="${DATADIR}/${FILEN}_${DATE}_OK"

        for ((i=1; i<=MAX; i++)); do
            if [ -f "${FLAG}" ]; then
                if [ "${FILEN}" = "igfff00000000" ]; then
                    ecflow_info "Executando ICONREMAP para condição inicial ${FILEN}."
                    "${SCRIPTS_DIR}/04.1_create_initcond_iconlam.sh" "${HH}" "${GRID}" || return 22
                fi
                ecflow_info "Executando ICONSUB/ICONREMAP para condição de contorno ${FILEN}."
                "${SCRIPTS_DIR}/04.2_create_latbc_iconlam.sh" "${HH}" "${GRID}" "${FILEN}" || return 22
                break
            fi

            if [ -f "${INDIR}/${FILEN}.bz2" ]; then
                cp -f "${INDIR}/${FILEN}.bz2" "${DATADIR}/" || return 22
                bunzip2 -f "${DATADIR}/${FILEN}.bz2" || return 22
                REFDATE=$(grib_ls -p dataDate "${DATADIR}/${FILEN}" 2>/dev/null | head -3 | tail -1 | xargs)
                if [ "${REFDATE}" = "${DATE}" ]; then
                    touch "${FLAG}"
		    break
                else
                    rm -f "${DATADIR}/${FILEN}"
                fi
            fi
            sleep "${SLEEP}"
        done

        if [ "${i}" -gt "${MAX}" ]; then
            ecflow_info "ERROR: Esperei o arquivo ${FILEN} por 6 horas."
            return 22
        fi
    done
}

if [ $# -ne 1 ] && [ $# -ne 2 ] && [ $# -ne 4 ] && [ $# -ne 5 ]; then
    echo "Usage: $0 HH [GRID [IPROG FPROG [DATE]]]"
    ecflow_info "ERROR: Número de argumentos inválido: $#; esperado 1, 2, 4 ou 5."
    exit 11
fi

HH="$1"
if [[ ! "${HH}" =~ ^(00|12)$ ]]; then
    ecflow_info "ERROR: Rodada inválida: ${HH}. Use 00 ou 12."
    exit 11
fi
DATE="${5:-$(<"${DATES_DIR}/currentdate${HH}")}"

if [ $# -eq 1 ]; then
    while read -r GRID; do
        [ -z "${GRID}" ] && continue
        [ -n "${GRID_DIR[$GRID]+x}" ] || { ecflow_info "ERROR: Grade inválida no runlist: ${GRID}."; exit 22; }
        preproc "${HH}" "${GRID}" default default "${DATE}" || exit $?
    done < "${SCRIPTS_DIR}/runlist"
else
    GRID="$2"
    [ -n "${GRID_DIR[$GRID]+x}" ] || { ecflow_info "ERROR: Grade inválida: ${GRID}."; exit 22; }
    if [ $# -eq 2 ]; then
        preproc "${HH}" "${GRID}" default default "${DATE}" || exit $?
    else
        preproc "${HH}" "${GRID}" "$3" "$4" "${DATE}" || exit $?
    fi
fi

ecflow_info "Pré-processamento finalizado com sucesso." "Terminou em: $(date)"
ecflow_event PreProc_SAFO
