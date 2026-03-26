#!/bin/bash
# @file start-zenfocus.sh
# @brief Inicializa o ambiente Zenfocus Gitea completo.
#
# @description
#   Carrega variáveis de ambiente, valida certificados TLS e sobe
#   todos os serviços via Docker Compose. Certificados são gerados
#   automaticamente se ausentes ou incompletos — sem precisar rodar
#   generate-certs.sh manualmente.
#
# @usage
#   ./start-zenfocus.sh [opções]
#
# @option --force-certs   Força regeneração dos certificados mesmo que existam.
# @option --no-certs      Pula a etapa de geração de certificados.
#
# @env GITEA_DOMAIN    Domínio do servidor Gitea. Padrão: gitea.zenfocus.com
# @env GITEA_SSH_PORT  Porta SSH do Gitea.        Padrão: 2222
# @env DNS_PORT        Porta do servidor DNS.      Padrão: 1053
# @env APP_PORT        Porta da aplicação web.     Padrão: 8080

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

FORCE_CERTS=false
SKIP_CERTS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --force-certs) FORCE_CERTS=true; shift ;;
    --no-certs)    SKIP_CERTS=true;  shift ;;
    -h|--help)
      grep '^# @' "$0" | sed 's/^# @//' | sed 's/^/  /'
      exit 0
      ;;
    *) echo "Opção desconhecida: $1  (use --help)"; exit 1 ;;
  esac
done

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

# @function certs_ok
# @brief Verifica se todos os arquivos de certificado existem e não estão vazios.
# @param $@  Lista de caminhos de arquivos a verificar.
certs_ok() {
  for f in "$@"; do
    [[ -f "$f" && -s "$f" ]] || return 1
  done
  return 0
}

# @function generate_certs
# @brief Gera certificados via script local ou container Docker como fallback.
# @param $1  "--force" para regenerar, "" para geração normal.
generate_certs() {
  local flags="${1:-}"
  local cert_script="${SCRIPT_DIR}/ca/generate-certs.sh"

  if [[ -x "$cert_script" ]]; then
    # Preferência: script local (mais rápido, sem build de imagem)
    # shellcheck disable=SC2086
    GITEA_DOMAIN="${DOMAIN}" CA_DIR="${SSL_DIR}" \
      bash "$cert_script" --no-restart $flags
  else
    # Fallback: container Docker (usado em CI ou quando Alpine não está disponível)
    log_warn "ca/generate-certs.sh não encontrado — usando container Docker."
    local compose_flags=""
    [[ "$flags" == *"--force"* ]] && compose_flags="-e FORCE=true"
    # shellcheck disable=SC2086
    docker compose run --rm --build $compose_flags ca
  fi
}

# ─── Banner ──────────────────────────────────────────────────────────────────

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     Zenfocus Gitea · Inicialização       ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── 1. Variáveis de ambiente ────────────────────────────────────────────────

log_step "Carregando variáveis de ambiente"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
  log_ok "Variáveis carregadas de .env"
else
  log_warn ".env não encontrado — usando valores padrão."
  export GITEA_DOMAIN="${GITEA_DOMAIN:-gitea.zenfocus.com}"
  export GITEA_SSH_PORT="${GITEA_SSH_PORT:-2222}"
  export DNS_PORT="${DNS_PORT:-1053}"
  export APP_PORT="${APP_PORT:-8080}"
fi

DOMAIN="${GITEA_DOMAIN:-gitea.zenfocus.com}"
SSL_DIR="${SCRIPT_DIR}/gitea/ssl"

# ─── 2. Certificados TLS ─────────────────────────────────────────────────────

log_step "Verificando certificados TLS"

# Arquivos obrigatórios para proxy e Gitea funcionarem
CERT_FILES=(
  "${SSL_DIR}/ca.crt"
  "${SSL_DIR}/ca.key"
  "${SSL_DIR}/${DOMAIN}.crt"
  "${SSL_DIR}/${DOMAIN}.key"
)

if [[ "$SKIP_CERTS" == true ]]; then
  log_warn "Etapa de certificados ignorada (--no-certs)."

elif [[ "$FORCE_CERTS" == true ]]; then
  log_warn "Regeneração forçada (--force-certs)."
  generate_certs "--force"

elif certs_ok "${CERT_FILES[@]}"; then
  log_ok "Certificados encontrados — nenhuma ação necessária."
  for f in "${CERT_FILES[@]}"; do
    log_info "$(basename "$f")  ($(du -sh "$f" | cut -f1))"
  done

else
  # Detecta e exibe quais arquivos estão faltando
  log_warn "Certificados ausentes ou incompletos — gerando automaticamente:"
  for f in "${CERT_FILES[@]}"; do
    if [[ ! -f "$f" || ! -s "$f" ]]; then
      log_info "  ✗  $(basename "$f")  ← faltando"
    fi
  done
  echo ""
  generate_certs ""
fi

# ─── 3. Serviços Docker ──────────────────────────────────────────────────────

log_step "Iniciando serviços"
docker compose up -d dns db gitea proxy app
log_ok "Todos os serviços iniciados."

# ─── Resumo ──────────────────────────────────────────────────────────────────

SSH_PORT="${GITEA_SSH_PORT:-2222}"
APP_PORT="${APP_PORT:-8080}"

echo -e "\n${BOLD}  ✅  Ambiente pronto!${RESET}\n"
printf "  %-22s %s\n" "Gitea (Web)"  "https://${DOMAIN}"
printf "  %-22s %s\n" "Gitea (SSH)"  "ssh://git@${DOMAIN}:${SSH_PORT}"
printf "  %-22s %s\n" "Aplicação"    "http://www.zenfocus.com:${APP_PORT}"
echo ""
echo "  Logs em tempo real:"
echo "    docker compose logs -f"
echo ""
echo -e "  ${YELLOW}Nota:${RESET} o Gitea pode levar alguns minutos para inicializar."
echo ""