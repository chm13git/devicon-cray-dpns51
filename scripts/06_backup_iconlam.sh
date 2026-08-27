#!/bin/bash -l

############################################################
#
# Script to compress the ICONLAM data and save it to the backup.
#
# Author: CT(T) Neris
############################################################
# Activating ecflow env
conda activate ecflow

PBZIP2=/home/opicon/anaconda3/envs/ecflow/bin/pbzip2

backup_iconlam(){

HH=$1
GRID=$2
DATE=$3
RUNTYPE=$4

case $GRID in
	sam)
	workdir="/home/opicon/operacional/sam6.5/data"
	bkpdir="/data2/backup/backup_icon/bkp_output_iconlam/sam"
	filepre="iconlam_sam6.5_${HH}"
	finalprog=120
	minfilesize=4437829451
	minfilesize_nc=125000000
	minfilesize_nc_ps=400000
	minfilesize_vrfml=7170221808 # geralmente arredondo o tamanho da 4 casa para zero
	minfilesize_vrfpl=13680028264
	minfilesize_vrf=20807229908
	tint=3
	refnumfiles=`echo "(($finalprog/$tint + 1) * 2)" |bc` # Calculating reference number of files
	refnumfiles_nc=1 # number of NC files to be bkd-up
	;;
	ant)
	workdir="/home/opicon/operacional/ant6.5/data"
	bkpdir="/data2/backup/backup_icon/bkp_output_iconlam/ant"
	filepre="iconlam_ant6.5_${HH}"
	finalprog=120
	minfilesize=805176483
	minfilesize_nc=2000000
	minfilesize_vrfml=3280924848
	minfilesize_vrfpl=6260677544
	minfilesize_vrf=9540586708
	tint=3
	refnumfiles=`echo "(($finalprog/$tint + 1) * 2)" |bc` # Calculating reference number of files
	refnumfiles_nc=1 # number of NC files
	;;
	sse)
	workdir="/home/opicon/operacional/sse2.1/data"
	bkpdir="/data2/backup/backup_icon/bkp_output_iconlam/sse"
	filepre="iconlam_sse2.1_${HH}"
	finalprog=48
	minfilesize=4400000000
	minfilesize_vrfml=2240940896
	minfilesize_vrfpl=4270016624
	minfilesize_vrf=6510140060
	tint=1
	refnumfiles=`echo "(($finalprog/$tint + 1) * 2)" |bc` # Calculating reference number of files
	refnumfiles_nc=1 # number of NC files
	;;
	pen)
	workdir="/home/opicon/operacional/pen2.1/data"
	bkpdir="/data2/backup/backup_icon/bkp_output_iconlam/pen"
	filepre="iconlam_pen2.1_${HH}"
	finalprog=48
	minfilesize=680000000
	minfilesize_vrfml=400532088
	minfilesize_vrfpl=763023444
	minfilesize_vrf=1160746812
	tint=1
	refnumfiles=`echo "(($finalprog/$tint + 1) * 2)" |bc` # Calculating reference number of files
	;;
	*)
	echo "ERROR! Invalid grid name!"
	echo "Enter sam, sse, ant, pen."
	msg="FATAL ERROR! Domínio inválido. Entre com sam, sse, ant ou pen."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Script abortado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	exit 22
	;;
esac

# I/O Dirs depend on workdir var, defined in the CASE above.

# Backup dir
rsync_bkpdir="admbackup@dpns42:$bkpdir"

#Output dir
if [ $RUNTYPE == 'ope' ];then
	outdir="$workdir/outputdata$HH"
else # entra aqui se RUNTYPE != ope
	outdir="$workdir/exprun_outputdata$HH"
fi

# Checking conditions to run
nmax_attempt=720 # 720 cycles of 30s, i.e., 6h.
nattempts=1
flag=1

while [ $flag -eq 1 ]; do

	cd ${outdir}
	echo Checking if all files exist and have the right size...
	echo
	msg="Checando se todos os arqs existem e são do tamanho correto..."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1

        msg="Data/Hora: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	# ============================================================
	# Checking VRF files
	# ============================================================

	vrfmlfilename="iconlam_${GRID}_${HH}_${DATE}_vrf_ml.nc"
	vrfplfilename="iconlam_${GRID}_${HH}_${DATE}_vrf_pl.nc"
	vrfFilename="${filepre}_${DATE}_vrf.nc"

	vrf_ready=1

	# Primeiro verifica se o arquivo consolidado já existe e está OK
	if [ -s "${outdir}/${vrfFilename}" ] && \
	   [ "$(stat -c %s "${outdir}/${vrfFilename}")" -ge "$minfilesize_vrf" ]; then

	    echo "VRF file ${vrfFilename} already exists and has the expected size."
	    vrf_ready=0

	# Caso contrário, verifica os dois arquivos de origem
	elif [ -s "${outdir}/${vrfmlfilename}" ] && \
     [ -s "${outdir}/${vrfplfilename}" ] && \
     [ "$(stat -c %s "${outdir}/${vrfmlfilename}")" -ge "$minfilesize_vrfml" ] && \
     [ "$(stat -c %s "${outdir}/${vrfplfilename}")" -ge "$minfilesize_vrfpl" ]; then

	    echo "VRF files found:"
	    echo "  ${vrfmlfilename}"
	    echo "  ${vrfplfilename}"
	    echo "Merging VRF files..."

	    msg="Arquivos VRF encontrados. Fazendo merge..."
	    ecflow_client --label=Info1 "$msg" > /dev/null 2>&1

	    # Copia ML para ser o arquivo de saída
	    cp -f "${outdir}/${vrfmlfilename}" "${outdir}/${vrfFilename}.temp"

	    # Acrescenta PL
	    if ncks -A \
        "${outdir}/${vrfplfilename}" \
        "${outdir}/${vrfFilename}.temp"; then

	        # Verifica se o arquivo final foi realmente criado
	        if [ -s "${outdir}/${vrfFilename}.temp" ] && \
	           [ "$(stat -c %s "${outdir}/${vrfFilename}.temp")" -ge "$minfilesize_vrf" ]; then

	            echo "VRF merge completed successfully. Renaming file..."
	            mv "${outdir}/${vrfFilename}.temp" "${outdir}/${vrfFilename}"
	            vrf_ready=0

	            msg="Merge dos arquivos VRF concluído com sucesso. Renomeando arquivo para nome final ${outdir}/${vrfFilename}..."
	            ecflow_client --label=Info1 "$msg" > /dev/null 2>&1

	        else

	            echo "WARNING: merged VRF file has unexpected size."
	            rm -f "${outdir}/${vrfFilename}.temp"

	        fi

	    else

        	echo "WARNING: ncks failed while merging VRF files."
        	rm -f "${outdir}/${vrfFilename}.temp"

    	    fi

	else

	    echo "VRF files are not ready yet."

	fi

	# ============================================================
	# Checking number of grib files (basic bkp)
	# ============================================================
	bkpfilenames=`ls ${filepre}_${DATE}_???_??.grb`
	numfiles=`echo $bkpfilenames | wc -w`
        
	if [ ! -s $bkpdir/${filepre}_${DATE}.tar.bz2 ] && \
	[ $numfiles -eq $refnumfiles ];then
		echo Successful! All $refnumfiles files for ATM found!
		echo Compressing and synchronizing files...
		echo
		msg="Sucesso! Todos os $refnumfiles arqs foram encontrados. Comprimindo e sincronizando arquivos..."
        	ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        	msg="Data/Hora: $(date)"
        	ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

		#tar cjvf ${outdir}/${filepre}_${DATE}.tar.bz2 $bkpfilenames
		tar --use-compress-program=$PBZIP2 -cf ${outdir}/${filepre}_${DATE}.tar.bz2 $bkpfilenames
		rsync -av ${outdir}/${filepre}_${DATE}.tar.bz2 $rsync_bkpdir/

		if [ -s $bkpdir/${filepre}_${DATE}.tar.bz2 ] && \
		[ `stat -c %s ${bkpdir}/${filepre}_${DATE}.tar.bz2` -gt $minfilesize ];then
			echo "Backup feito com sucesso! ✅"
			msg="Backup feito com sucesso! ✅"
        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        		msg="Data/Hora: $(date)"
        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
			ecflow_client --event Backup_SAFO
			flag=0
		else
			echo "Warning! Ocorreu algum erro no Backup. ⚠️"
			msg="Warning! Ocorreu algum erro no Backup. ⚠️"
        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
			msg="Vou tentar de novo..."
        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        		msg="Data/Hora: $(date)"
        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
		fi
	elif [ -s $bkpdir/${filepre}_${DATE}.tar.bz2 ] && \
	[ `stat -c %s ${bkpdir}/${filepre}_${DATE}.tar.bz2` -gt $minfilesize ];then
		echo Successful! 
		echo File $bkpdir/${filepre}_${DATE}.tar.bz2 already backed-up with correct file size!
		echo
		msg="Sucesso! O arq $bkpdir/${filepre}_${DATE}.tar.bz2 foi encontrado e está com o tamanho esperado."
        	ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        	msg="Mal feito feito ✅. Data/Hora: $(date)"
        	ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
		ecflow_client --event Backup_SAFO

		flag=0
	else
		echo "BACKUP WARNING: File(s) are not ready yet. Waiting 30s..."
		echo "Cycle $nattempts of $nmax_attempt"
		echo "Teste 1 - $bkpdir/${filepre}_${DATE}.tar.bz"
		echo "Teste 2 - `stat -c %s ${bkpdir}/${filepre}_${DATE}.tar.bz2` -gt $minfilesize"
		echo
		msg="Warning! Arqs grib NÃO foram encontrados. Esperando 30s..."
        	ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        	msg="Ciclo $nattempts de $nmax_attempt. Data/Hora: $(date)"
        	ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

		echo
		sleep 30
		nattempts=$((nattempts+1))
	fi

	# Checking delft files
	if [ $GRID == "sam" ];then
		# Resetting flag
		flag=1

		cd ${outdir}
		bkpfilenames=`ls iconlam_${GRID}_${HH}_${DATE}_delft.nc`
		bkpfilenames_ps=`ls iconlam_${GRID}_${HH}_${DATE}_delft_ps.nc`
		numfiles=`echo $bkpfilenames | wc -w`
		numfiles_ps=`echo $bkpfilenames | wc -w`

		if [[ ! -s $bkpdir/${filepre}_wave_${DATE}.tar.bz2 || \
		      ! -s $bkpdir/${filepre}_wave_ps_${DATE}.tar.bz2 || \
		      $numfiles -eq $refnumfiles_nc || \
		      $numfiles_ps -eq $refnumfiles_nc ]];then
			echo Successful! Files iconlam_${GRID}_${HH}_${DATE}_delft.nc and iconlam_${GRID}_${HH}_${DATE}_delft_ps.nc found correct!
			echo Compressing and synchronizing files...
			echo
			msg="Sucesso! Arqs iconlam_${GRID}_${HH}_${DATE}_delft.nc e iconlam_${GRID}_${HH}_${DATE}_delft_ps.nc corretos encontrados."
        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        		msg="Comprimindo e sincronizando arquivos... Data/Hora: $(date)"
        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

			#tar cjvf ${outdir}/${filepre}_wave_ps_${DATE}.tar.bz2 $bkpfilenames_ps
			tar --use-compress-program=$PBZIP2 -cf ${outdir}/${filepre}_wave_${DATE}.tar.bz2 $bkpfilenames
			tar --use-compress-program=$PBZIP2 -cf ${outdir}/${filepre}_wave_ps_${DATE}.tar.bz2 $bkpfilenames_ps
			rsync -av ${outdir}/${filepre}_wave*${DATE}.tar.bz2 $rsync_bkpdir/

			if [[ -s "$bkpdir/${filepre}_wave_${DATE}.tar.bz2" && \
                        -s "$bkpdir/${filepre}_wave_ps_${DATE}.tar.bz2" && \
                        `stat -c %s ${bkpdir}/${filepre}_wave_${DATE}.tar.bz2` -gt $minfilesize_nc && \
                        `stat -c %s ${bkpdir}/${filepre}_wave_ps_${DATE}.tar.bz2` -gt $minfilesize_nc_ps ]];then
				echo "Backup 2 de 2 feito com sucesso! ✅"
				msg="Backup 2 de 2 feito com sucesso! ✅"
	        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
	        		msg="Data/Hora: $(date)"
	        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
				ecflow_client --event Backup_SAFO
				flag=0
			else
				echo "Warning! Ocorreu algum erro no Backup. ⚠️"
				msg="Warning! Ocorreu algum erro no Backup. ⚠️"
	        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
				msg="Vou tentar de novo..."
	        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
	        		msg="Data/Hora: $(date)"
	        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
			fi
		elif [[ -s "$bkpdir/${filepre}_wave_${DATE}.tar.bz2" && \
		        -s "$bkpdir/${filepre}_wave_ps_${DATE}.tar.bz2" && \
		        `stat -c %s ${bkpdir}/${filepre}_wave_${DATE}.tar.bz2` -gt $minfilesize_nc && \
		        `stat -c %s ${bkpdir}/${filepre}_wave_ps_${DATE}.tar.bz2` -gt $minfilesize_nc_ps ]];then
			echo Successful! 
			echo Files already backed-up with correct size!
			echo "$bkpdir/${filepre}_wave_${DATE}.tar.bz2"
			echo "$bkpdir/${filepre}_wave_ps_${DATE}.tar.bz2"
			msg="Sucesso! Arqs $bkpdir/${filepre}_wave_${DATE}.tar.bz2 and $bkpdir/${filepre}_wave_ps_${DATE}.tar.bz2 já foram salvos e com os tamanhos esperados."
        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        		msg="Mal feito feito ✅. Data/Hora: $(date)"
        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
			ecflow_client --event Backup_SAFO

			echo
			flag=0
		else
			echo "BACKUP WARNING: Files ($bkpdir/${filepre}_wave_${DATE}.tar.bz2, $bkpdir/${filepre}_wave_ps_${DATE}.tar.bz2) for WAVE are not ready yet. Waiting 30s..."
			echo "Cycle $nattempts of $nmax_attempt"
			echo
			msg="Warning! Arqs $bkpdir/${filepre}_wave_${DATE}.tar.bz2 e $bkpdir/${filepre}_wave_ps_${DATE}.tar.bz2 NÃO foram encontrados. Esperando 30s..."
        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        		msg="Ciclo $nattempts de $nmax_attempt. Data/Hora: $(date)"
        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

			echo
			sleep 30
			nattempts=$((nattempts+1))
		fi

	fi

	# Checking delft files
        if [ $GRID == "ant" ] || [ $GRID == "sse" ];then
                # Resetting flag
                flag=1

                cd ${outdir}
                bkpfilenames=`ls iconlam_${GRID}_${HH}_${DATE}_delft.nc`
                numfiles=`echo $bkpfilenames | wc -w`

                if [[ ! -s $bkpdir/${filepre}_wave_${DATE}.tar.bz2 && \
                      $numfiles -eq $refnumfiles_nc ]];then
			echo "Successful! File(s) number is correct and bkp file does not exist yet!"
                        echo Compressing files...
                        echo
			msg="Sucesso! Arq $bkpdir/${filepre}_wave_${DATE}.tar.bz2 encontrado."
        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        		msg="Comprimindo e sincronizando... Data/Hora: $(date)"
        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

                        #tar cjvf ${outdir}/${filepre}_wave_${DATE}.tar.bz2 $bkpfilenames
			tar --use-compress-program=$PBZIP2 -cf ${outdir}/${filepre}_wave_${DATE}.tar.bz2 $bkpfilenames
                        rsync -av ${outdir}/${filepre}_wave_${DATE}.tar.bz2 $rsync_bkpdir/

			if [[ -s "$bkpdir/${filepre}_wave_${DATE}.tar.bz2" && \
                        `stat -c %s ${bkpdir}/${filepre}_wave_${DATE}.tar.bz2` -gt $minfilesize_nc ]];then
				echo "Backup 2 de 2 feito com sucesso! ✅"
				msg="Backup 2 de 2 feito com sucesso! ✅"
	        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
	        		msg="Data/Hora: $(date)"
	        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
				ecflow_client --event Backup_SAFO
				flag=0
			else
				echo "Warning! Ocorreu algum erro no Backup. ⚠️"
				echo "File size found: `stat -c %s ${bkpdir}/${filepre}_wave_${DATE}.tar.bz2`"
				echo "Expected file size: $minfilesize_nc"
				msg="Warning! Ocorreu algum erro no Backup. ⚠️"
	        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
				msg="Vou tentar de novo..."
	        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
	        		msg="Data/Hora: $(date)"
	        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
			fi

                        flag=0
                elif [[ -s "$bkpdir/${filepre}_wave_${DATE}.tar.bz2" && \
                        `stat -c %s ${bkpdir}/${filepre}_wave_${DATE}.tar.bz2` -gt $minfilesize_nc ]];then
                        echo Successful!
                        echo Files already backed-up with correct size!
                        echo "$bkpdir/${filepre}_wave_${DATE}.tar.bz2"
                        echo "$bkpdir/${filepre}_wave_ps_${DATE}.tar.bz2"
                        echo
			msg="Sucesso! Arq $bkpdir/${filepre}_wave_${DATE}.tar.bz2 já foi salvo e com o tamanho esperado."
        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        		msg="Mal feito feito ✅. Data/Hora: $(date)"
        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
			ecflow_client --event Backup_SAFO

                        flag=0
                else
                        echo "BACKUP WARNING: File $bkpdir/${filepre}_wave_${DATE}.tar.bz2 for WAVE not ready yet. Waiting 30s..."
                        echo "Cycle $nattempts of $nmax_attempt"
                        echo
			msg="Warning! Arq $bkpdir/${filepre}_wave_${DATE}.tar.bz2 NÃO encontrado. Esperando 30s..."
        		ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        		msg="Ciclo $nattempts de $nmax_attempt. Data/Hora: $(date)"
        		ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

                        echo
                        sleep 30
                        nattempts=$((nattempts+1))
                fi

        fi

	if [ $nattempts -gt $nmax_attempt ];then
		echo 06_backup_iconlam.sh script ERROR!
		echo Waited for 6 hours but the file did not arrive.
		echo Aborting script...
		msg="FATAL ERROR! Esperei por 6 horas mas não encontrei o(s) arq(s)."
        	ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        	msg="Script abortado em: $(date)"
        	ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
		exit 2
	fi
done
}

# Step 1 - Retrieving parameters
if [ $# -ne 2 ] && [ $# -ne 3 ] && [ $# -ne 4 ];then
	echo "Enter the run (00, 12), the grid (sam, met, sse, ant, pen), and/or the date (yyyymmdd) and/or runtype (ope, exp)!!!"
	echo 
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

if [ -z $DATE ] && [ -z $RUNTYPE ];then
	currdate=`cat /home/opicon/operacional/currentdates/currentdate${HH}`
	runtype='ope'
	echo Running BACKUP for $GRID grid, $HH run, date $currdate and runtype $runtype...
	msg="Rodando o backup para: $HH $GRID $currdate $runtype..."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Data/Hora: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

	date
	time backup_iconlam $HH $GRID $currdate $runtype
elif [ -z $RUNTYPE ];then
	runtype='ope'
	echo Running BACKUP for $GRID grid, $HH run, date $DATE and runtype $runtype...
        date
	msg="Rodando o backup para: $HH $GRID $DATE $runtype..."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Data/Hora: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

        time backup_iconlam $HH $GRID $DATE $runtype
else
	echo Running BACKUP for $GRID grid, $HH run, date $DATE and runtype $RUNTYPE...
        date
	msg="Rodando o backup para: $HH $GRID $DATE $RUNTYPE..."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Data/Hora: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

        time backup_iconlam $HH $GRID $DATE $RUNTYPE
fi

date
echo "End of ICONLAM BACKUP script 06!"
