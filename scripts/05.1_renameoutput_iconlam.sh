#!/bin/bash -l
#
# Script para modificar os nomes dos arquivos de previsão
# de todas as áreas do modelo ICON-LAM.
#
# Autor: CT(T) Neris

# ----------------------------------------------------------------------
# Arguments
# ----------------------------------------------------------------------
if [ $# -ne 2 ] && [ $# -ne 4 ] && [ $# -ne 5 ]; then
    echo "Usage:"
    echo "  $0 HH AREA"
    echo "  $0 HH AREA HSTART HSTOP"
    echo "  $0 HH AREA HSTART HSTOP DATE"
    echo
    echo "Ex.: $0 00 sam"
    echo "Ex.: $0 00 sam 48 96"
    echo "Ex.: $0 00 sam 48 96 20260929"
    echo
    msg="FATAL ERROR! Número de argumentos inválido."
    ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    msg="Script abortado em: $(date)"
    ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
    exit 11
fi

HH="$1"
AREA="$2"
HSTART="${3:-}"
HSTOP="${4:-}"
DATE="${5:-}"

# ----------------------------------------------------------------------
# Forecast range and date
# ----------------------------------------------------------------------
if [ -z "${HSTART}" ] && [ -z "${HSTOP}" ]; then
    HSTART=0
    HSTOP="${GRID_FPROG[$AREA]}"
    echo
    echo "Using default hstart/hstop = ${HSTART}/${HSTOP}"
    echo
elif [ -z "${HSTART}" ] || [ -z "${HSTOP}" ]; then
    echo "ERROR! HSTART and HSTOP must be supplied together."
    exit 13
else
    echo
    echo "Using hstart/hstop passed by user = ${HSTART}/${HSTOP}"
    echo
fi

if [ -z "${DATE}" ]; then
    CURRDATE="$(cat "${DATES_DIR}/currentdate${HH}")"
else
    CURRDATE="${DATE}"
fi

# ----------------------------------------------------------------------
# Grid parameters
# ----------------------------------------------------------------------
DOMAIN="${GRID_DIR[$AREA]}"
PROG_INT="${GRID_PROG_INT[$AREA]}"
NVARML="${GRID_NVARML[$AREA]}"
NVARPL="${GRID_NVARPL[$AREA]}"

# ----------------------------------------------------------------------
# Common parameters
# ----------------------------------------------------------------------
NMAX=720
SLTIME=30

# ----------------------------------------------------------------------
# Output directory
# ----------------------------------------------------------------------
OUTDIR="${GRID_OUTPUTDATA_DIR[$AREA]}${HH}"

# ----------------------------------------------------------------------
# Loop for renaming files
# ----------------------------------------------------------------------
INUM=$((HSTART / PROG_INT + 1))
FNUM=$((HSTOP / PROG_INT + 1))

for NUM in $(seq "${INUM}" "${FNUM}"); do
    NUMGRB=$(printf "%04d" "${NUM}")
    PROG=$((NUM * PROG_INT - PROG_INT))
    NUMPROG=$(printf "%03d" "${PROG}")
    NUMPROG2=$(printf "%02d" "${PROG}")
    RESTOPROG=$((PROG % 24))

    MLFILE="${OUTDIR}/iconlam_${AREA}_${HH}_${CURRDATE}_${NUMGRB}_ml.grb"
    NMLFILE="${OUTDIR}/iconlam_${DOMAIN}_${HH}_${CURRDATE}_${NUMPROG}_ml.grb"
    PLFILE="${OUTDIR}/iconlam_${AREA}_${HH}_${CURRDATE}_${NUMGRB}_pl.grb"
    NPLFILE="${OUTDIR}/iconlam_${DOMAIN}_${HH}_${CURRDATE}_${NUMPROG}_pl.grb"

    NUMNC=$(printf "%04d" "$((PROG / 24))")
    UVFILE="${OUTDIR}/iconlam_${AREA}_${HH}_${CURRDATE}_${NUMNC}_uv.nc"
    NUVFILE="${OUTDIR}/iconlam_uv_${CURRDATE}${HH}_${NUMPROG2}.nc"

    NATTEMPTS=1
    NATTEMPTSUV=1
    FLAG=1
    FLAGUV=1

    while [ "${FLAG}" -eq 1 ] || [ "${FLAGUV}" -eq 1 ]; do
        msg="Renomeando prog ${NUMPROG}..."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1

        msg="Data/Hora: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

        ecflow_client --meter=progress "${NUMPROG}"

        # Check ML and PL files
        if [ -s "${MLFILE}" ] && \
           [ "$(grib_count "${MLFILE}")" -eq "${NVARML}" ] && \
           [ -s "${PLFILE}" ] && \
           [ "$(grib_count "${PLFILE}")" -eq "${NVARPL}" ]; then

            echo "OK, ML and PL files found with correct number of variables!"
            echo "Renaming prog ${NUMPROG}h..."
            echo

            msg="OK. Arqs ML e PL de ${NUMPROG} com número correto de vars"
            ecflow_client --label=Info1 "$msg" > /dev/null 2>&1

            msg="Data/Hora: $(date)"
            ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

            mv "${MLFILE}" "${NMLFILE}"
            mv "${PLFILE}" "${NPLFILE}"

            FLAG=0

        elif [ -s "${NMLFILE}" ] && [ -s "${NPLFILE}" ]; then
            echo "ALL DONE! ML and PL files have already been renamed for prog ${NUMPROG}h!"
            echo
            FLAG=0

        else
            NATTEMPTS=$((NATTEMPTS + 1))

            echo
            echo "Info: File(s) are not ready yet. Waiting ${SLTIME}s..."
            echo "Cycle ${NATTEMPTS} of ${NMAX}"
            echo
            echo "Please, check them:"
            echo "${MLFILE}"
            echo "${PLFILE}"
            echo

            msg="Info. Arqs ML e PL de ${NUMPROG} NÃO encontrado ou com número errado de vars"
            ecflow_client --label=Info1 "$msg" > /dev/null 2>&1

            msg="Data/Hora: $(date)"
            ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

            sleep "${SLTIME}"
            FLAG=1
        fi

        # Check UV file
        if [ "${RESTOPROG}" -eq 0 ] && \
           [ "${NUM}" -gt 1 ] && \
           [ "${AREA}" = "sam" ]; then

            if [ -s "${UVFILE}" ]; then
                echo "OK, UV file found and complete!"
                echo "Renaming prog ${NUMPROG2}h..."
                echo

                mv "${UVFILE}" "${NUVFILE}"
                FLAGUV=0

            elif [ -s "${NUVFILE}" ]; then
                echo "ALL DONE! NC file has already been renamed for prog ${NUMPROG2}h!"
                echo
                FLAGUV=0

            else
                NATTEMPTSUV=$((NATTEMPTSUV + 1))

                echo "Info: File NC not ready yet. Waiting ${SLTIME}s..."
                echo "Please, check it out:"
                echo "${UVFILE}"
                echo

                sleep "${SLTIME}"
                FLAGUV=1
            fi

        else
            echo "Skipping UV file for grid ${DOMAIN} and prog ${NUMPROG2}h..."
            echo
            FLAGUV=0
        fi

        # Abort if files take more than 6 hours to arrive
        if [ "${NATTEMPTS}" -gt "${NMAX}" ] || \
           [ "${NATTEMPTSUV}" -gt "${NMAX}" ]; then
            echo "05.1 Rename script ERROR!"
            echo "Waited for 6 hours but the file did not arrive."
            echo "Aborting script..."
            exit 777
        fi
    done
done
