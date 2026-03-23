#!/bin/bash

# Script para exibir credenciais padrão do GitLab
# Uso: ./show-gitlab-credentials.sh [container-name] [gitlab-domain]
# Exemplo: ./show-gitlab-credentials.sh zenfocus-gitlab gitlab.zenfocus.com

CONTAINER_NAME="${1:-zenfocus-gitlab}"
GITLAB_DOMAIN="${2:-gitlab.zenfocus.com}"

# Verificar se o container está rodando
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Erro: Container '$CONTAINER_NAME' não está em execução."
  exit 1
fi

# Obter a senha inicial do root
ROOT_PASSWORD=$(
  docker exec "$CONTAINER_NAME" sh -c "grep '^Password:' /etc/gitlab/initial_root_password 2>/dev/null | awk '{print \$2}'" \
  || true
)

if [ -z "$ROOT_PASSWORD" ]; then
  ROOT_PASSWORD="NAO_ENCONTRADA"
fi

# Exibir credenciais
echo
echo "========================================"
echo "GitLab - Credenciais de Admin"
echo "========================================"
echo "URL:      https://${GITLAB_DOMAIN}"
echo ""
echo "Admin (root)"
echo "  Username: root"
echo "  Senha:    ${ROOT_PASSWORD}"
echo ""
echo "========================================"
