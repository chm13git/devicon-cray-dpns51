#!/bin/bash -lx

ecflow_info()
{
    echo "$2"
    ecflow_client --label="$1" "$2" > /dev/null 2>&1
}

preproc()
{
    local HH="$1"
    local GRID="$2"
    local IPROG="$3"
    local FPROG="$4"
    local DATE="$5"

    local WORKDIR="${OPERACIONAL_DIR}/${GRID_DIR[$GRID]}/data"
    local INDIR="${WORKDIR}/inputdata${HH}"
    local DATADIR="${WORKDIR}/inputdataready${HH}"
    local DATETIME="${DATE}${HH}"

    [ "${IPROG}" = "default" ] && IPROG=0
    [ "${FPROG}" = "default" ] && FPROG="${GRID_FPROG[$GRID]}"

    cd "${DATADIR}" || return 22

    local SLEEP=30
    local MAX=720

    # Check icon_new
    for ((i=1; i<=MAX; i++)); do

        ecflow_info Info1 "Verificando icon_new para ${GRID}: ${DATETIME}..."
        ecflow_info Info2 "Data/Hora: $(date)"

        cp -f "${INDIR}/icon_new.bz2" .
        bunzip2 -f icon_new.bz2

        if [ "$(head -1 icon_new)$(head -2 icon_new | tail -1)" = "${DATETIME}" ]; then
            echo "$(date) - The data reception has already started" > "ICONDATA_${DATETIME}"
            break
        fi

        rm -f icon_new
        sleep "${SLEEP}"

    done

    if [ "${i}" -gt "${MAX}" ]; then
        ecflow_info Info1 "ERROR! Esperei o arquivo icon_new por 6 horas."
        ecflow_info Info2 "Script abortado em: $(date)"
        return 22
    fi

    # Process forecast files
    for ((prog=IPROG; prog<=FPROG; prog+=3)); do

        ecflow_info Info1 "Iniciando pre-processamento do prog ${prog}..."
        ecflow_info Info2 "Data/Hora: $(date)"
        ecflow_client --meter=progress "${prog}" > /dev/null 2>&1

        FILEN=$(printf "igfff%02d%02d0000" $((prog / 24)) $((prog % 24)))
        FLAG="${DATADIR}/${FILEN}_${DATE}_OK"

        for ((i=1; i<=MAX; i++)); do

            if [ -f "${FLAG}" ]; then

                if [ "${FILEN}" = "igfff00000000" ]; then
                    ecflow_info Info1 "Executando ICONREMAP para condição inicial ${FILEN}..."
                    "${SCRIPTS_DIR}/04.1_create_initcond_iconlam.sh" "${HH}" "${GRID}" || return 22
                fi

                ecflow_info Info1 "Executando ICONSUB/ICONREMAP para condição de contorno ${FILEN}..."
                "${SCRIPTS_DIR}/04.2_create_latbc_iconlam.sh" "${HH}" "${GRID}" "${FILEN}" || return 22

                break
            fi

            if [ -f "${INDIR}/${FILEN}.bz2" ]; then

                cp -f "${INDIR}/${FILEN}.bz2" "${DATADIR}/"
                bunzip2 -f "${DATADIR}/${FILEN}.bz2"

                REFDATE=$(grib_ls -p dataDate "${DATADIR}/${FILEN}" |
                    head -3 | tail -1 | xargs)

                if [ "${REFDATE}" = "${DATE}" ]; then
                    touch "${FLAG}"
                else
                    rm -f "${DATADIR}/${FILEN}"
                fi
            fi

        done

        if [ "${i}" -gt "${MAX}" ]; then
            ecflow_info Info1 "ERROR! Esperei o arquivo ${FILEN} por 6 horas."
            ecflow_info Info2 "Script abortado em: $(date)"
            return 22
        fi

    done
}

# ============================================================
# Main
# ============================================================

if [ $# -ne 1 ] && [ $# -ne 2 ] && [ $# -ne 4 ] && [ $# -ne 5 ]; then
    ecflow_info Info1 "FATAL ERROR! Número de argumentos inválido: esperado 1, 2, 4 ou 5; recebido $#."
    ecflow_info Info2 "Uso 1: $0 <HH>"
    ecflow_info Info3 "       Exemplo: $0 00"
    ecflow_info Info4 "Uso 2: $0 <HH> <GRID>"
    ecflow_info Info5 "       Exemplo: $0 00 sam"
    ecflow_info Info6 "Uso 3: $0 <HH> <GRID> <IPROG> <FPROG> [DATE]"
    ecflow_info Info7 "       Exemplo: $0 00 sam 0 120 20260902"
    ecflow_info Info8 "Script abortado em: $(date)"
    exit 11
fi

HH="$1"

if [[ ! "${HH}" =~ ^(00|12)$ ]]; then
    ecflow_info Info1 "FATAL ERROR! Rodada inválida: ${HH}."
    ecflow_info Info2 "Script abortado em: $(date)"
    exit 11
fi

DATE="${5:-$(<"${DATES_DIR}/currentdate${HH}")}"

# ------------------------------------------------------------
# HH only
# ------------------------------------------------------------

if [ $# -eq 1 ]; then

    for GRID in $(<"${SCRIPTS_DIR}/runlist"); do
        preproc "${HH}" "${GRID}" default default "${DATE}" || exit $?
    done

# ------------------------------------------------------------
# HH + GRID
# ------------------------------------------------------------

elif [ $# -eq 2 ]; then

    GRID="$2"

    if [ -z "${GRID_DIR[$GRID]+x}" ]; then
        ecflow_info Info1 "FATAL ERROR! Domínio inválido: ${GRID}."
        ecflow_info Info2 "Script abortado em: $(date)"
        exit 22
    fi

    preproc "${HH}" "${GRID}" default default "${DATE}" || exit $?

# ------------------------------------------------------------
# HH + GRID + IPROG + FPROG [+ DATE]
# ------------------------------------------------------------

else

    GRID="$2"
    IPROG="$3"
    FPROG="$4"

    if [ -z "${GRID_DIR[$GRID]+x}" ]; then
        ecflow_info Info1 "FATAL ERROR! Domínio inválido: ${GRID}."
        ecflow_info Info2 "Script abortado em: $(date)"
        exit 22
    fi

    preproc "${HH}" "${GRID}" "${IPROG}" "${FPROG}" "${DATE}" || exit $?

fi

ecflow_info Info1 "OK. Processo finalizado com sucesso!"
ecflow_info Info2 "Terminou em: $(date)"

ecflow_client --event PreProc_SAFO > /dev/null 2>&1
