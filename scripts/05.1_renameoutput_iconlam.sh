#!/bin/bash -l
#
#  Script para modificar os nomes dos arquivos de previsao
#  de todas as areas do modelo iconlam.
#
#
# Autor: CT(T) Neris

# ----------------------------------------------------------------------
# Activating ecflow env
conda activate ecflow

# Step 1 - Retrieving parameters

if [ $# -ne 2 ] && [ $# -ne 4 ] && [ $# -ne 5 ] && [ $# -ne 6 ];then
	echo "Enter the run (00, 12) and the grid (sam, sse, ant, pen), HSTART, HSTOP and run type (ope/exp) optionally!!!"
	echo
	echo "Ex.: script 00 sam"
	echo or
	echo "Ex.: script 00 sam 48 96"
	echo or
	echo "Ex.: script 00 sam 48 96 exp"
	echo or
	echo "Ex.: script 00 sam 48 96 exp 20241203"
	msg="FATAL ERROR! Núm de args inválido. Entre com a rodada (00, 12), e/ou domínio (sam, sse, ant, pen) \
		hstart (00), hstop (48), modo (ope, exp) [opcional] e data (yyyymmdd) [opcional]"
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Script abortado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	exit 11
fi

HH=$1
AREA=$2
HSTART=$3
HSTOP=$4
RUNTYPE=$5
DATE=$6

if [ -z $HSTART ] && [ -z $HSTOP ] && [ -z $RUNTYPE ] && [ -z $DATE ];then
	if [ $AREA == "sse" -o $AREA == "pen" ];then
		HSTART=0
		HSTOP=48
	else
		HSTART=0
		HSTOP=120
	fi
	RUNTYPE='ope'
	currdate=`cat /home/opicon/operacional/currentdates/currentdate${HH}`
	echo
	echo Using default hstart/hstop = $HSTART/$HSTOP
	echo
elif [ -z $RUNTYPE ] && [ -z $DATE ];then
	RUNTYPE='ope'
	currdate=`cat /home/opicon/operacional/currentdates/currentdate${HH}`
elif [ -z $DATE ];then
	currdate=`cat /home/opicon/operacional/currentdates/currentdate${HH}`
else
	currdate=$DATE
	echo Using hstart/hstop passed by user = $HSTART/$HSTOP
	echo
fi

# Defining vars
ncdump="/home/devicon/intel2020.4_install/build/netcdf-c-4.9.2/bin/ncdump"
nmax=720
sltime=30

# ----------------------------------------------------------------------
# Step 2 - Defining grid specifics vars
case $AREA in
	sam)
	domain="sam6.5"
	workdir="/home/opicon/operacional/sam6.5/data"
	nvarml="34"
	nvarpl="104"
	ntuv="24" # Esta usando como -ge pq o primeiro arq tem 25 tempos
	prog_int=3
	;;
	ant)
	domain="ant6.5"
	workdir="/home/opicon/operacional/ant6.5/data"
	nvarml="33"
	nvarpl="104"
	ntuv="24"
	prog_int=3
	;;
	sse)
	domain="sse2.1"
	workdir="/home/opicon/operacional/sse2.1/data"
	nvarml="33"
	nvarpl="48"
	ntuv="24"
	prog_int=1
	;;
	pen)
	domain="pen2.1"
	workdir="/home/opicon/operacional/pen2.1/data"
	nvarml="26"
	nvarpl="48"
	prog_int=1
	;;
	*)
	echo " ERROR! Invalid grid name!"
	exit 12
	;;
esac

# Loading common dirs
if [ $RUNTYPE == 'ope' ];then
	outdir="$workdir/outputdata$HH"
else
	outdir="$workdir/exprun_outputdata$HH"
fi


# ----------------------------------------------------------------------
# Loop for renaming files
inum=`echo "($HSTART / $prog_int) + 1" |bc`
fnum=`echo "($HSTOP / $prog_int) + 1" |bc`

for num in `seq $inum 1 $fnum`; do

	# Setting prog num vars
	numgrb=`printf "%04g" $num`		# 0001, 0002...
	numprog=`printf "%03g" $((num*prog_int-prog_int))`	# 000, 003...
	numprog2=`printf "%02g" $((num*prog_int-prog_int))`	# 00, 03...
	restoprog=`echo "$numprog2 % 24" |bc`

	# Retrieving prog file name
	mlfile=${outdir}/iconlam_${AREA}_${HH}_${currdate}_${numgrb}_ml.grb
	nmlfile=${outdir}/iconlam_${domain}_${HH}_${currdate}_${numprog}_ml.grb
	plfile=${outdir}/iconlam_${AREA}_${HH}_${currdate}_${numgrb}_pl.grb
	nplfile=${outdir}/iconlam_${domain}_${HH}_${currdate}_${numprog}_pl.grb

	# Dealing with NC files
	numnc=`printf "%04g" \`echo "$numprog2 / 24" |bc\``   # 0001, 0002...
	uvfile=${outdir}/iconlam_${AREA}_${HH}_${currdate}_${numnc}_uv.nc
	nuvfile=${outdir}/iconlam_uv_${currdate}${HH}_${numprog2}.nc

	# Waits for 6 hours the files to arrive
	nattempts=1
	nattemptsuv=1
	flag=1
	flaguv=1

	while [ $flag -eq 1 ] || [ $flaguv -eq 1 ]; do

		msg="Renomeando prog $numprog..."
        	ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        	msg="Data/Hora: $(date)"
        	ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
		ecflow_client --meter=progress ${numprog}
		# Check if the file exists, if is not empty and if the number of variables is valid
		if [ -s $mlfile ] && [ `wgrib2 $mlfile | wc -l` = $nvarml ] \
	       	&& [ -s $plfile ] && [ `wgrib2 $plfile | wc -l` = $nvarpl ]; then
			echo "OK, ML and PL files found and with correct number of vars! Renaming prog ${numprog}h..."
			echo
			msg="OK. Arqs ML e PL de $numprog com número correto de vars"
        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        		msg="Data/Hora: $(date)"
        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
			mv $mlfile $nmlfile
			mv $plfile $nplfile
			flag=0
		elif [ -s $nmlfile ] && [ -s $nplfile ]; then
			echo "ALL DONE! ML and PL files have already been renamed for prog ${numprog}h!"
			echo
			flag=0
		else
			nattempts=$((nattempts+1))
			echo
			echo "Info: File(s) are not ready yet. Waiting ${sltime}s..."
			echo "Cycle $nattempts of $nmax"
			echo
			echo "Please, check them:"
			echo $mlfile
			echo $plfile
			echo
			msg="Info. Arqs ML e PL de $numprog NÃO encontrado ou com número errado de vars"
        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        		msg="Data/Hora: $(date)"
        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
			sleep $sltime
			flag=1
		fi
	
		# Check if the UV file exists, if is not empty and if the number of variables is valid
		if [ $restoprog -eq 0 ] && [ $num -gt 1 ] && [ $AREA == "sam" ];then
			#if [ -s $uvfile ] && [ `${ncdump} -h ${uvfile} | grep 'time = UNLIMITED' | cut -d'(' -f2 | awk {'print $1'}` -ge $ntuv ];then
			if [ -s $uvfile ];then
				echo "OK, UV file found and complete! Renaming prog ${numprog2}h..."
				echo
				mv $uvfile ${nuvfile}
				flaguv=0
			elif [ -s $nuvfile ]; then
				echo "ALL DONE! NC file has already been renamed for prog ${numprog}h!"
				echo
				flaguv=0
			else
				nattemptsuv=$((nattemptsuv+1))
				echo "Info: File NC not ready yet. Waiting ${sltime}s..."
				echo "Please, check it out:"
				echo $uvfile
				echo
				sleep $sltime
				flaguv=1
			fi
		elif [ $AREA != "sam" ] || [ $restoprog -ne 0 ];then
			echo Skipping UV file for GRID != sam6.5 and prog ${numprog2}h...
			echo
			flaguv=0
		else
			echo Skipping UV file for prog ${numprog2}h...
			echo
			flaguv=0
		fi

		# Aborting if file takes more than 6hrs to arrive
		if [ $nattempts -gt $nmax ] || [ $nattemptsuv -gt $nmax ];then
			echo 05.1 Rename script ERROR!
			echo Waited for 6 hours but the file did not arrive.
			echo Aborting script...
			exit 777
		fi
	done
done
