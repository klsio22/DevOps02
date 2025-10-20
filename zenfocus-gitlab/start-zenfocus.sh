#!/bin/bash
set -e

echo "🚀 Iniciando Zenfocus GitLab..."

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando. Inicie o Docker primeiro."
    exit 1
fi

# Criar diretório padrão para volumes se não existir
mkdir -p gitlab/config gitlab/logs gitlab/data gitlab/ssl dns/data

# Criar rede se não existir
if ! docker network ls --format '{{.Name}}' | grep -q '^zenfocus-net$'; then
    docker network create --subnet 10.10.10.0/24 zenfocus-net >/dev/null
fi

# Subir serviços
docker-compose up -d

echo "⏳ Aguardando GitLab inicializar (pode levar alguns minutos)..."
sleep 60

echo "✅ Zenfocus GitLab está rodando em:"
echo "   🌐 HTTP: http://gitlab.zenfocus.local"
echo "   🔗 SSH: git@gitlab.zenfocus.local:2222"

echo "📝 Para ver logs: docker logs -f zenfocus-gitlab"
