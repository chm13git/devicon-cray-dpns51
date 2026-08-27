#!/bin/bash -l
#
# Script to kill all ICON process before running the model,
# including those within each node.
#
# Author: CT Neris/CC Alana, 20240228
#-------------------------------------------------------
# Activating ecflow env
conda activate ecflow

if  [ $# -ne 1 ];then
        echo
        echo " Entre com o modo desejado:"
        echo " $0 all - para matar processos no nó de login e nos nós de execução do modelo"
	echo ou
        echo " $0 login - para matar processos SOMENTE no nó de login"
	echo ou
        echo " $0 proc - para matar SOMENTE processos de Proc no login e nos nós"
        echo
        exit 1
fi

MODE=$1

if [ "$MODE" = "all" ];then
   echo
   msg="Matando processos no nó de login"
   ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
   msg="O processo iniciou em: $(date)"
   ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
   echo
   echo -e "======\e[00;32m Killing processes at Login Node\e[00m ======" ;
   kill -TERM `ps -ef | grep -E "iconlam" | grep -v "01_killall_iconlam.sh" | awk '{print $2}'`
   kill -TERM `ps -ef | grep -E "ICONLAM" | grep -v "Mata" | awk '{print $2}'`
   kill -TERM `ps -ef | grep -E "exprun" | awk '{print $2}'`
   kill -TERM `ps -ef | grep -E "iconmodel" | awk '{print $2}'`
   kill -TERM `ps -ef | grep -E "mpiexec" | awk '{print $2}'`
   echo
   msg="Matando processos nos nós de execução do modelo"
   ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
   msg="O processo iniciou em: $(date)"
   ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
   echo
   echo -e "======\e[00;32m Killing processes in each Node\e[00m ======" ;
   pdsh -w node[01-07] kill -TERM -`ps -ef | grep -E "icon" | grep -E "binaries" | tail -1 | awk '{print $3}'`
   pdsh -w node[01-07] kill -TERM `ps -ef | grep -E "icon" | grep -E "binaries" | awk '{print $2}'`
   #pdsh -w node04 kill -TERM `ps -ef | grep -E "icon" | grep -E "binaries" | awk '{print $2}'`
   echo
elif [  "$MODE" = "login" ];then
   echo
   msg="Matando processos no nó de login"
   ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
   msg="O processo iniciou em: $(date)"
   ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
   echo
   echo -e "======\e[00;32m Killing processes at Login Node\e[00m ======" ;
   kill -TERM `ps -ef | grep -E "iconlam" |  grep -v "01_killall_iconlam.sh" | awk '{print $2}'`
   kill -TERM `ps -ef | grep -E "ICONLAM" | grep -v "Mata" | awk '{print $2}'`
   kill -TERM `ps -ef | grep -E "exprun" | awk '{print $2}'`
   kill -TERM `ps -ef | grep -E "iconmodel" | awk '{print $2}'`
   kill -TERM `ps -ef | grep -E "mpiexec" | awk '{print $2}'`
   echo
elif [  "$MODE" = "proc" ];then
   echo
   msg="Matando SOMENTE processos de PROCESSAMENTO no nó de login e nos nós"
   ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
   msg="O processo iniciou em: $(date)"
   ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
   echo
   echo -e "======\e[00;32m Killing ONLY procs of RUNTIME at Login Node and at nodes\e[00m ======" ;
   kill -TERM -`ps -ef | grep -E "05_run_iconlam.sh" | awk '{print $2}'`
   pdsh -w node[01-07] kill -TERM -`ps -ef | grep -E "icon" | awk '{print $3}'`
   pdsh -w node[01-07] kill -TERM `ps -ef | grep -E "icon" | grep -E "binaries" | awk '{print $2}'`
   echo
else
   echo -e "======\e[00;32m ERROR! Mode $MODE not found. Choose between: all/login.\e[00m ======" ;
   exit 2
fi

msg="Checando status dos nós node0[1-7]."
ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
msg="O processo iniciou em: $(date)"
ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

echo -e "======\e[00;32m Verifing if they are ALIVE and UP\e[00m ======" ;
pdsh -w node[01-07] uptime > time.txt
#pdsh -w node[01-07] uptime > time.txt
nodes=`cat time.txt | awk '{print $1}' | sort | sed 's/://g'`
NumberOfNodes=`cat time.txt | awk '{print $3}' | wc -l`
rm time.txt

if [ $NumberOfNodes -ge 7 ]; then 
   echo -e "======\e[00;32m All nodes (>=7) are Available and ON \e[00m ======" ; 
   echo -e "\e[00;32m$nodes\e[00m" ; 

   msg="Todos os nós (>=7) disponíveis e ON."
   ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
else
   msg="Warning: Número de nós disponíveis < 7."
   ecflow_client --label=Info1 "$msg" > /dev/null 2>&1

fi

msg="Checando status das partições do nó de login."
ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
msg="O processo iniciou em: $(date)"
ecflow_client --label=Info2 "$msg" > /dev/null 2>&1

echo -e "======\e[00;32m Verifing Partions on dpns41 \e[00m ======" ; 

sshpass -p '@dmd@40' ssh root@10.13.100.41 << EOF

# Tempo máximo de espera (4h) e intervalo (10s)
MAX_WAIT=\$((4*3600))
INTERVAL=10

# Extrai apenas linhas de NFS do fstab, ignorando comentários
montagens=\$(grep -v '^#' /etc/fstab | awk '\$3 == "nfs" {print \$1 ";" \$2}')
#echo \$montagens

for linha in \$montagens; do
    origem=\$(echo "\$linha" | cut -d';' -f1)
    destino=\$(echo "\$linha" | cut -d';' -f2)

    # Debug: mostrar origem/destino
    #echo "XXX origem: \$origem"
    #echo "XXX destino: \$destino"

    if [ ! -d "\$destino" ]; then
        echo "Ponto de montagem \$destino não existe. Pulando."
        continue
    fi

    if mountpoint -q "\$destino"; then
        echo "\$destino já está montado. Pulando."
        continue
    fi

    echo "Tentando montar \$origem em \$destino ..."
    start_time=\$(date +%s)

    #exit 33   # <<< só usar se quiser interromper para testar
    while true; do
        mount -t nfs "\$origem" "\$destino"
        if mountpoint -q "\$destino"; then
            echo "\$destino montado com sucesso."
            break
        fi

        now=\$(date +%s)
        elapsed=\$(( now - start_time ))

        if [ \$elapsed -ge \$MAX_WAIT ]; then
            echo "ERRO: Não foi possível montar \$destino após 4 horas."
            exit 1
        fi

        echo "Falha ao montar \$destino. Tentando novamente em \$INTERVAL segundos..."
        sleep \$INTERVAL
    done
done

EOF

msg="### Todas as montagens NFS concluídas ###"
ecflow_client --label=Info1 "$msg" > /dev/null 2>&1
msg="O processo terminou em: $(date)"
ecflow_client --label=Info2 "$msg" > /dev/null 2>&1
ecflow_client --event Mata_SAFO

