#!/bin/bash
# @file update-remote.sh
# @brief Inicia túnel ngrok TCP para SSH do Gitea e atualiza o remote no EC2.
#
# @description
#   Verifica se já existe um túnel TCP no ngrok. Se não existir, inicia
#   automaticamente com "ngrok tcp 2222". Depois atualiza o remote do
#   repositório no EC2 com a porta atual do túnel.
#
# @usage
#   ./update-remote.sh
#
# @env EC2_HOST    Host do EC2.        Padrão: ec2-3-233-229-119.compute-1.amazonaws.com
# @env EC2_USER    Usuário do EC2.     Padrão: admin
# @env PEM_KEY     Chave PEM SSH.      Padrão: /home/knlinux/.../zenfocus.pem
# @env REPO_PATH   Repo no EC2.        Padrão: ~/pulsefocus-app
# @env GITEA_PORT  Porta SSH do Gitea. Padrão: 2222
# @env NGROK_HOST  Host ngrok TCP.     Padrão: autodetectado

set -euo pipefail

# ─── Configuração ────────────────────────────────────────────────────────────

EC2_HOST="${EC2_HOST:-ec2-3-233-229-119.compute-1.amazonaws.com}"
EC2_USER="${EC2_USER:-admin}"
PEM_KEY="${PEM_KEY:-/home/knlinux/Documents/www/utfpr/zenfocus-server/zenfocus.pem}"
REPO_PATH="${REPO_PATH:-~/pulsefocus-app}"
GITEA_PORT="${GITEA_PORT:-2222}"
NGROK_API="http://localhost:4040/api/tunnels"
GITEA_REPO="${GITEA_REPO:-admin/pulsefocus-app}"

# ─── Helpers de log ──────────────────────────────────────────────────────────

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

log_step()  { echo -e "\n${BOLD}${CYAN}▶ $*${RESET}"; }
log_ok()    { echo -e "  ${GREEN}✔${RESET}  $*"; }
log_warn()  { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
log_error() { echo -e "\n  ${RED}✖${RESET}  $*" >&2; }
log_info()  { echo -e "     $*"; }

# ─── Funções ─────────────────────────────────────────────────────────────────

# @function get_tcp_tunnel
# @brief Extrai a URL do túnel TCP da API do ngrok.
# @returns URL completa ex: tcp://0.tcp.sa.ngrok.io:17180 ou vazio
get_tcp_tunnel() {
  curl -s "$NGROK_API" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for t in data.get('tunnels', []):
    url = t.get('public_url', '')
    if url.startswith('tcp://'):
        print(url)
        sys.exit(0)
print('')
" 2>/dev/null
}

# @function start_ngrok_tcp
# @brief Inicia ngrok TCP em background e aguarda o túnel ficar disponível.
start_ngrok_tcp() {
  log_warn "Nenhum túnel TCP encontrado — iniciando ngrok tcp ${GITEA_PORT}..."

  # Verifica se o ngrok está instalado
  if ! command -v ngrok &>/dev/null; then
    log_error "ngrok não está instalado."
    log_info "Instale com: curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null"
    log_info "             echo 'deb https://ngrok-agent.s3.amazonaws.com buster main' | sudo tee /etc/apt/sources.list.d/ngrok.list"
    log_info "             sudo apt update && sudo apt install ngrok"
    exit 1
  fi

  # Inicia em background (mata sessão anterior se existir)
  pkill -f "ngrok tcp ${GITEA_PORT}" 2>/dev/null || true
  nohup ngrok tcp "${GITEA_PORT}" > /tmp/ngrok.log 2>&1 &
  NGROK_PID=$!

  log_info "ngrok PID: ${NGROK_PID} — aguardando túnel TCP inicializar..."

  # Aguarda até 15s pelo túnel TCP aparecer na API
  local attempts=0
  while [[ $attempts -lt 15 ]]; do
    sleep 1
    TCP_URL=$(get_tcp_tunnel)
    if [[ -n "$TCP_URL" ]]; then
      log_ok "Túnel TCP iniciado: ${TCP_URL}"
      return 0
    fi
    attempts=$((attempts + 1))
    echo -n "."
  done
  echo ""

  log_error "Timeout aguardando ngrok TCP. Veja logs: cat /tmp/ngrok.log"
  exit 1
}

# ─── 1. Verificar chave PEM ───────────────────────────────────────────────────

log_step "Verificando chave PEM"

if [[ ! -f "$PEM_KEY" ]]; then
  log_error "Chave PEM não encontrada: ${PEM_KEY}"
  exit 1
fi

chmod 600 "$PEM_KEY"
log_ok "Chave: ${PEM_KEY}"

# ─── 2. Garantir túnel TCP ───────────────────────────────────────────────────

log_step "Verificando túnel ngrok TCP"

# Verifica se API do ngrok está acessível
if ! curl -sf "$NGROK_API" > /dev/null 2>&1; then
  # ngrok não está rodando de forma alguma — inicia
  start_ngrok_tcp
else
  # ngrok está rodando — verifica se tem túnel TCP
  TCP_URL=$(get_tcp_tunnel)
  if [[ -z "$TCP_URL" ]]; then
    # Só tem HTTPS, precisa adicionar TCP
    start_ngrok_tcp
    TCP_URL=$(get_tcp_tunnel)
  else
    log_ok "Túnel TCP já ativo: ${TCP_URL}"
  fi
fi

# Recarrega após possível início
TCP_URL=$(get_tcp_tunnel)

# ─── 3. Extrair host e porta ─────────────────────────────────────────────────

log_step "Extraindo host e porta do túnel"

# TCP_URL formato: tcp://0.tcp.sa.ngrok.io:17180
NGROK_HOST=$(echo "$TCP_URL" | python3 -c "
import sys
url = sys.stdin.read().strip().replace('tcp://', '')
print(url.split(':')[0])
")

PORTA=$(echo "$TCP_URL" | python3 -c "
import sys
url = sys.stdin.read().strip()
print(url.split(':')[-1])
")

NEW_REMOTE="ssh://git@${NGROK_HOST}:${PORTA}/${GITEA_REPO}.git"

log_ok "Host  : ${NGROK_HOST}"
log_ok "Porta : ${PORTA}"
log_ok "Remote: ${NEW_REMOTE}"

# ─── 4. Atualizar remote no EC2 ──────────────────────────────────────────────

log_step "Atualizando remote no EC2"

ssh -i "$PEM_KEY" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    "${EC2_USER}@${EC2_HOST}" \
    "set -e; \
     mkdir -p ${REPO_PATH}; \
     if [ ! -d ${REPO_PATH}/.git ]; then \
       git -C ${REPO_PATH} init >/dev/null; \
     fi; \
     if git -C ${REPO_PATH} remote get-url origin >/dev/null 2>&1; then \
       git -C ${REPO_PATH} remote set-url origin '${NEW_REMOTE}'; \
     else \
       git -C ${REPO_PATH} remote add origin '${NEW_REMOTE}'; \
     fi"

log_ok "Remote atualizado."

# ─── 5. Testar git pull no EC2 ───────────────────────────────────────────────

log_step "Testando git pull no EC2"

if ssh -i "$PEM_KEY" \
       -o StrictHostKeyChecking=no \
       "${EC2_USER}@${EC2_HOST}" \
       "git -C ${REPO_PATH} pull"; then
  log_ok "git pull OK!"
else
  log_warn "git pull falhou — verifique se o Gitea está acessível."
  log_info "ngrok log: cat /tmp/ngrok.log"
fi

# ─── Resumo ──────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}  ✅  Concluído!${RESET}"
echo ""
printf "  %-20s %s\n" "Túnel TCP"  "${TCP_URL}"
printf "  %-20s %s\n" "Remote EC2" "${NEW_REMOTE}"
printf "  %-20s %s\n" "EC2"        "${EC2_USER}@${EC2_HOST}"
echo ""
echo "  Para ver o ngrok no navegador: http://localhost:4040"
echo ""