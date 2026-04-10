#!/usr/bin/env bash
set -euo pipefail

# restore-db.sh
# Restaura backups MySQL (.sql ou .sql.gz) no ambiente zenfocus-gitea.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/.env}"
DB_CONTAINER="${DB_CONTAINER:-zenfocus-gitea-db}"

INPUT_FILE=""
SELECTED_DB=""
USE_ROOT=false
CREATE_DB=false
NO_TARGET_DB=false

usage() {
  cat <<EOF
Uso: $0 --file <arquivo.sql|arquivo.sql.gz> [opcoes]

Opcoes:
  --file <caminho>       Arquivo de backup (.sql ou .sql.gz)
  --database <nome>      Banco de destino (padrao: MYSQL_DATABASE do .env)
  --container <nome>     Nome do container MySQL (padrao: $DB_CONTAINER)
  --root                 Usa credenciais de root em vez de MYSQL_USER
  --create-db            Cria banco destino se nao existir
  --no-target-db         Restaura sem selecionar banco (uso comum para --all-databases)
  -h, --help             Exibe esta ajuda

Variaveis (carregadas de .env quando existir):
  MYSQL_DATABASE
  MYSQL_USER
  MYSQL_PASSWORD
  MYSQL_ROOT_PASSWORD

Exemplos:
  $0 --file ./backups/db/zenfocus_20260409_234736.sql.gz
  $0 --file ./backups/db/zenfocus_20260409_234736.sql --database zenfocus --create-db
  $0 --file ./backups/db/all_20260409_010000.sql.gz --no-target-db --root
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      INPUT_FILE="${2:-}"
      if [[ -z "$INPUT_FILE" ]]; then
        echo "Erro: informe o caminho apos --file." >&2
        exit 1
      fi
      shift 2
      ;;
    --database)
      SELECTED_DB="${2:-}"
      if [[ -z "$SELECTED_DB" ]]; then
        echo "Erro: informe o nome do banco apos --database." >&2
        exit 1
      fi
      shift 2
      ;;
    --container)
      DB_CONTAINER="${2:-}"
      if [[ -z "$DB_CONTAINER" ]]; then
        echo "Erro: informe o nome apos --container." >&2
        exit 1
      fi
      shift 2
      ;;
    --root)
      USE_ROOT=true
      shift
      ;;
    --create-db)
      CREATE_DB=true
      shift
      ;;
    --no-target-db)
      NO_TARGET_DB=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Opcao desconhecida: $1" >&2
      echo "Use --help para ver as opcoes." >&2
      exit 1
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "Erro: Docker nao encontrado no PATH." >&2
  exit 1
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

if [[ -z "$INPUT_FILE" ]]; then
  echo "Erro: informe um arquivo com --file." >&2
  usage
  exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Erro: arquivo nao encontrado: $INPUT_FILE" >&2
  exit 1
fi

if [[ "$INPUT_FILE" != *.sql && "$INPUT_FILE" != *.sql.gz ]]; then
  echo "Erro: arquivo invalido. Use extensao .sql ou .sql.gz." >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -Fxq "$DB_CONTAINER"; then
  echo "Erro: container '$DB_CONTAINER' nao esta em execucao." >&2
  echo "Dica: inicie a stack com docker compose up -d." >&2
  exit 1
fi

if [[ "$USE_ROOT" == true ]]; then
  DB_USER="root"
  DB_PASS="${MYSQL_ROOT_PASSWORD:-}"
else
  DB_USER="${MYSQL_USER:-root}"
  DB_PASS="${MYSQL_PASSWORD:-${MYSQL_ROOT_PASSWORD:-}}"
fi

if [[ -z "$DB_PASS" ]]; then
  echo "Erro: senha nao definida no .env para o usuario selecionado." >&2
  exit 1
fi

if [[ "$NO_TARGET_DB" == false ]]; then
  SELECTED_DB="${SELECTED_DB:-${MYSQL_DATABASE:-}}"
  if [[ -z "$SELECTED_DB" ]]; then
    echo "Erro: banco nao definido. Use --database ou --no-target-db." >&2
    exit 1
  fi
fi

MYSQL_TARGET_ARGS=()
if [[ "$NO_TARGET_DB" == false ]]; then
  MYSQL_TARGET_ARGS+=("$SELECTED_DB")
fi

if [[ "$CREATE_DB" == true && "$NO_TARGET_DB" == false ]]; then
  echo "Garantindo existencia do banco '$SELECTED_DB'..."
  docker exec -e MYSQL_PWD="$DB_PASS" "$DB_CONTAINER" \
    mysql -u"$DB_USER" -e "CREATE DATABASE IF NOT EXISTS \`$SELECTED_DB\`;"
fi

echo "Iniciando restore do banco..."
echo "Container : $DB_CONTAINER"
echo "Usuario   : $DB_USER"
echo "Arquivo   : $INPUT_FILE"
if [[ "$NO_TARGET_DB" == false ]]; then
  echo "Destino   : $SELECTED_DB"
else
  echo "Destino   : servidor MySQL (sem banco alvo fixo)"
fi

if [[ "$INPUT_FILE" == *.sql.gz ]]; then
  gzip -cd "$INPUT_FILE" | docker exec -i -e MYSQL_PWD="$DB_PASS" "$DB_CONTAINER" \
    mysql -u"$DB_USER" "${MYSQL_TARGET_ARGS[@]}"
else
  cat "$INPUT_FILE" | docker exec -i -e MYSQL_PWD="$DB_PASS" "$DB_CONTAINER" \
    mysql -u"$DB_USER" "${MYSQL_TARGET_ARGS[@]}"
fi

echo "Restore concluido com sucesso."