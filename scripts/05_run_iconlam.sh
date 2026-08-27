#!/bin/bash -l
#
# Script for running ICONLAM.
#
# Author: CT(T) Neris
#
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Activating ecflow env
conda activate ecflow

# ----------------------------------------------------------------------
# Function Section

proc(){

# DO NOT touch this unless you know what you are doing!
# Some of these really makes the difference for running via cron!
export MPI_GROUP_MAX=1024
export MPI_IB_RECV_MSGS=2048
export LIBDWD_BITMAP_TYPE=ASCII
export MPI_BUFS_PER_PROC=1024
export MPI_BUFS_PER_HOST=1024
export LIBDWD_FORCE_CONTROLWORDS=1

ulimit -s unlimited
ulimit -l unlimited
ulimit -v unlimited

HH=$1
GRID=$2
currdate=$3
RUNTYPE=$4

echo "Initiating ICONLAM $GRID run..."
date

# ----------------------------------------------------------------------
# Loading icon binary with full path
#compiler='intel2019'
compiler='intel2020.4'
#source $scripts_dir/00_env_vars_iconlam.sh $compiler
#source $scripts_dir/00_env_vars_iconlam.sh $compiler mpich
#source $scripts_dir/00_env_vars_iconlam.sh $compiler mpiintel
source $scripts_dir/00_env_vars_iconlam.sh $compiler mpiintel 2025.04

MODEL=$BINARY_ICONMODEL
MPIEXEC=$MPIBIN_ICONMODEL
MODELDIR=$MODEL_DIR
CDO=$CDO

# ----------------------------------------------------------------------
# Step 2 - Defining grid specifics vars
case $GRID in
	sam)
	domain="sam6.5"
	workdir="/home/opicon/operacional/sam6.5"
	localgrid="$workdir/const/grid_files/ICON-SAM6.5_DOM01.nc"
	radgrid="$workdir/const/grid_files/ICON-SAM6.5_DOM01.parent.nc"
	extpargrid="$workdir/const/grid_files/external_parameter_icon_ICON-SAM6.5_DOM01_tiles.nc"
	tmpl="$workdir/const/tmpl_create_icon_nml_sam6.5"
	filepre="iconlam_${domain}_${HH}_${DATE}_120_pl.grb"
	forecast_time_per=120
	checkpoint1="$outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_pl.grb"
	checkpoint2="$outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_ml.grb"
	checkpoint3="$outdir/iconlam_uv_${currdate}${HH}_${forecast_time_per}.nc"
	;;
	sse)
	domain="sse2.1"
	workdir="/home/opicon/operacional/sse2.1"
	localgrid="$workdir/const/grid_files/sse2.1_DOM01.nc"
	radgrid="$workdir/const/grid_files/sse2.1_DOM01.parent.nc"
	extpargrid="$workdir/const/grid_files/external_parameter_icon_sse2.1_DOM01_tiles.nc"
	tmpl="$workdir/const/tmpl_create_icon_nml_sse2.1"
	filepre="iconlam_${domain}_${HH}_${DATE}_120_pl.grb"
	forecast_time_per=48
	checkpoint1="$outdir/iconlam_${domain}_${HH}_${currdate}_0${forecast_time_per}_pl.grb"
	checkpoint2="$outdir/iconlam_${domain}_${HH}_${currdate}_0${forecast_time_per}_ml.grb"
	;;
	ant)
	domain="ant6.5"
	workdir="/home/opicon/operacional/ant6.5"
	localgrid="$workdir/const/grid_files/ICONLAM-ANT6.5_DOM01.nc"
	radgrid="$workdir/const/grid_files/ICONLAM-ANT6.5_DOM01.parent.nc"
	extpargrid="$workdir/const/grid_files/external_parameter_icon_ICONLAM-ANT6.5_DOM01_tiles.nc"
	tmpl="$workdir/const/tmpl_create_icon_nml_ant6.5"
	filepre="iconlam_${domain}_${HH}_${DATE}_120_pl.grb"
	forecast_time_per=120
	checkpoint1="$outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_pl.grb"
	checkpoint2="$outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_ml.grb"
	checkpoint3="$outdir/iconlam_${GRID}_${HH}_${currdate}_delft.nc"
	;;
	pen)
	domain="pen2.1"
	workdir="/home/opicon/operacional/pen2.1"
	localgrid="$workdir/const/grid_files/ICON-ANT2km_DOM01.nc"
	radgrid="$workdir/const/grid_files/ICON-ANT2km_DOM01.parent.nc"
	extpargrid="$workdir/const/grid_files/ICON-ANT2km_DOM01_external_parameter.nc"
	tmpl="$workdir/const/tmpl_create_icon_nml_pen2.1"
	forecast_time_per=48
	checkpoint1="$outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_pl.grb"
	checkpoint2="$outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_ml.grb"
	checkpoint3="$outdir/iconlam_${GRID}_${HH}_${currdate}_delft.nc"
	;;
	*)
	echo "ERROR! Invalid grid name!"
	echo "Enter sam, sse, ant or pen."
	msg="FATAL ERROR! Domínio inválido. Entre com sam, sse, ant ou pen"
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Script abortado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	exit 22
	;;
esac

# I/O Dirs depend on workdir var, defined in the CASE above.
if [ $RUNTYPE == 'ope' ];then
	lbcdir="$workdir/data/initialcond$HH"
	outdir="$workdir/data/outputdata$HH"
else # entra aqui se RUNTYPE=exp
	lbcdir="$workdir/data/exprun_initialcond$HH"
	outdir="$workdir/data/exprun_outputdata$HH"
fi

# Files to be used. Depend on workdir var, defined in the CASE above.
lbcgrid="$lbcdir/lateral_boundary.grid.nc"
icfile="$lbcdir/igfff00000000.grb2"
runnodes="$workdir/const/icon_model_nodes.txt"
#if [ $HH == "12" -a $GRID == "sse" ];then
#	runnodes="$workdir/const/icon_model_nodes.txt_extranodes"
#else
#	runnodes="$workdir/const/icon_model_nodes.txt_extranodes" # futuramente, sera o default
#fi

# ----------------------------------------------------------------------
# Loading date args
echo "Loading current date info: start, stop and grib dates..."
datecurr="$currdate $HH:00:00"
datecurr=`date -d "$datecurr"`
hstart=`date --date="$datecurr" "+%Y-%m-%dT%H:00:00Z"`
hstop=`date --date="$datecurr +${forecast_time_per}hour" "+%Y-%m-%dT%H:00:00Z"`
curr_refdate=`date -d "$datecurr" "+%Y-%m-%d %H:00:00"`

# Retrieve node and procs info
echo
echo Calculating number of nodes available based on $runnodes file...
echo
num_procs_per_node=$(grep '^num_procs_per_node:' "$runnodes" | cut -d':' -f2)
node_list=$(grep '^node_list:' "$runnodes" | cut -d':' -f2)
node_count=$(echo "$node_list" | tr ',' '\n' | wc -l)
num_total_procs=$((num_procs_per_node * node_count))
echo
echo "Nodes to be used			: $node_list."
echo "Total number of cores to be used	: $num_total_procs."
echo

# Checking and cleaning cache at each Node...
for no in $(echo "$node_list" | tr ',' ' '); do
    echo Checking if node is free...
    msg="Checando se nó $no está livre..."
    ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    msg="Data/Hora: $(date)"
    ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

    # INS um while para agu liberação do nó
    icon_procs_active=`pdsh -w $no 'ps -ef | grep binaries | grep -v grep' | wc -l`
    if [ $icon_procs_active -ne 0 ];then
	    pdsh -w $no 'ps -ef | grep binaries | grep -v grep' > $logs_dir/icon_procs_$no.txt
	    echo FATAL ERROR! There are ICON processes already running at node $no. Please, reffer to $logs_dir/icon_procs_$no.txt for more info. Aborting!
  	    msg="ERROR! Já existem processos do ICON rodando no nó $no. Vide $logs_dir/icon_procs_$no.txt para mais detalhes. Vou abortar!!!!"
	    #echo WARNING! There are ICON processes already running at node $no. Please, reffer to $logs_dir/icon_procs_$no.txt for more info. Killing processes!
  	    #msg="Warning! Já existem processos do ICON rodando no nó $no. Vide $logs_dir/icon_procs_$no.txt para mais detalhes. Vou matá-los!!!!"
  	    ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
  	    msg="Data/Hora: $(date)"
  	    ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	    exit 1
	    pdsh -w $no kill -TERM -`ps -ef | grep -E "icon" | grep -E "binaries" | tail -1 | awk '{print $3}'`
	    pdsh -w $no kill -9 `ps -ef | grep -E "icon" | awk '{print $2}'`
    else
	    echo Node $no está livre para uso. 
	    msg="👍Nó $no está livre para uso."
	    ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
	    msg="Data/Hora: $(date)"
	    ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
    fi

    echo Cleaning cache on $no...
    msg="Limpando cache do nó $no..."
    ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    msg="Data/Hora: $(date)"
    ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

    sshpass -p '@dmd@40' ssh root@10.13.100.41 "pdsh -w $no bcfree"
    echo
done
# ----------------------------------------------------------------------
# Step 3 -  Checking if latbc_grid has been generated by 04.2 to run the model.

# absolute path to directory with plenty of space
cd $outdir

# Checking conditions to run
nmax_attempt=720 # 720 cycles of 30s, i.e., 6h.
attempt=1
FLAG=1

while [ $FLAG -eq 1 ]; do

	echo Checking if todays lateral_boundary.grid.nc exists...
	
	if [ -f ${lbcgrid} ] && [ `date -d "$(stat -c %y $lbcgrid)" +%Y%m%d` == "$currdate" ];then
		echo OK! The ${lbcgrid} file exists and it is todays. Proceeding...
		touch ${lbcgrid}_OK ; chmod 775 ${lbcgrid}_OK
	else
		echo Minor Info! The ${lbcgrid} file does NOT exist or is NOT todays.
                echo If extpar file is suposed to be updated, confirm that the file ${lbcgrid} is exactly what you expected.
		touch ${lbcgrid}_OK ; chmod 775 ${lbcgrid}_OK
	fi

	echo Checking if todays igfff00060000.grb2 exists...

        if [ -f $lbcdir/igfff00060000_lbc.grb2 ] && [ "`$CDO sinfov $lbcdir/igfff00060000_lbc.grb2 | grep RefTime | awk '{print $3,$4}'`" == "$curr_refdate" ];then
                echo The igfff00060000_lbc.grb2 file exists and it is todays. Proceeding...
                touch $lbcdir/igfff00060000_lbc.grb2_OK ; chmod 775 $lbcdir/igfff00060000_lbc.grb2_OK
        else
                echo WARNING! The igfff00060000_lbc.grb2 file does NOT exist or is NOT todays!!!
        fi


	# If condition is  met, proceed.
	if [ -f ${lbcgrid}_OK ] && \
     	   [ -f $lbcdir/igfff00060000_lbc.grb2_OK  ] ; then
		#-------------------------------------------------------------
		# Creating script for generating NAMELIST_ICONLAM* and icon_master*
		FLAG=0

		echo All conditions have been met. Creating icon namelists...
    		msg="Arquivos ${lbcgrid}_OK e igfff00060000_lbc.grb2_OK encontrados. Criando namelists..."
    		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    		msg="Data/Hora: $(date)"
    		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

		cat $tmpl						> raw3_$GRID
		cat raw3_$GRID | sed -e 's|HH_ARG|'$HH'|g'		> raw4_$GRID
		cat raw4_$GRID | sed -e 's|GRIDNAME_ARG|'$GRID'|g'	> raw3_$GRID
		cat raw3_$GRID | sed -e 's|DATE_ARG|'$currdate'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|HSTART_ARG|'$hstart'|g' 	> raw3_$GRID
		cat raw3_$GRID | sed -e 's|HSTOP_ARG|'$hstop'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|ICFILE_ARG|'$icfile'|g'	> raw3_$GRID
		cat raw3_$GRID | sed -e 's|LBCDIR_ARG|'$lbcdir'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|LBCGRID_ARG|'$lbcgrid'|g'	> raw3_$GRID
		cat raw3_$GRID | sed -e 's|LOCALGRID_ARG|'$localgrid'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|RADGRID_ARG|'$radgrid'|g'	> raw3_$GRID
		cat raw3_$GRID | sed -e 's|CLDOPTPROP_ARG|'$cldoptprop'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|LWABSCFF_ARG|'$lwabscff'|g'	> raw3_$GRID
		cat raw3_$GRID | sed -e 's|EXTPAR_ARG|'$extpargrid'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|MODELDIR_ARG|'$MODELDIR'|g'	> raw3_$GRID

		# Renaming and running script to create NAMELISTS_ICONSUB
		echo Renaming and running script to create NAMELISTS_ICON...
    		msg="Renomeando e rodando o script NAMELISTS_ICON..."
    		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    		msg="Data/Hora: $(date)"
    		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

		mv raw3_$GRID temp_tmpl_create_icon_nml_$GRID.sh
		chmod 755 temp_tmpl_create_icon_nml_$GRID.sh
		cat temp_tmpl_create_icon_nml_$GRID.sh

		./temp_tmpl_create_icon_nml_$GRID.sh

		# Triggering rename script in background
		echo
		echo Running RENAME for $HH $GRID in parallel...
		echo
		$scripts_dir/05.1_renameoutput_iconlam.sh $HH $GRID 00 $forecast_time_per $RUNTYPE $currdate > $logs_dir/rename_${GRID}_${HH}_${RUNTYPE}.log &

		echo

		run_flag=1
		counter=1
		#while [ $run_flag -ne 0 ];do
			echo
			echo Running ICONLAM for $HH $GRID...
			echo
			#time $MPIEXEC -ppn $num_procs_per_node -hosts $node_list -n $num_total_procs $MODEL && run_flag=0 || run_flag=1
			#	echo "ERROR! Some error occurred during iconlam run. Process will restart now `date`."
			time $MPIEXEC -ppn $num_procs_per_node -hosts $node_list -n $num_total_procs $MODEL

		#	counter=+1
		#	if [ $counter -gt 5 ];then
		#		echo
		#		echo "I've tried running for 5 times, but the error persisted."
		#		echo "Aborting..."
		#		echo
		#		exit 3
		#	fi
		#done
		#echo The run_flag = ${run_flag}, meaning the model simulation has been successful.

		sleep 90 # To give enough time to check and rename last file
		forecast_time_per=`printf "%03g" "$forecast_time_per"` # to write num with 3 digs
		if [ -s $outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_pl.grb ] && \
		   [ -s $outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_ml.grb ];then
			echo OK! Files $outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_*.grb found!
    			msg="Rodada OK! Arquivos $outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_*.grb encontrados."
    			ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    			msg="Data/Hora: $(date)"
    			ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
			ecflow_client --event Proc_SAFO

			touch $outdir/RUN_${domain}_${HH}_${currdate}_OK
		else
			echo ERROR in the ICONLAM run for ${HH}z $domain $currdate $RUNTYPE!
			echo File $outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_*.grb NOT found.
    			msg="ERROR! Arquivos $outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_*.grb NÃO encontrados."
    			ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    			msg="Data/Hora: $(date)"
    			ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
		fi

		# Clean-up
		#rm temp_tmpl_create_icon_nml_$GRID.sh raw3_$GRID raw4_$GRID output_schedule.ps icon_master.namelist NAMELIST_ICONLAM_$GRID NAMELIST_ICON_output_atm nml.atmo.log output_schedule.txt 2> /dev/null

		# Running backup_icon
		#echo
		#echo Running BACKUP for $HH $GRID $currdate $RUNTYPE simultaneously...
    		#msg="Rodando Backup para $HH $GRID em segundo plano."
    		#ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    		#msg="Data/Hora: $(date)"
    		#ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
		#echo
		#time $scripts_dir/06_backup_iconlam.sh $HH $GRID $currdate $RUNTYPE &

	else # if any condition has NOT been met
		echo WARNING! One or more conditions have NOT been met!
		echo Waiting 30s to try again...
    		msg="WARNING! Arquivos $outdir/iconlam_${domain}_${HH}_${currdate}_${forecast_time_per}_*.grb NÃO encontrados."
    		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    		msg="Esperando 30s para tentar novamente. Data/Hora: $(date)"
    		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
		sleep 30

		attempt=`expr $attempt + 1`
	fi

	if [ $attempt -gt $nmax_attempt ]; then
	  echo "Script 05 aborted after 6 hours!!!!"
	  echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    	  msg="ERROR! Script abortado depois de 6 horas de espera!!!!"
    	  ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
    	  msg="Data/Hora: $(date)"
    	  ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	  exit 22
	fi

done
}

# End of Function Section
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Loading used dirs
scripts_dir=$SCRIPTS_DIR
logs_dir=$SCRIPTS_DIR/logs

# Step 1 - Retrieving parameters
if [ $# -ne 1 ] && [ $# -ne 2 ] && [ $# -ne 3 ] && [ $# -ne 4 ] ;then
	echo "Enter the run (00, 12), the grid (sam, sse, ant, pen) and the DATE (yyyymmdd)!!!"
	echo 
	echo "Ex.: $0 00"
	echo or
	echo "Ex.: $0 00 sam"
	echo or
	echo "Ex.: $0 00 sam 20230301"
	echo or
	echo "Ex.: $0 00 sam 20230301 exp"
	msg="FATAL ERROR! Núm de args inválido. Entre com a rodada (00, 12), e/ou domínio (sam, sse, ant, pen) \
		data (yyyymmdd) [opcional] e o modo (ope, exp) [opcional]."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Script abortado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	exit 11
fi

HH=$1
GRID=$2
DATE=$3
RUNTYPE=$4

# Running ICONLAM model for each case
if [ -z $GRID ] && [ -z $DATE ] && [ -z $RUNTYPE ];then
	# Execution list
	gridslist=`cat $scripts_dir/runlist` # Same order for execution.

	echo Running ICONLAM for execution list: $gridslist...
	echo 
	msg="Rodando o ICONLAM para a lista de execução: $gridslist."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Data/Hora: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	currdate=`cat $scripts_dir/currentdates/currentdate${HH}`
	runtype='ope'
	for grid in $gridslist; do
		echo Running iconlam for $grid grid, date $currdate...
		date
		msg="Rodando o ICONLAM para o domínio: $HH $grid $currdate $runtype."
        	ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        	msg="Data/Hora: $(date)"
        	ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

		echo
		proc $HH $grid $currdate $runtype > $logs_dir/05_${HH}_${grid}_${currdate}_${runtype}.log 2>&1
		echo Saving log at $logs_dir/05_${HH}_${grid}_${currdate}_${runtype}.log
	done
elif [ -z $DATE ] && [ -z $RUNTYPE ];then
	currdate=`cat /home/opicon/operacional/currentdates/currentdate${HH}`
	runtype='ope'
	echo Running iconlam for $GRID grid, date $currdate...
	date
	msg="Rodando o ICONLAM para o domínio: $HH $GRID $currdate $runtype."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Data/Hora: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo
	proc $HH $GRID $currdate $runtype > $logs_dir/05_${HH}_${GRID}_${currdate}_${runtype}.log 2>&1
elif [ -z $RUNTYPE ];then
	runtype='ope'
	echo Running iconlam for $GRID grid, date $DATE...
	date
	msg="Rodando o ICONLAM para o domínio: $HH $GRID $DATE $runtype."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Data/Hora: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo
	proc $HH $GRID $DATE $runtype > $logs_dir/05_${HH}_${GRID}_${DATE}_${runtype}.log 2>&1
else
	echo Running iconlam for $GRID grid, date $DATE...
	date
	msg="Rodando o ICONLAM para o domínio: $HH $GRID $DATE $RUNTYPE."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Data/Hora: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	echo
	proc $HH $GRID $DATE $RUNTYPE > $logs_dir/05_${HH}_${GRID}_${DATE}_${RUNTYPE}.log 2>&1
fi

date
echo "End of ICONLAM script 05!"
