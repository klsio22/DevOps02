#!/usr/bin/env bash
set -euo pipefail

# backup-db.sh
# Cria backup do banco MySQL do ambiente zenfocus-gitea.
#
# Uso rapido:
#   ./scripts/backup-db.sh
#   ./scripts/backup-db.sh --all
#   ./scripts/backup-db.sh --database gitea --no-compress

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/.env}"
DB_CONTAINER="${DB_CONTAINER:-zenfocus-gitea-db}"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/backups/db}"

COMPRESS=true
BACKUP_ALL=false
SELECTED_DB=""

usage() {
  cat <<EOF
Uso: $0 [opcoes]

Opcoes:
  --all                  Faz dump de todos os bancos (mysqldump --all-databases)
  --database <nome>      Faz dump de um banco especifico
  --output-dir <caminho> Diretorio de saida (padrao: $OUTPUT_DIR)
  --container <nome>     Nome do container MySQL (padrao: $DB_CONTAINER)
  --no-compress          Gera arquivo .sql em vez de .sql.gz
  -h, --help             Exibe esta ajuda

Variaveis (carregadas de .env quando existir):
  MYSQL_DATABASE
  MYSQL_USER
  MYSQL_PASSWORD
  MYSQL_ROOT_PASSWORD

Exemplos:
  $0
  $0 --database zenfocus
  $0 --all --output-dir ./backups
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      BACKUP_ALL=true
      shift
      ;;
    --database)
      SELECTED_DB="${2:-}"
      if [[ -z "$SELECTED_DB" ]]; then
        echo "Erro: informe o nome do banco apos --database." >&2
        exit 1
      fi
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:-}"
      if [[ -z "$OUTPUT_DIR" ]]; then
        echo "Erro: informe o caminho apos --output-dir." >&2
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
    --no-compress)
      COMPRESS=false
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

if [[ "$BACKUP_ALL" == true && -n "$SELECTED_DB" ]]; then
  echo "Erro: use apenas uma das opcoes: --all ou --database." >&2
  exit 1
fi

if [[ "$BACKUP_ALL" == false ]]; then
  SELECTED_DB="${SELECTED_DB:-${MYSQL_DATABASE:-}}"
  if [[ -z "$SELECTED_DB" ]]; then
    echo "Erro: banco nao definido. Use --database ou configure MYSQL_DATABASE no .env." >&2
    exit 1
  fi
fi

DB_USER="${MYSQL_USER:-root}"
DB_PASS="${MYSQL_PASSWORD:-${MYSQL_ROOT_PASSWORD:-}}"

if [[ -z "$DB_PASS" ]]; then
  echo "Erro: senha nao definida. Configure MYSQL_PASSWORD ou MYSQL_ROOT_PASSWORD no .env." >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -Fxq "$DB_CONTAINER"; then
  echo "Erro: container '$DB_CONTAINER' nao esta em execucao." >&2
  echo "Dica: inicie a stack com docker compose up -d." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

timestamp="$(date +%Y%m%d_%H%M%S)"
backup_target="${SELECTED_DB:-all}"

if [[ "$COMPRESS" == true ]]; then
  output_file="$OUTPUT_DIR/${backup_target}_${timestamp}.sql.gz"
else
  output_file="$OUTPUT_DIR/${backup_target}_${timestamp}.sql"
fi

echo "Iniciando backup do banco..."
echo "Container : $DB_CONTAINER"
echo "Usuario   : $DB_USER"
echo "Destino   : $output_file"

# MySQL 8 pode exigir privilegio PROCESS ao tentar exportar tablespaces.
# A flag abaixo evita esse requisito para backups logicos comuns.
DUMP_COMMON_ARGS=(--single-transaction --quick --routines --triggers --no-tablespaces)

if [[ "$BACKUP_ALL" == true ]]; then
  if [[ "$COMPRESS" == true ]]; then
    docker exec -e MYSQL_PWD="$DB_PASS" "$DB_CONTAINER" \
      mysqldump -u"$DB_USER" "${DUMP_COMMON_ARGS[@]}" --all-databases \
      | gzip > "$output_file"
  else
    docker exec -e MYSQL_PWD="$DB_PASS" "$DB_CONTAINER" \
      mysqldump -u"$DB_USER" "${DUMP_COMMON_ARGS[@]}" --all-databases \
      > "$output_file"
  fi
else
  if [[ "$COMPRESS" == true ]]; then
    docker exec -e MYSQL_PWD="$DB_PASS" "$DB_CONTAINER" \
      mysqldump -u"$DB_USER" "${DUMP_COMMON_ARGS[@]}" "$SELECTED_DB" \
      | gzip > "$output_file"
  else
    docker exec -e MYSQL_PWD="$DB_PASS" "$DB_CONTAINER" \
      mysqldump -u"$DB_USER" "${DUMP_COMMON_ARGS[@]}" "$SELECTED_DB" \
      > "$output_file"
  fi
fi

if [[ ! -s "$output_file" ]]; then
  echo "Erro: backup gerado vazio: $output_file" >&2
  exit 1
fi

echo "Backup concluido com sucesso."
echo "Arquivo: $output_file"
du -h "$output_file" | awk '{print "Tamanho: "$1}'