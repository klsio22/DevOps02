#!/bin/bash
set -e

echo "Iniciando ambiente do Passo I (CRUD + MariaDB)..."

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "Docker nao esta rodando. Inicie o Docker primeiro."
    exit 1
fi

# Diretorios necessarios para a fase inicial
mkdir -p app/data dns/data

# Criar rede se não existir
if ! docker network ls --format '{{.Name}}' | grep -q '^zenfocus-net$'; then
    docker network create --subnet 10.10.10.0/24 zenfocus-net >/dev/null
fi

# Subir apenas os servicos da primeira parte
docker compose up -d db app

echo "Aguardando banco de dados inicializar..."
sleep 8

echo "Ambiente inicial pronto."
echo "Acesse a aplicacao em:"
echo "  http://localhost:8080"
echo "  http://www.zenfocus.com:8080  (apos ajustar /etc/hosts)"

echo
echo "Se precisar usar dominio no navegador, adicione no host:"
echo "  sudo sh -c \"echo '127.0.0.1 www.zenfocus.com' >> /etc/hosts\""

echo "Comandos uteis:"
echo "  docker compose ps"
echo "  docker compose logs -f app db"
echo "  docker compose down"
