#!/bin/bash
# @file start-zenfocus.sh
# @brief Start the full Zenfocus Gitea environment.
#
# @description
#   Loads environment variables, validates TLS certificates and brings up
#   all services via Docker Compose. Certificates are generated automatically
#   if missing or incomplete — no need to run generate-certs.sh manually.
#
# @usage
#   ./start-zenfocus.sh [options]
#
# @option --force-certs   Force regeneration of certificates even if present.
# @option --no-certs      Skip the certificate generation step.
#
# @env GITEA_DOMAIN    Gitea server domain. Default: gitea.zenfocus.com
# @env GITEA_SSH_PORT  Gitea SSH port.       Default: 2222
# @env DNS_PORT        DNS server port.      Default: 1053

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

COMPOSE_CMD="docker compose"

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

# @function reset_runner_registration
# @brief Remove credencial .runner stale para forcar novo registro do act_runner.
reset_runner_registration() {
  local runner_data_dir="${SCRIPT_DIR}/runner/data"

  if [[ ! -d "$runner_data_dir" ]]; then
    return 0
  fi

  # Remove via container utilitario para evitar falha por permissao root no host.
  docker run --rm -v "${runner_data_dir}:/data" alpine sh -c 'rm -f /data/.runner' >/dev/null 2>&1 || true
}

# ─── Banner ──────────────────────────────────────────────────────────────────

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     Zenfocus Gitea · Inicialização       ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── 1. Variáveis de ambiente ────────────────────────────────────────────────

log_step "Loading environment variables"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
  log_ok "Variables loaded from .env"
else
  log_warn ".env not found — using default values."
  export GITEA_DOMAIN="${GITEA_DOMAIN:-gitea.zenfocus.com}"
  export GITEA_SSH_PORT="${GITEA_SSH_PORT:-2222}"
  export DNS_PORT="${DNS_PORT:-1053}"
fi

DOMAIN="${GITEA_DOMAIN:-gitea.zenfocus.com}"
SSL_DIR="${SCRIPT_DIR}/gitea/ssl"

# ─── 2. Certificados TLS ─────────────────────────────────────────────────────

log_step "Checking TLS certificates"

# Arquivos obrigatórios para proxy e Gitea funcionarem
CERT_FILES=(
  "${SSL_DIR}/ca.crt"
  "${SSL_DIR}/ca.key"
  "${SSL_DIR}/${DOMAIN}.crt"
  "${SSL_DIR}/${DOMAIN}.key"
)

if [[ "$SKIP_CERTS" == true ]]; then
  log_warn "Certificate step skipped (--no-certs)."

elif [[ "$FORCE_CERTS" == true ]]; then
  log_warn "Forced regeneration (--force-certs)."
  generate_certs "--force"

elif certs_ok "${CERT_FILES[@]}"; then
  log_ok "Certificates found — no action required."
  for f in "${CERT_FILES[@]}"; do
    log_info "$(basename "$f")  ($(du -sh "$f" | cut -f1))"
  done

else
  # Detecta e exibe quais arquivos estão faltando
  log_warn "Certificates missing or incomplete — generating automatically:"
  for f in "${CERT_FILES[@]}"; do
    if [[ ! -f "$f" || ! -s "$f" ]]; then
      log_info "  ✗  $(basename "$f")  ← missing"
    fi
  done
  echo ""
  generate_certs ""
fi

# ─── 3. Serviços Docker ──────────────────────────────────────────────────────

log_step "Starting services"
docker compose up -d --remove-orphans dns db gitea proxy
log_ok "All services started."

# ─── 4. Act Runner (opcional) ───────────────────────────────────────────────

if [[ -n "${ACT_RUNNER_REGISTRATION_TOKEN:-}" ]]; then
  log_step "Starting Gitea Actions runner"
  $COMPOSE_CMD --profile actions up -d --no-deps act_runner >/dev/null

  # Caso o runner esteja com credencial stale, ele entra em loop "unregistered runner".
  sleep 2
  if $COMPOSE_CMD logs --tail=40 act_runner 2>/dev/null | grep -q "unregistered runner"; then
    log_warn "Runner with stale registration detected. Re-registering..."
    $COMPOSE_CMD --profile actions stop act_runner >/dev/null 2>&1 || true
    reset_runner_registration
    $COMPOSE_CMD --profile actions up -d --no-deps act_runner >/dev/null
  fi

  log_ok "Actions runner started."
else
  log_warn "ACT_RUNNER_REGISTRATION_TOKEN is empty. Runner was not started."
fi

# ─── Resumo ──────────────────────────────────────────────────────────────────

SSH_PORT="${GITEA_SSH_PORT:-2222}"

echo -e "\n${BOLD}  ✅  Environment ready!${RESET}\n"
printf "  %-22s %s\n" "Gitea (Web)"  "https://${DOMAIN}"
printf "  %-22s %s\n" "Gitea (SSH)"  "ssh://git@${DOMAIN}:${SSH_PORT}"
echo ""
echo "  Live logs:"
echo "    docker compose logs -f"
if [[ -n "${ACT_RUNNER_REGISTRATION_TOKEN:-}" ]]; then
  echo "    docker compose logs -f act_runner"
fi
echo ""
echo -e "  ${YELLOW}Note:${RESET} Gitea may take several minutes to finish starting up."
echo ""