#!/bin/bash
#
# Script for checking if each icon input file is of current date
# and generating initial and latbc conditions for ICONLAM
#
# Author: CT(T) Neris
#
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Activating ecflow env
conda activate ecflow

GribLs='/home/devicon/intel2020.4_install/build/eccodes-2.30.2-Source/bin/grib_ls'
# ----------------------------------------------------------------------
# Function Section

preproc(){

HH=$1
GRID=$2
IPROG=$3
FPROG=$4
DATE=$5
RUNTYPE=$6

# ----------------------------------------------------------------------
# Loading date args and scripts path
echo "Loading current date info..."
currdate=$DATE
datetimeana=${currdate}${HH}

# ----------------------------------------------------------------------
# Step 2 - Defining grid specifics vars
case $GRID in
	sam)
        workdir="/home/opicon/operacional/sam6.5/data"
        if [ $IPROG = "default" ]; then
                IPROG=0
                FPROG=120
        fi
        ;;
        sse)
        workdir="/home/opicon/operacional/sse2.1/data"
        if [ $IPROG = "default" ]; then
                IPROG=0
                FPROG=48
        fi
        ;;
        ant)
        workdir="/home/opicon/operacional/ant6.5/data"
        if [ $IPROG = "default" ]; then
                IPROG=0
                FPROG=120
        fi
        ;;
        pen)
        workdir="/home/opicon/operacional/pen2.1/data"
        if [ $IPROG = "default" ]; then
                IPROG=0
                FPROG=48
        fi
        ;;
        *)
	msg="FATAL ERROR. Domínio inválido. Entre com sam, sse, ant ou pen."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Script abortado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

        echo Error! Modelo não cadastrado!
        echo Entre com sam, sse, ant ou pen.
        exit 22
        ;;
esac

# I/O Dirs depend on workdir var, defined in the CASE above.
if [ $RUNTYPE = "ope" ];then
	indir="$workdir/inputdata${HH}"
	datadir="$workdir/inputdataready$HH"
else
	datadir="$workdir/exprun_inputdataready$HH"

	if [ $DATE == `cat $DATES_DIR/currentdate${HH}` ];then
		indir="$workdir/inputdata${HH}"

		msg="Modo EXP. Vou usar os dados operacionais em $indir..."
                ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
                msg="Data/Hora: $(date)"
                ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	else
		indir="$workdir/exprun_inputdata${HH}"

		msg="Modo EXP. Desagrupando arq icon4iconlam${GRID}_${DATE}${HH}.tar.bz2 em $indir..."
                ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
                msg="Data/Hora: $(date)"
                ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

		echo "Untarring file from archive to $indir in background..."
		if [[ $GRID == "sam" || $GRID == "sse" ]]; then
		    tar -xvf $BKP_DIR/bkp_input_icon4iconlam_sam/icon4iconlamsam_${DATE}${HH}.tar.bz2 -C $indir/ &
		else
		    tar -xvf $BKP_DIR/bkp_input_icon4iconlam_ant/icon4iconlamant_${DATE}${HH}.tar.bz2 -C $indir/ &
		fi

	fi
fi

echo "Initiating script 04..."
date

# ----------------------------------------------------------------------
# Step 3 -  Checking if the data is current

cd ${datadir}

nmax_attempt=720 # 720 cycles of 30s, i.e., 6hrs
sleeptime=30
horas_espera=$(( nmax_attempt * sleeptime / 3600 ))

# Checking icon_new
attempt=1
FLAG=1

while [ $FLAG -eq 1 ]; do

	msg="VRF se ${datadir}/icon_new é do dia e rodadas corretos: ${datetimeana}..."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="O processo iniciou em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo Checking if ${datadir}/icon_new date/run is ${datetimeana}...

	# Copying initial file to local dir
	cp -f ${indir}/icon_new.bz2 ${datadir}/

	# Checking if the data is of current date
	bunzip2 -f icon_new.bz2
	dataf=`head -1 icon_new`
	run=`head -2 icon_new | tail -1`

	if [ ${dataf}${run} == ${datetimeana} ];then
		msg="A recepção de dados já começou."
	        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
	        msg="O processo iniciou em: $(date)"
	        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

		echo The data reception has already started.
		echo Proceeding to initial/boundary data check...
		echo `date` - The data reception has already started > ${datadir}/ICONDATA_${datetimeana}
		FLAG=0
	else
		msg="WARNING! Data e rodada de referência incorreta."
                ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
		msg="Deletando arquivo ${datadir}/icon_new e esperando ${sleeptime}s to try again... ($(date))"
                ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

		echo "Reference date/run is incorrect!"
		echo "Deleting incorrect file in ${datadir}..."
		rm -f ${datadir}/icon_new
		echo "Waiting ${sleeptime}s to try again..."
		sleep ${sleeptime}
		attempt=`expr $attempt + 1`
	fi

	if [ $attempt -gt $nmax_attempt ]; then
		msg="ERROR! Esperei o arquivo icon_new por $horas_espera horas."
                ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
                msg="Script abortado em: $(date)"
                ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

		echo "ERROR! icon_new check for $GRID aborted after $horas_espera hours!!!!"
	fi
done


### Checking initial/boundary data
if [ $FLAG -eq 1 ] ; then
	msg="Como o arquivo icon_new para o domínio $GRID não chegou, \
		vou pular para o próximo da lista ou abortar."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Data/Hora: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo Since icon_new check for $GRID was unsuccessful, skipping loop for BC.
	echo I will try the next grid of the list gridslist now...

else

for prog in `seq $IPROG 3 $FPROG` ; do # loop progs
	msg="Iniciando pre-processamento do prog $prog..."
	ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
	msg="Data/Hora: $(date)"
	ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	ecflow_client --meter=progress ${prog}

	attempt=1
	FLAG=1

	# Writting input file name
	dd=$(printf "%02d" `expr $prog / 24`) # sets 2 digs day
	hh=$(printf "%02d" `expr $prog % 24`) # sets 2 digs hour
	filen="igfff${dd}${hh}0000"

	while [ $FLAG -eq 1 ]; do # loop tries

		echo "Checking flag ${datadir}/${filen}_${currdate}_OK..."

		if [ -f ${datadir}/${filen}_${currdate}_OK ];then
			msg="Flag ${datadir}/${filen}_${currdate}_OK encontrada."
	                ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
	                msg="Procedendo para execução do preproc ($(date))"
	                ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

			echo "Flag ${datadir}/${filen}_${currdate}_OK found!"
			echo "Proceeding to running preproc..."
			FLAG=0

			# Running scripts
			if [ $filen == "igfff00000000" ];then
				msg="Executando ICONREMAP para arq de condição inicial $filen..."
			        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
			        msg="Data/Hora: $(date)"
			        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

				echo "Running iconremap for IC file $filen..."
				time ${scriptsdir}/04.1_create_initcond_iconlam.sh $HH $GRID $RUNTYPE # Test with "&"!!

				msg="Executando ICONSUB e ICONREMAP para condição de contorno $filen..."
			        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
			        msg="Data/Hora: $(date)"
			        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

				echo "Running iconsub and/or iconremap for LBC file $filen..."
				time ${scriptsdir}/04.2_create_latbc_iconlam.sh $HH $GRID ${filen} $RUNTYPE

			else
				msg="Executando somente ICONREMAP para condição de contorno $filen..."
			        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
			        msg="Data/Hora: $(date)"
			        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

				echo "Running ONLY iconremap for LBC file $filen..."
				time ${scriptsdir}/04.2_create_latbc_iconlam.sh $HH $GRID ${filen} $RUNTYPE
			fi
		else
			msg="VRF data de REF de $filen..."
			ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
			msg="Data/Hora: $(date)"
			ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

			echo "Checking the reference date of $filen..."

			cp -f $indir/${filen}.bz2 ${datadir}/
			/usr/bin/bunzip2 -f ${datadir}/${filen}.bz2
			input_refdate=`$GribLs -p dataDate ${datadir}/${filen} | head -3 | tail -1`

			if [ ${input_refdate} == ${currdate} ]; then
				msg="Arquivo $filen é atual e já foi copiado para ${datadir}."
			        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
			        msg="Criando flag ${datadir}/${filen}_${currdate}_OK. Data/Hora: $(date)"
			        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

				echo "File $filen is up-to-date and has already been copied to ${datadir}!"
				echo "Creating flag in ${datadir}/${filen}..."
				touch ${datadir}/${filen}_${currdate}_OK
			else
				msg="WARNING! Data de REF do arquivo $filen incorreta!"
			        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
			        msg="Deletando arquivo incorreto em ${datadir} e esperando ${sleeptime}s to try again... - Data/Hora: $(date)"
			        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

				echo "WARNING! Reference date is incorrect!"
				echo "Deleting incorrect file in ${datadir}..."
				rm ${datadir}/${filen}
				echo "Waiting ${sleeptime}s to try again..."
				sleep ${sleeptime}
				attempt=`expr $attempt + 1`
			fi

			if [ $attempt -gt $nmax_attempt ]; then
				msg="ERROR! Esperei o arquivo ${filen} por $horas_espera horas."
				ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
				msg="Script abortado em: $(date)"
		 		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

				echo "Check aborted after $horas_espera hours!!!!"
				exit 22
			fi
		fi

	done # loop tries

done # loop progs

fi # FLAG icon_new
}

# End of Function Section
# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------
# Setting up dirs
scriptsdir=$SCRIPTS_DIR
dates_dir=$DATES_DIR
bkp_dir=$BKP_DIR

# Step 1 - Retrieving parameters
if [ $# -ne 1 ] && [ $# -ne 4 ] && [ $# -ne 5 ] && [ $# -ne 6 ];then
	echo "Enter the run (00, 12), grid (sam, sse, ant, pen), initial and final prog!"
	echo "$0 00"
	echo or
	echo "$0 00 sam 00 120"
	echo or
	echo "$0 00 sam 00 120 20230330"
	echo or
	echo "$0 00 sam 00 120 20230330 exp"
	msg="FATAL ERROR! Núm de args inválido. Entre com a rodada (00, 12), e/ou domínio (sam, sse, ant, pen) \
		hstart (caso num args != 1), hstop (caso num args != 1), data (yyyymmdd) [opcional] \
		e o modo (ope, exp) [opcional]."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Script abortado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	exit 11
fi

HH=$1
GRID=$2
IPROG=$3
FPROG=$4
DATE=$5
RUNTYPE=$6

# Running ICON preproc for each case
if [ -z $GRID ] && [ -z $DATE ] && [ -z $RUNTYPE ]; then

	# Execution list
	gridslist=`cat $SCRIPTS_DIR/runlist`

	msg="Executando script para a lista: $gridslist..."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="O processo iniciou em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo ICONTOOLS will run for execution list: $gridslist...
	echo

	currdate=`cat $DATES_DIR/currentdate${HH}`
	runtype='ope'

	for grid in $gridslist; do
		msg="Executando preproc para $HH, domínio $grid, data $currdate e modo $runtype..."
                ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
                msg="O processo iniciou em: $(date)"
                ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

		echo Running preproc for $grid grid, date $currdate...
		echo $msg
		preproc $HH $grid default default $currdate $runtype # Change to meet forecast horizon!
	done
elif [ -z $DATE ] && [ -z $RUNTYPE ];then
	currdate=`cat $DATES_DIR/currentdate${HH}`
	runtype='ope'

	msg="Executando preproc para $HH, domínio $GRID, hstart $IPROG, hstop $FPROG, data $currdate \
		e modo $runtype..."
	ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
	msg="O processo iniciou em: $(date)"
	ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo Running preproc for $GRID grid only...
	echo $msg
	preproc $HH $GRID $IPROG $FPROG $currdate $runtype
elif [ -z $RUNTYPE ];then
	runtype='ope'

	msg="Executando preproc para $HH, domínio $GRID, hstart $IPROG, hstop $FPROG, data $DATE \
                e modo $runtype..."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="O processo iniciou em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo Running preproc for $GRID grid only...
	date
	echo
	preproc $HH $GRID $IPROG $FPROG $DATE $runtype
else
	msg="Executando preproc para $HH, domínio $GRID, hstart $IPROG, hstop $FPROG, data $DATE \
                e modo $RUNTYPE..."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="O processo iniciou em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo Running iconlam for $GRID grid, date $currdate...
	date
	echo
	preproc $HH $GRID $IPROG $FPROG $DATE $RUNTYPE
fi

if [ $? -eq 0 ]; then
        msg="OK. Processo finalizado com sucesso!"
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Terminou em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
        ecflow_client --event PreProc_SAFO
else
        msg="WARNING! Processo finalizado com erros!"
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Terminou em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
fi

echo $msg
echo "End of preproc script 04!"
