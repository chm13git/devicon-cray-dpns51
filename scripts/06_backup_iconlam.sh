#!/bin/bash -l

############################################################
# Script to compress the ICONLAM data and save it to backup.
# Author: CT(T) Neris
############################################################

backup_iconlam()
{
    local HH="$1"
    local GRID="$2"
    local DATE="$3"
    local DOMAIN="${GRID_DIR[$GRID]}"
    local OUTDIR="${GRID_OUTPUTDATA_DIR[$GRID]}${HH}"
    local BKPDIR="${GRID_BACKUP_DIR[$GRID]}"
    local FILEPRE="iconlam_${DOMAIN}_${HH}"
    local FINALPROG="${GRID_FPROG[$GRID]}"
    local PROG_INT="${GRID_PROG_INT[$GRID]}"
    local MIN_GRIB="${GRID_BACKUP_MIN_GRIB[$GRID]}"
    local MIN_VRFML="${GRID_BACKUP_MIN_VRF_ML[$GRID]}"
    local MIN_VRFPL="${GRID_BACKUP_MIN_VRF_PL[$GRID]}"
    local MIN_VRF="${GRID_BACKUP_MIN_VRF[$GRID]}"
    local MIN_WAVE="${GRID_BACKUP_MIN_WAVE[$GRID]}"
    local MIN_WAVE_PS="${GRID_BACKUP_MIN_WAVE_PS[$GRID]}"
    local NMAX=720
    local SLEEP_TIME=30
    local REFNUMFILES
    local RSYNC_BKPDIR
    local ATTEMPT=1

    REFNUMFILES=$(( (FINALPROG / PROG_INT + 1) * 2 ))
    RSYNC_BKPDIR="${BACKUP_RSYNC_HOST}:${BKPDIR}"

    # --------------------------------------------------------
    # Check pbzip2
    # --------------------------------------------------------
    if [ ! -x "${PBZIP2}" ]; then
        ecflow_info \
            "ERROR: pbzip2 não encontrado ou não executável: ${PBZIP2}"
        return 1
    fi

    echo
    echo "Running BACKUP for ${GRID} grid, ${HH} run, date ${DATE}..."
    echo "Output directory: ${OUTDIR}"
    echo "Backup directory: ${BKPDIR}"
    echo
    echo "Entering ${OUTDIR}..."

    cd "${OUTDIR}" || {
        ecflow_info \
            "ERROR: Não foi possível acessar o diretório de saída: ${OUTDIR}"
        return 1
    }

    while [ "${ATTEMPT}" -le "${NMAX}" ]; do

        echo
        echo "============================================================"
        echo "Checking ICONLAM output files..."
        echo "Cycle ${ATTEMPT} of ${NMAX}"
        echo "============================================================"

        ecflow_info \
            "Checando arquivos de backup - ciclo ${ATTEMPT}/${NMAX}."

        # =====================================================
        # VRF
        # =====================================================
        local VRFML="iconlam_${GRID}_${HH}_${DATE}_vrf_ml.nc"
        local VRFPL="iconlam_${GRID}_${HH}_${DATE}_vrf_pl.nc"
        local VRF="${FILEPRE}_${DATE}_vrf.nc"
        local VRFTEMP="${VRF}.temp"

        echo
        echo "---------------- VRF ----------------"

        if check_file_size \
            "${OUTDIR}/${VRF}" \
            "${MIN_VRF}" \
            ge \
            "VRF final já existente"; then

            :

        elif check_file_size \
            "${OUTDIR}/${VRFML}" \
            "${MIN_VRFML}" \
            ge \
            "VRF ML pronto" &&
             check_file_size \
            "${OUTDIR}/${VRFPL}" \
            "${MIN_VRFPL}" \
            ge \
            "VRF PL pronto"; then

            ecflow_info \
                "VRF ML e PL atendem aos critérios. Fazendo merge..."

            cp -f "${OUTDIR}/${VRFML}" "${OUTDIR}/${VRFTEMP}"

            if ncks -A "${OUTDIR}/${VRFPL}" "${OUTDIR}/${VRFTEMP}"; then

                if check_file_size \
                    "${OUTDIR}/${VRFTEMP}" \
                    "${MIN_VRF}" \
                    ge \
                    "VRF temporário após merge"; then

                    mv "${OUTDIR}/${VRFTEMP}" "${OUTDIR}/${VRF}"

                    ecflow_info \
                        "OK: Merge dos arquivos VRF concluído com sucesso."

                    ecflow_event Backup_SAFO

                else
                    ecflow_info \
                        "WARNING: VRF temporário após merge não atingiu o tamanho mínimo."

                    rm -f "${OUTDIR}/${VRFTEMP}"
                fi

            else
                ecflow_info \
                    "WARNING: ncks falhou durante o merge dos arquivos VRF."

                rm -f "${OUTDIR}/${VRFTEMP}"
            fi

        else
            ecflow_info \
                "WAIT: Arquivos VRF ML/PL ainda não atendem aos critérios."
        fi


        # =====================================================
        # Atmospheric GRIB backup
        # =====================================================
        local NUMFILES
        local ATM_ARCHIVE="${FILEPRE}_${DATE}.tar.bz2"

        NUMFILES=$(find "${OUTDIR}" -maxdepth 1 -type f \
            -name "${FILEPRE}_${DATE}_???_??.grb" | wc -l)

        echo
        echo "---------------- Atmospheric GRIB ----------------"

        if check_remote_file_size \
            "${BKPDIR}/${ATM_ARCHIVE}" \
            "${MIN_GRIB}" \
            gt \
            "Backup atmosférico já existente"; then

            :

        else
            ecflow_info \
                "GRIB atmosféricos: ${NUMFILES} arquivos encontrados; ${REFNUMFILES} esperados."

            if [ "${NUMFILES}" -eq "${REFNUMFILES}" ]; then

                ecflow_info \
                    "OK: Quantidade de arquivos GRIB atende ao esperado."

                ecflow_info \
                    "Iniciando compressão e sincronização."

                ecflow_info \
                    "Comprimindo ${NUMFILES} arquivos GRIB."

                tar --use-compress-program="${PBZIP2}" \
                    -cf "${OUTDIR}/${ATM_ARCHIVE}" \
                    -C "${OUTDIR}" \
                    "${FILEPRE}_${DATE}"_???_??.grb

                rsync -av \
                    "${OUTDIR}/${ATM_ARCHIVE}" \
                    "${RSYNC_BKPDIR}/"

                if check_remote_file_size \
                    "${BKPDIR}/${ATM_ARCHIVE}" \
                    "${MIN_GRIB}" \
                    gt \
                    "Backup atmosférico após sincronização"; then

                    ecflow_info \
                        "OK: Backup atmosférico concluído com sucesso."

                    ecflow_event Backup_SAFO

                else
                    ecflow_info \
                        "WARNING: Verificação do backup atmosférico falhou."
                fi

            else
                ecflow_info \
                    "WAIT: Quantidade de arquivos GRIB ainda não está completa. Encontrados: ${NUMFILES}. Esperados: ${REFNUMFILES}."
            fi
        fi


        # =====================================================
        # Delft / wave backup
        # =====================================================
        if [ "${GRID_HAS_WAVE[$GRID]}" -eq 1 ]; then

            local WAVE="iconlam_${GRID}_${HH}_${DATE}_delft.nc"
            local WAVE_ARCHIVE="${FILEPRE}_wave_${DATE}.tar.bz2"

            echo
            echo "---------------- Delft / Wave ----------------"

            if [ "${GRID_HAS_WAVE_PS[$GRID]}" -eq 1 ]; then

                local WAVE_PS="iconlam_${GRID}_${HH}_${DATE}_delft_ps.nc"
                local WAVE_PS_ARCHIVE="${FILEPRE}_wave_ps_${DATE}.tar.bz2"

                if check_remote_file_size \
                    "${BKPDIR}/${WAVE_ARCHIVE}" \
                    "${MIN_WAVE}" \
                    gt \
                    "Backup Wave já existente" &&
                   check_remote_file_size \
                    "${BKPDIR}/${WAVE_PS_ARCHIVE}" \
                    "${MIN_WAVE_PS}" \
                    gt \
                    "Backup Wave PS já existente"; then

                    ecflow_event Backup_SAFO

                elif check_file_size \
                    "${OUTDIR}/${WAVE}" \
                    1 \
                    ge \
                    "Arquivo Wave de entrada" &&
                     check_file_size \
                    "${OUTDIR}/${WAVE_PS}" \
                    1 \
                    ge \
                    "Arquivo Wave PS de entrada"; then

                    ecflow_info \
                        "Wave e Wave PS encontrados. Comprimindo e sincronizando..."

                    tar --use-compress-program="${PBZIP2}" \
                        -cf "${OUTDIR}/${WAVE_ARCHIVE}" \
                        -C "${OUTDIR}" \
                        "${WAVE}"

                    tar --use-compress-program="${PBZIP2}" \
                        -cf "${OUTDIR}/${WAVE_PS_ARCHIVE}" \
                        -C "${OUTDIR}" \
                        "${WAVE_PS}"

                    rsync -av \
                        "${OUTDIR}/${WAVE_ARCHIVE}" \
                        "${OUTDIR}/${WAVE_PS_ARCHIVE}" \
                        "${RSYNC_BKPDIR}/"

                    if check_remote_file_size \
                        "${BKPDIR}/${WAVE_ARCHIVE}" \
                        "${MIN_WAVE}" \
                        gt \
                        "Backup Wave após sincronização" &&
                       check_remote_file_size \
                        "${BKPDIR}/${WAVE_PS_ARCHIVE}" \
                        "${MIN_WAVE_PS}" \
                        gt \
                        "Backup Wave PS após sincronização"; then

                        ecflow_info \
                            "OK: Backup Wave concluído com sucesso."

                        ecflow_event Backup_SAFO
                    fi
                fi

            elif check_remote_file_size \
                "${BKPDIR}/${WAVE_ARCHIVE}" \
                "${MIN_WAVE}" \
                gt \
                "Backup Wave já existente"; then

                ecflow_event Backup_SAFO

            elif check_file_size \
                "${OUTDIR}/${WAVE}" \
                1 \
                ge \
                "Arquivo Wave de entrada"; then

                ecflow_info \
                    "Arquivo Wave encontrado. Comprimindo e sincronizando..."

                tar --use-compress-program="${PBZIP2}" \
                    -cf "${OUTDIR}/${WAVE_ARCHIVE}" \
                    -C "${OUTDIR}" \
                    "${WAVE}"

                rsync -av \
                    "${OUTDIR}/${WAVE_ARCHIVE}" \
                    "${RSYNC_BKPDIR}/"

                if check_remote_file_size \
                    "${BKPDIR}/${WAVE_ARCHIVE}" \
                    "${MIN_WAVE}" \
                    gt \
                    "Backup Wave após sincronização"; then

                    ecflow_info \
                        "OK: Backup Wave concluído com sucesso."

                    ecflow_event Backup_SAFO
                fi
            fi
        fi


        # =====================================================
        # Final verification
        # =====================================================
        local ATM_OK=0
        local VRF_OK=0
        local WAVE_OK=1

        echo
        echo "---------------- Final verification ----------------"

        if check_remote_file_size \
            "${BKPDIR}/${ATM_ARCHIVE}" \
            "${MIN_GRIB}" \
            gt \
            "Verificação final do backup atmosférico"; then

            ATM_OK=1
        fi

        if check_file_size \
            "${OUTDIR}/${VRF}" \
            "${MIN_VRF}" \
            ge \
            "Verificação final do VRF"; then

            VRF_OK=1
        fi

        if [ "${GRID_HAS_WAVE[$GRID]}" -eq 1 ]; then

            WAVE_OK=0

            if [ "${GRID_HAS_WAVE_PS[$GRID]}" -eq 1 ]; then

                if check_remote_file_size \
                    "${BKPDIR}/${WAVE_ARCHIVE}" \
                    "${MIN_WAVE}" \
                    gt \
                    "Verificação final do backup Wave" &&
                   check_remote_file_size \
                    "${BKPDIR}/${WAVE_PS_ARCHIVE}" \
                    "${MIN_WAVE_PS}" \
                    gt \
                    "Verificação final do backup Wave PS"; then

                    WAVE_OK=1
                fi

            elif check_remote_file_size \
                "${BKPDIR}/${WAVE_ARCHIVE}" \
                "${MIN_WAVE}" \
                gt \
                "Verificação final do backup Wave"; then

                WAVE_OK=1
            fi
        fi


        # =====================================================
        # Backup completed
        # =====================================================
        if [ "${ATM_OK}" -eq 1 ] &&
           [ "${VRF_OK}" -eq 1 ] &&
           [ "${WAVE_OK}" -eq 1 ]; then

            echo
            echo "============================================================"
            echo "ICONLAM BACKUP completed successfully!"
            echo "============================================================"

            ecflow_info \
                "OK: Backup feito com sucesso!"

            ecflow_event Backup_SAFO

            return 0
        fi

        sleep "${SLEEP_TIME}"
        ATTEMPT=$((ATTEMPT + 1))
    done


    # =========================================================
    # Timeout
    # =========================================================
    echo
    echo "ERROR: waited 6 hours but backup files were not ready."
    echo "Aborting script..."

    ecflow_info \
        "FATAL ERROR: Esperei por 6 horas mas não encontrei os arquivos."

    return 2
}


# ============================================================
# Main
# ============================================================

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "Usage: $0 HH GRID [YYYYMMDD]"
    echo
    echo "Examples:"
    echo "  $0 00 sam"
    echo "  $0 00 sam 20260929"
    exit 11
fi

HH="$1"
GRID="$2"
DATE="${3:-$(<"${DATES_DIR}/currentdate${HH}")}"

if [ -z "${GRID_DIR[$GRID]+x}" ]; then
    echo "ERROR: Invalid grid '${GRID}'."
    echo "Valid grids: sam sse ant pen"
    exit 22
fi

echo
echo "Running BACKUP for:"
echo "  HH   : ${HH}"
echo "  GRID : ${GRID}"
echo "  DATE : ${DATE}"
echo

date
time backup_iconlam "${HH}" "${GRID}" "${DATE}"
RET=$?
date

echo "End of ICONLAM BACKUP script 06!"
exit "${RET}"
