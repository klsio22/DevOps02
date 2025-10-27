#!/usr/bin/env sh
set -eu

# scripts/bootstrap-create-user.sh
# Waits for GitLab to become ready and creates a user via the REST API using
# an admin personal access token. Token is read from /config/admin_token (file)
# or from the env var ADMIN_TOKEN.

CONFIG_DIR=/config
TOKEN_FILE="$CONFIG_DIR/admin_token"

BOOT_USER=${BOOT_USER:-dev1}
BOOT_EMAIL=${BOOT_EMAIL:-dev1@gitlab.zenfocus.com}
BOOT_NAME=${BOOT_NAME:-Dev One}
BOOT_PASS=${BOOT_PASS:-}
GITLAB_HOST=${GITLAB_HOST:-https://gitlab.zenfocus.com}

if [ -z "$BOOT_PASS" ]; then
  # generate a short password if openssl available, else fallback
  if command -v openssl >/dev/null 2>&1; then
    BOOT_PASS=$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-16)
  else
    BOOT_PASS="Dev1Passw0rd!"
  fi
fi

echo "[bootstrap] usando usuário=$BOOT_USER email=$BOOT_EMAIL"

# read token
if [ -n "${ADMIN_TOKEN:-}" ]; then
  TOKEN="$ADMIN_TOKEN"
elif [ -f "$TOKEN_FILE" ]; then
  TOKEN=$(cat "$TOKEN_FILE" | tr -d '\n')
else
  echo "[bootstrap] nenhum token admin fornecido: crie ./gitlab/config/admin_token ou exporte ADMIN_TOKEN" >&2
  exit 0
fi

echo "[bootstrap] aguardando GitLab ficar pronto em $GITLAB_HOST ..."
RETRIES=0
MAX_RETRIES=60
SLEEP=5
while [ $RETRIES -lt $MAX_RETRIES ]; do
  HTTP=$(curl -k -s -o /dev/null -w "%{http_code}" -H "PRIVATE-TOKEN: $TOKEN" "$GITLAB_HOST/api/v4/version" || true)
  if [ "$HTTP" = "200" ]; then
    echo "[bootstrap] GitLab pronto (HTTP 200)"
    break
  fi
  RETRIES=$((RETRIES+1))
  echo "[bootstrap] aguardando... ($RETRIES/$MAX_RETRIES)"
  sleep $SLEEP
done

if [ $RETRIES -ge $MAX_RETRIES ]; then
  echo "[bootstrap] timeout aguardando GitLab" >&2
  exit 1
fi

# check if user exists
EXIST=$(curl -k -s -H "PRIVATE-TOKEN: $TOKEN" "$GITLAB_HOST/api/v4/users?username=$BOOT_USER")
if echo "$EXIST" | grep -q "\[\]"; then
  echo "[bootstrap] usuário $BOOT_USER não existe, criando..."
  CREATE=$(curl -k -s -o /dev/stderr -w "%{http_code}" -X POST -H "PRIVATE-TOKEN: $TOKEN" "$GITLAB_HOST/api/v4/users" \
    -d "email=$BOOT_EMAIL" -d "username=$BOOT_USER" -d "name=$BOOT_NAME" -d "password=$BOOT_PASS" -d "skip_confirmation=true")
  if [ "$CREATE" = "201" ]; then
    echo "[bootstrap] usuário $BOOT_USER criado com sucesso"
    echo "[bootstrap] credenciais: $BOOT_USER / $BOOT_PASS"
    exit 0
  else
    echo "[bootstrap] falha ao criar usuário, HTTP status: $CREATE" >&2
    exit 1
  fi
else
  echo "[bootstrap] usuário $BOOT_USER já existe, nada a fazer"
  exit 0
fi
