#!/bin/bash -l
#
# Script for generating files with current data in specific
# formats.
#
# Author CT Neris, adapted from 03_ledata_corr.sh (admcosmo)
# 
# ---------------------------------------------------------
# Activating ecflow env
conda activate ecflow

# Checking args passed
if [ $# -ne 1 ]; then
	echo "Enter reference data (00, 12)!!!!!"
	msg="FATAL ERROR. Entre com a rodada (00, 12)."
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Script abortado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	exit 11
fi

HH=$1

# ---------------------------------------------------------
# Cleaning directory
rm -f /home/opicon/operacional/currentdates/currentdate$HH

#  Read and copy 
date +%Y%m%d > /home/opicon/operacional/currentdates/currentdate$HH

echo "Currentdate is `cat /home/opicon/operacional/currentdates/currentdate$HH`!"

if [ $? -eq 0 ]; then
        msg="OK. Processo finalizado com sucesso! Data atual: `cat /home/opicon/operacional/currentdates/currentdate$HH`"
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Finalizado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
        ecflow_client --event AtuData_SAFO
else
        msg="WARNING! Processo finalizado com erros! Data atual: `cat /home/opicon/operacional/currentdates/currentdate$HH`"
        ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
        msg="Finalizado em: $(date)"
        ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
	exit 2
fi
