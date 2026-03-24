#!/bin/bash
set -e
set +H

# Load variables from .env
if [ -f .env ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi
    key="${line%%=*}"
    value="${line#*=}"
    key="${key%$'\r'}"
    value="${value%$'\r'}"
    export "$key=$value"
  done < .env
else
  echo "Arquivo .env nao encontrado."
  exit 1
fi

echo "Iniciando ambiente do Passo I (CRUD + MariaDB)..."

if ! docker info > /dev/null 2>&1; then
  echo "Docker nao esta rodando. Inicie o Docker primeiro."
  exit 1
fi

mkdir -p app/data dns/data

if ! docker network ls --format '{{.Name}}' | grep -q '^zenfocus-net$'; then
  docker network create --subnet 10.10.10.0/24 zenfocus-net >/dev/null
fi

docker compose up -d db app

echo "Aguardando banco de dados inicializar..."
sleep 8

echo "Ambiente inicial pronto."
echo "Acesse a aplicacao em:"
echo "  http://localhost:${APP_PORT}"
echo "  http://${APP_DOMAIN}:${APP_PORT}  (apos ajustar /etc/hosts)"
echo
echo "Se precisar usar dominio no navegador, adicione no host:"
echo "  sudo sh -c \"echo '127.0.0.1 ${APP_DOMAIN}' >> /etc/hosts\""
echo "Comandos uteis:"
echo "  docker compose ps"
echo "  docker compose logs -f app db"
echo "  docker compose down"

if [ "${START_GITLAB:-false}" = "true" ]; then
  echo
  echo "Iniciando GitLab (Passo II / Parte GitLab)..."

  mkdir -p gitlab/config gitlab/logs gitlab/data gitlab/ssl

  if [ ! -f "gitlab/ssl/${GITLAB_DOMAIN}.crt" ] || [ ! -f "gitlab/ssl/${GITLAB_DOMAIN}.key" ]; then
    echo "Certificados ausentes em ./gitlab/ssl; gerando com o servico ca..."
    docker compose run --rm ca >/dev/null 2>&1 || docker compose run --rm ca
  fi

  docker compose up -d dns gitlab proxy

  CONTAINER_NAME="${CONTAINER_NAME:-zenfocus-gitlab}"

  echo "Aguardando o GitLab inicializar (pode levar alguns minutos)..."
  MAX_RETRIES=60
  RETRY_INTERVAL=10
  COUNT=0

  until docker exec "$CONTAINER_NAME" gitlab-rails runner "User.count" >/dev/null 2>&1; do
    COUNT=$((COUNT + 1))
    if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
      echo "GitLab nao ficou pronto a tempo."
      echo "Dica: docker logs $CONTAINER_NAME --tail 200"
      exit 1
    fi
    echo "GitLab ainda iniciando... tentativa ${COUNT}/${MAX_RETRIES}"
    sleep "$RETRY_INTERVAL"
  done

  echo "GitLab Rails pronto."
  echo
  echo "GitLab pronto!"
  echo
  
  # Exibir credenciais usando script separado
  if [ -f ./scripts/show-gitlab-credentials.sh ]; then
    ./scripts/show-gitlab-credentials.sh "$CONTAINER_NAME" "$GITLAB_DOMAIN"
  else
    echo "Script show-gitlab-credentials.sh não encontrado em ./scripts/."
    echo "Para ver as credenciais, execute:"
    echo "  ./scripts/show-gitlab-credentials.sh $CONTAINER_NAME $GITLAB_DOMAIN"
  fi
fi
