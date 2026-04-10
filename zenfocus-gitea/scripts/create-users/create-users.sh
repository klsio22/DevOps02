#!/bin/bash
# @file create-users.sh
# @brief Cria usuários no Gitea a partir de um arquivo JSON.
#
# @description
#   Lê um arquivo JSON com a lista de usuários e os cria no Gitea
#   via API REST (modo padrão) ou via CLI do container Docker.
#
#   Comportamento:
#     - Usuários já existentes são ignorados (idempotente)
#     - Erros de um usuário não interrompem os demais
#     - Exibe resumo ao final com totais de criados/pulados/falhos
#
# @usage
#   ./create-users.sh [opções]
#
# @option --mode api|cli        Modo de criação.           Padrão: api
# @option --file <json>         Arquivo JSON de usuários.  Padrão: users.json
# @option --gitea-url <url>     URL base do Gitea.         Padrão: https://gitea.zenfocus.com
# @option --token <token>       Token de admin da API.     Padrão: $GITEA_ADMIN_TOKEN
# @option --container <nome>    Nome do container Docker.  Padrão: zenfocus-gitea
#
# @example
#   # Modo API com token via env
#   GITEA_ADMIN_TOKEN=abc123 ./create-users.sh
#
#   # Modo API com token via argumento e arquivo customizado
#   ./create-users.sh --token abc123 --file turma-a.json
#
#   # Modo CLI (sem precisar de token)
#   ./create-users.sh --mode cli

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/.env}"

# ─── Defaults ────────────────────────────────────────────────────────────────

MODE="api"
USERS_FILE="users.json"
GITEA_URL="${GITEA_URL:-https://gitea.zenfocus.com}"
ADMIN_TOKEN="${GITEA_ADMIN_TOKEN:-}"
CONTAINER="${GITEA_CONTAINER:-zenfocus-gitea}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
  ADMIN_TOKEN="${GITEA_ADMIN_TOKEN:-$ADMIN_TOKEN}"
  GITEA_URL="${GITEA_URL:-$GITEA_URL}"
  CONTAINER="${GITEA_CONTAINER:-$CONTAINER}"
fi

# ─── Argumentos ──────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case $1 in
    --mode)      MODE="$2";        shift 2 ;;
    --file)      USERS_FILE="$2";  shift 2 ;;
    --gitea-url) GITEA_URL="$2";   shift 2 ;;
    --token)     ADMIN_TOKEN="$2"; shift 2 ;;
    --container) CONTAINER="$2";   shift 2 ;;
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
log_skip()  { echo -e "  ${YELLOW}⊘${RESET}  $* ${YELLOW}(já existe — pulando)${RESET}"; }
log_warn()  { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
log_error() { echo -e "  ${RED}✖${RESET}  $*" >&2; }
log_info()  { echo -e "     $*"; }

# ─── Contadores ──────────────────────────────────────────────────────────────

COUNT_OK=0
COUNT_SKIP=0
COUNT_FAIL=0

# ─── Funções ─────────────────────────────────────────────────────────────────

# @function check_deps
# @brief Verifica se as dependências necessárias estão instaladas.
check_deps() {
  local missing=()
  command -v docker  &>/dev/null || missing+=("docker")
  command -v curl    &>/dev/null || missing+=("curl")
  command -v python3 &>/dev/null || missing+=("python3")

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Dependências ausentes: ${missing[*]}"
    log_info "Instale com: sudo apt install ${missing[*]}"
    exit 1
  fi
}

# @function parse_json_users
# @brief Extrai campos do JSON e imprime uma linha por usuário.
# @stdout  username|email|password|full_name|visibility|must_change_password
parse_json_users() {
  python3 - "$USERS_FILE" << 'PYTHON'
import json, sys

try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
except FileNotFoundError:
    print(f"ERRO: arquivo '{sys.argv[1]}' não encontrado.", file=sys.stderr)
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"ERRO: JSON inválido — {e}", file=sys.stderr)
    sys.exit(1)

for u in data.get("users", []):
    username  = u.get("username", "").strip()
    email     = u.get("email", "").strip()
    password  = u.get("password", "").strip()
    full_name = u.get("full_name", username).strip()
    visibility = u.get("visibility", "public").strip()
    must_change = str(u.get("must_change_password", False)).lower()

    if not username or not email or not password:
        print(f"AVISO: usuário incompleto ignorado: {u}", file=sys.stderr)
        continue

    print(f"{username}|{email}|{password}|{full_name}|{visibility}|{must_change}")
PYTHON
}

# @function create_user_api
# @brief Cria um usuário via API REST do Gitea.
# @param $1 username  $2 email  $3 password
# @param $4 full_name $5 visibility $6 must_change_password
create_user_api() {
  local username="$1" email="$2" password="$3"
  local full_name="$4" visibility="$5" must_change="$6"

  local http_code
  local payload
  local resp_file
  resp_file="$(mktemp)"

  payload=$(USERNAME="$username" EMAIL="$email" PASSWORD="$password" FULL_NAME="$full_name" VISIBILITY="$visibility" MUST_CHANGE="$must_change" python3 - <<'PY'
import json
import os

payload = {
    'username': os.environ['USERNAME'],
    'email': os.environ['EMAIL'],
    'password': os.environ['PASSWORD'],
    'full_name': os.environ['FULL_NAME'],
    'login_name': os.environ['USERNAME'],
    'visibility': os.environ['VISIBILITY'],
    'must_change_password': os.environ['MUST_CHANGE'].lower() == 'true',
    'send_notify': False,
    'source_id': 0,
}
print(json.dumps(payload))
PY
)

  http_code=$(curl -s -o "$resp_file" -w "%{http_code}" \
    --insecure \
    -X POST "${GITEA_URL}/api/v1/admin/users" \
    -H "Content-Type: application/json" \
    -H "Authorization: token ${ADMIN_TOKEN}" \
    -d "$payload")

  local body
  body=$(cat "$resp_file" 2>/dev/null || echo "{}")
  rm -f "$resp_file"

  case "$http_code" in
    201)
      log_ok "${username} criado  — ${email}"
      COUNT_OK=$((COUNT_OK + 1))
      ;;
    422)
      local msg
      msg=$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('message',''))" <<< "$body" 2>/dev/null || echo "")
      if echo "$msg" | grep -qi "already\|exist\|duplicate\|taken"; then
        log_skip "${username}"
        COUNT_SKIP=$((COUNT_SKIP + 1))
      else
        log_error "${username} → erro 422: ${msg}"
        COUNT_FAIL=$((COUNT_FAIL + 1))
      fi
      ;;
    401|403)
      log_error "Sem permissão (${http_code}). Verifique o token de admin."
      exit 1
      ;;
    *)
      local msg
      msg=$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('message', sys.stdin.read()))" <<< "$body" 2>/dev/null || echo "$body")
      log_error "${username} → HTTP ${http_code}: ${msg}"
      COUNT_FAIL=$((COUNT_FAIL + 1))
      ;;
  esac
}

# @function create_user_cli
# @brief Cria um usuário via CLI gitea dentro do container Docker.
# @param $1 username  $2 email  $3 password  $4 must_change_password
create_user_cli() {
  local username="$1" email="$2" password="$3" must_change="$4"

  local output
  local cmd=(docker exec -u git "$CONTAINER" gitea admin user create \
    --username "$username" \
    --email    "$email" \
    --password "$password")

  if [[ "$must_change" == "true" ]]; then
    cmd+=(--must-change-password)
  fi

  if output=$("${cmd[@]}" 2>&1); then
    log_ok "${username} criado  — ${email}"
    COUNT_OK=$((COUNT_OK + 1))
  else
    if echo "$output" | grep -qi "already\|exist\|duplicate"; then
      log_skip "${username}"
      COUNT_SKIP=$((COUNT_SKIP + 1))
    else
      log_error "${username} → ${output}"
      COUNT_FAIL=$((COUNT_FAIL + 1))
    fi
  fi
}

# ─── Banner ──────────────────────────────────────────────────────────────────

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     Gitea · Criação de Usuários (JSON)   ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"
echo "  Modo      : ${MODE}"
echo "  Arquivo   : ${USERS_FILE}"
echo "  Gitea URL : ${GITEA_URL}"
[[ "$MODE" == "cli" ]] && echo "  Container : ${CONTAINER}"

# ─── Validações ──────────────────────────────────────────────────────────────

log_step "Validando dependências e configuração"

if [[ "$MODE" == "api" && -z "$ADMIN_TOKEN" ]]; then
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER}$"; then
    log_warn "Token não definido. Alternando para modo CLI usando o container '${CONTAINER}'."
    MODE="cli"
  else
    log_error "Token não definido."
    log_info "Use --token <token> ou exporte: export GITEA_ADMIN_TOKEN=seu_token"
    log_info "Para gerar: Gitea → Settings → Applications → Generate Token"
    exit 1
  fi
fi

if [[ "$MODE" == "api" ]]; then
  check_deps
else
  local_missing=()
  command -v docker  &>/dev/null || local_missing+=("docker")
  command -v python3 &>/dev/null || local_missing+=("python3")

  if [[ ${#local_missing[@]} -gt 0 ]]; then
    log_error "Dependências ausentes para modo CLI: ${local_missing[*]}"
    log_info "Instale com: sudo apt install ${local_missing[*]}"
    exit 1
  fi
fi

if [[ "$MODE" == "cli" ]]; then
  if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER}$"; then
    log_error "Container '${CONTAINER}' não encontrado ou não está rodando."
    log_info "Verifique com: docker ps"
    exit 1
  fi
  log_ok "Container '${CONTAINER}' acessível."
fi

if [[ ! -f "$USERS_FILE" ]]; then
  log_error "Arquivo '${USERS_FILE}' não encontrado."
  log_info "Crie o arquivo JSON com o formato:"
  cat << 'EXAMPLE'

  {
    "users": [
      {
        "username": "joao",
        "full_name": "João Silva",
        "email": "joao@empresa.com",
        "password": "Senha@2026!",
        "visibility": "public",
        "must_change_password": false
      }
    ]
  }

EXAMPLE
  exit 1
fi

log_ok "Arquivo '${USERS_FILE}' encontrado."

# ─── Processar usuários ───────────────────────────────────────────────────────

log_step "Criando usuários"

TOTAL=$(python3 -c "import json; d=json.load(open('${USERS_FILE}')); print(len(d.get('users',[])))")
log_info "Total de usuários no arquivo: ${TOTAL}"
echo ""

while IFS='|' read -r username email password full_name visibility must_change; do
  if [[ "$MODE" == "api" ]]; then
    create_user_api "$username" "$email" "$password" "$full_name" "$visibility" "$must_change"
  else
    create_user_cli "$username" "$email" "$password" "$must_change"
  fi
done < <(parse_json_users)

# ─── Resumo ──────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}  Resumo${RESET}"
echo "  ────────────────────────────"
printf "  ${GREEN}✔${RESET}  Criados  : %d\n" "$COUNT_OK"
printf "  ${YELLOW}⊘${RESET}  Pulados  : %d\n" "$COUNT_SKIP"
printf "  ${RED}✖${RESET}  Falhos   : %d\n"   "$COUNT_FAIL"
echo "  ────────────────────────────"
printf "     Total   : %d\n" "$TOTAL"
echo ""

# Listar usuários criados
if [[ "$MODE" == "api" && $COUNT_OK -gt 0 ]]; then
  echo "  Para listar todos os usuários:"
  echo "    curl -s -H 'Authorization: token ${ADMIN_TOKEN}' \\"
  echo "      ${GITEA_URL}/api/v1/admin/users?limit=50 | python3 -m json.tool | grep login"
elif [[ "$MODE" == "cli" && $COUNT_OK -gt 0 ]]; then
  echo "  Para listar todos os usuários:"
  echo "    docker exec ${CONTAINER} gitea admin user list"
fi

echo ""

# Exit code com falha se algum usuário falhou
[[ $COUNT_FAIL -eq 0 ]]
