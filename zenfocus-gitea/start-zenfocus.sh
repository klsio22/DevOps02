#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Zenfocus Gitea - Inicializacao do Ambiente ==="
echo ""

# Carregar variaveis de ambiente
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "Variaveis de ambiente carregadas de .env"
else
    echo "Aviso: arquivo .env nao encontrado. Usando valores padrao."
    export GITEA_DOMAIN=${GITEA_DOMAIN:-gitea.zenfocus.com}
    export GITEA_SSH_PORT=${GITEA_SSH_PORT:-2222}
    export DNS_PORT=${DNS_PORT:-1053}
fi

# Verificar rede Docker
echo ""
echo "1) Verificando rede Docker..."
echo "   Rede sera criada automaticamente pelo docker compose."

# Gerar certificados
echo ""
echo "2) Gerando certificados SSL..."
docker compose up --build ca
if [ $? -ne 0 ]; then
    echo "Erro ao gerar certificados. Verifique o container ca."
    exit 1
fi
echo "   Certificados gerados em ./gitea/ssl/"

# Inicializar servicos
echo ""
echo "3) Iniciando servicos..."
docker compose up -d dns db gitea proxy app

if [ $? -ne 0 ]; then
    echo "Erro ao iniciar servicos."
    exit 1
fi

echo ""
echo "=== Servicos iniciados com sucesso ==="
echo ""
echo "Acesso:"
echo "  - Gitea (Web): https://${GITEA_DOMAIN:-gitea.zenfocus.com}"
echo "  - Gitea (SSH): ssh://git@${GITEA_DOMAIN:-gitea.zenfocus.com}:${GITEA_SSH_PORT:-2222}"
echo "  - Aplicacao:   http://www.zenfocus.com:${APP_PORT:-8080}"
echo ""
echo "Logs:"
echo "  docker compose logs -f"
echo ""
echo "Para ver as credenciais do Gitea:"
echo "  ./scripts/show-gitea-credentials.sh"
echo ""
echo "Nota: O Gitea pode levar alguns minutos para inicializar completamente."
