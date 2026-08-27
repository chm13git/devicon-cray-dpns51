#!/bin/bash
#
# Script to delete old iconlam run files
#
# Author: CT Neris
#
#-------------------------------------------------------
# Activating ecflow env
conda activate ecflow

# Function Section

deloldfiles(){

HH=$1
GRID=$2
RUNTYPE=$3

# Setting workdir for each area.
case $GRID in
	sam)
	WORKDIR="/home/opicon/operacional/sam6.5/data"
;;
	sse)
	WORKDIR="/home/opicon/operacional/sse2.1/data"
;;
	ant)
	WORKDIR="/home/opicon/operacional/ant6.5/data"
;;
	pen)
	WORKDIR="/home/opicon/operacional/pen2.1/data"
;;
	*)
	msg="FATAL ERROR. Entre com um domínio válido (sam, sse, ant, pen)."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Script abortado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo " ERROR! Invalid grid name!"
	exit 12
;;
esac

# Deleting old files depending on the runtype
if [ $RUNTYPE == 'ope' ];then
    msg="Deletando arquivos em ${WORKDIR} OPERACIONAL."
    ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    msg="Iniciado em: $(date)"
    ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

    rm -f ${WORKDIR}/inputdataready${HH}/ICON*
    rm -f ${WORKDIR}/inputdataready${HH}/igf*
    rm -f ${WORKDIR}/inputdataready${HH}/raw*
    rm -f ${WORKDIR}/outputdata${HH}/out*
    rm -f ${WORKDIR}/outputdata${HH}/nml*
    rm -f ${WORKDIR}/outputdata${HH}/NAMELIST*
    rm -f ${WORKDIR}/outputdata${HH}/icon*
    rm -f ${WORKDIR}/outputdata${HH}/finish*
    rm -f ${WORKDIR}/outputdata${HH}/RUN*
    rm -f ${WORKDIR}/initialcond${HH}/igfff*
    rm -f ${WORKDIR}/initialcond${HH}/lateral*
else # entra aqui se RUNTYPE =! ope, ex.: exp
    msg="Deletando arquivos em ${WORKDIR} EXPERIMENTAL."
    ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    msg="Iniciado em: $(date)"
    ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

    rm -f ${WORKDIR}/exprun_inputdata${HH}/i*
    rm -f ${WORKDIR}/exprun_inputdataready${HH}/ICON*
    rm -f ${WORKDIR}/exprun_inputdataready${HH}/igf*
    rm -f ${WORKDIR}/exprun_inputdataready${HH}/raw*
    rm -f ${WORKDIR}/exprun_outputdata${HH}/out*
    rm -f ${WORKDIR}/exprun_outputdata${HH}/nml*
    rm -f ${WORKDIR}/exprun_outputdata${HH}/NAMELIST*
    rm -f ${WORKDIR}/exprun_outputdata${HH}/icon*
    rm -f ${WORKDIR}/exprun_outputdata${HH}/finish*
    rm -f ${WORKDIR}/exprun_outputdata${HH}/RUN*
    rm -f ${WORKDIR}/exprun_initialcond${HH}/igfff*
    rm -f ${WORKDIR}/exprun_initialcond${HH}/lateral*
fi
}

# End of Function Section
# ----------------------------------------------------------------------


if [ $# -ne 1 ] && [ $# -ne 2 ] && [ $# -ne 3 ] ;then
	echo " Enter the run (00, 12), the grid (sam, sse, ant, pen) and/or the mode (ope, exp)."
	echo
	echo "Ex.: $0 00"
	echo ou
	echo "Ex.: $0 00 sam"
	echo or
        echo "Ex.: $0 00 sam exp"
	msg="FATAL ERROR. Entre com a rodada (00, 12), o domínio (sam, sse, ant, pen) e o modo (ope, exp)."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Script abortado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	exit 11
fi

HH=$1
GRID=$2
RUNTYPE=$3

# Running script for each case
if [ -z $GRID ] && [ -z $RUNTYPE ];then

	gridslist=`cat ~/operacional/scripts/runlist`
	msg="Executando script para a lista: $gridslist..."
	ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
     	msg="O processo iniciou em: $(date)"
     	ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo Running script for list: $gridslist...
        echo

	runtype='ope'
	for grid in $gridslist; do
		msg="Executando script para $HH, domínio $grid e modo $runtype..."
		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
		msg="O processo iniciou em: $(date)"
		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

		echo echo Running script for $HH, $grid grid and runtype $runtype...
		echo
		deloldfiles $HH $grid $runtype
	done
elif [ -z $RUNTYPE ];then
	runtype='ope'
	msg="Executando script para $HH, domínio $GRID e modo $runtype..."
	ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
	msg="O processo iniciou em: $(date)"
	ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

        echo Running script for $HH, $GRID grid and runtype $runtype...
	echo
        deloldfiles $HH $GRID $runtype
else
	msg="Executando script para $HH, domínio $GRID e modo $RUNTYPE..."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="O processo iniciou em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo Running script for $HH, $GRID grid and runtype $RUNTYPE...
        echo
        deloldfiles $HH $GRID $RUNTYPE
fi

if [ $? -eq 0 ]; then
	msg="Processo finalizado com success!"
	ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
	msg="Finalizado em: $(date)"
	ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	ecflow_client --event DeletaAntigos_SAFO
else
	msg="WARNING! Processo finalizado com erros!"
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Finalizado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
fi
