#!/bin/bash -l
#
# Script to kill ICONLAM operational processes before running
# the model, including processes running on the compute nodes.
#
# Author: CT Neris/CC Alana, 20240228
# Refactored for Cray / OpenMPI 5
#-------------------------------------------------------

if [ $# -ne 1 ]; then
    echo
    echo "Entre com o modo desejado:"
    echo "  $0 all   - mata processos 04/05, ICON e PRTE no login e nos nós"
    echo "  $0 login - mata processos 04/05, ICON e PRTE somente no login"
    echo "  $0 proc  - mata somente processos de execução do ICON"
    echo
    exit 1
fi

MODE="$1"

# ============================================================
# Configuration
# ============================================================

FIRST_NODE=1
LAST_NODE=40

NODES=$(printf "cn%02d," $(seq "${FIRST_NODE}" "${LAST_NODE}") | sed 's/,$//')
ICON_BINARY="${ICONMODEL_DIR}/icon_"

# ============================================================
# Kill operational scripts on login node
# ============================================================

kill_operational_scripts()
{
    echo
    echo "====== Killing operational scripts at Login Node ======"
    echo

    ecflow_info "Matando processos dos scripts 04/05 no nó de login."

    # 04 - preprocessing
    pkill -TERM -f "04.*iconlam" 2>/dev/null || true

    # 05 - model execution / post-processing
    pkill -TERM -f "05.*iconlam" 2>/dev/null || true

    sleep 2
}

# ============================================================
# Kill ICON execution on login node
# ============================================================

kill_login_processes()
{
    echo
    echo "====== Killing ICON processes at Login Node ======"
    echo

    ecflow_info "Matando processos do ICON no nó de login."

    kill_operational_scripts

    # OpenMPI 5 / PRRTE launcher
    pkill -TERM -f "[/]prterun.*${ICONMODEL_DIR}/icon_" 2>/dev/null || true

    sleep 3
}

# ============================================================
# Kill ICON processes on compute nodes
# ============================================================

kill_compute_processes()
{
    echo
    echo "====== Cleaning ICON processes on Compute Nodes ======"
    echo
    echo "Nodes: ${NODES}"
    echo

    ecflow_info "Verificando e limpando processos do ICON nos nós de execução."

    pdsh -w "${NODES}" \
        "pkill -TERM -f '${ICON_BINARY}' 2>/dev/null || true"

    sleep 3

    REMAINING=$(pdsh -w "${NODES}" \
        "pgrep -af '${ICON_BINARY}' 2>/dev/null || true")

    if [ -n "${REMAINING}" ]; then
        echo
        echo "WARNING: ICON processes still running:"
        echo "${REMAINING}"
        echo

        ecflow_info "WARNING: Ainda existem processos ICON. Tentando encerramento forçado."

        pdsh -w "${NODES}" \
            "pkill -KILL -f '${ICON_BINARY}' 2>/dev/null || true"

        sleep 2
    fi
}

# ============================================================
# Check for remaining PRTE daemons
# ============================================================

check_prted()
{
    echo
    echo "====== Checking PRTE daemons on Compute Nodes ======"
    echo

    ORPHAN_PRTED=$(pdsh -w "${NODES}" \
        "pgrep -af '[/]prted' 2>/dev/null || true")

    if [ -n "${ORPHAN_PRTED}" ]; then
        echo
        echo "WARNING: PRTE daemons still running:"
        echo "${ORPHAN_PRTED}"
        echo

        ecflow_info "WARNING: Existem processos prted remanescentes nos nós."
    else
        echo
        echo "No orphan PRTE daemons found."
        echo

        ecflow_info "Nenhum processo prted remanescente encontrado."
    fi
}

# ============================================================
# Main action
# ============================================================

case "${MODE}" in
    all)
        kill_login_processes
        kill_compute_processes
        check_prted
        ;;

    login)
        kill_login_processes
        ;;

    proc)
        echo
        echo "====== Killing ICON runtime ======"
        echo

        ecflow_info "Matando somente processos de execução do ICON."

        # 05_run_iconlam
        pkill -TERM -f "[/]05_run_iconlam.sh" 2>/dev/null || true

        # OpenMPI / PRRTE launcher
        pkill -TERM -f "[/]prterun.*${ICONMODEL_DIR}/icon_" 2>/dev/null || true

        sleep 3

        kill_compute_processes
        check_prted
        ;;

    *)
        echo
        echo "ERROR: Mode '${MODE}' not found."
        echo "Valid modes: all, login, proc."
        echo

        ecflow_info \
            "ERROR: Modo '${MODE}' não encontrado. Use: all, login ou proc."

        exit 2
        ;;
esac

# ============================================================
# Check compute nodes
# ============================================================

echo
echo "====== Verifying Compute Nodes ======"
echo

ecflow_info \
    "Checando status dos nós ${FIRST_NODE} a ${LAST_NODE}."

TMP_NODES="/tmp/iconlam_nodes_$$.txt"

pdsh -w "${NODES}" uptime > "${TMP_NODES}" 2>&1

NUMBER_OF_NODES=$(grep -c '^cn[0-9][0-9]:' "${TMP_NODES}")

NODES_OK=$(grep '^cn[0-9][0-9]:' "${TMP_NODES}" |
          awk -F: '{print $1}' |
          sort)

rm -f "${TMP_NODES}"

if [ "${NUMBER_OF_NODES}" -ge "${LAST_NODE}" ]; then
    echo
    echo "====== All compute nodes are available ======"
    echo
    echo "${NODES_OK}"
    echo

    ecflow_info \
        "Todos os nós (${NUMBER_OF_NODES}/${LAST_NODE}) disponíveis e ON."
else
    echo
    echo "====== WARNING: Some compute nodes are unavailable ======"
    echo
    echo "Available nodes: ${NUMBER_OF_NODES}/${LAST_NODE}"
    echo "${NODES_OK}"
    echo

    ecflow_info \
        "WARNING: Número de nós disponíveis: ${NUMBER_OF_NODES}/${LAST_NODE}."
fi

# ============================================================
# Check NFS mounts on dpns41
# ============================================================

echo
echo "====== Verifying NFS mounts on dpns41 ======"
echo

ecflow_info "Checando status das partições do nó de login."

sshpass -p '@dmd@40' ssh root@10.13.100.41 << 'EOF'

MAX_WAIT=$((4 * 3600))
INTERVAL=10

MONTAGENS=$(grep -v '^#' /etc/fstab |
            awk '$3 == "nfs" {print $1 ";" $2}')

for LINHA in ${MONTAGENS}; do
    ORIGEM=$(echo "${LINHA}" | cut -d';' -f1)
    DESTINO=$(echo "${LINHA}" | cut -d';' -f2)

    if [ ! -d "${DESTINO}" ]; then
        echo "Ponto de montagem ${DESTINO} não existe. Pulando."
        continue
    fi

    if mountpoint -q "${DESTINO}"; then
        echo "${DESTINO} já está montado. Pulando."
        continue
    fi

    echo "Tentando montar ${ORIGEM} em ${DESTINO}..."

    START_TIME=$(date +%s)

    while true; do
        mount -t nfs "${ORIGEM}" "${DESTINO}"

        if mountpoint -q "${DESTINO}"; then
            echo "${DESTINO} montado com sucesso."
            break
        fi

        NOW=$(date +%s)
        ELAPSED=$((NOW - START_TIME))

        if [ "${ELAPSED}" -ge "${MAX_WAIT}" ]; then
            echo "ERRO: Não foi possível montar ${DESTINO} após 4 horas."
            exit 1
        fi

        echo "Falha ao montar ${DESTINO}."
        echo "Tentando novamente em ${INTERVAL} segundos..."

        sleep "${INTERVAL}"
    done
done

EOF

RET=$?

if [ "${RET}" -ne 0 ]; then
    ecflow_info \
        "ERROR: Falha na verificação/montagem das partições NFS em dpns41."
    exit "${RET}"
fi

# ============================================================
# End
# ============================================================

ecflow_info \
    "### Todas as montagens NFS concluídas ###" \
    "O processo terminou em: $(date)"

ecflow_event Mata_SAFO

exit 0
