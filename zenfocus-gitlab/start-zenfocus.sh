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
docker compose up -d

echo "⏳ Aguardando GitLab inicializar (pode levar alguns minutos)..."
sleep 60

echo "✅ Zenfocus GitLab está rodando em:"
echo "   🌐 HTTP: http://gitlab.zenfocus.com"
echo "   🔗 SSH: git@gitlab.zenfocus.com:2222"

echo "📝 Para ver logs: docker logs -f zenfocus-gitlab"

# criar usuário automático 'dev1' se o GitLab estiver pronto
echo "⏳ Verificando disponibilidade do GitLab para criação de usuário 'dev1'..."
TRIES=0
MAX_TRIES=30
while ! docker exec zenfocus-gitlab bash -lc "gitlab-rails runner 'puts :ok'" >/dev/null 2>&1; do
    TRIES=$((TRIES+1))
    if [ "$TRIES" -ge "$MAX_TRIES" ]; then
        echo "⚠️ GitLab não ficou pronto em tempo para criar o usuário automático. Você pode criar manualmente depois."
        break
    fi
    echo -n "."
    sleep 5
done

if [ "$TRIES" -lt "$MAX_TRIES" ]; then
    DEV_USER="dev1"
    DEV_EMAIL="dev1@gitlab.zenfocus.com"
    DEV_PASS="Dev1Passw0rd!"
    echo
    echo "🔐 Criando usuário '$DEV_USER' (email: $DEV_EMAIL) ..."
    docker exec zenfocus-gitlab bash -lc "gitlab-rails runner \"user = User.find_by_username('$DEV_USER'); if user.nil?; user = User.create!(name: 'Dev One', username: '$DEV_USER', email: '$DEV_EMAIL', password: '$DEV_PASS', password_confirmation: '$DEV_PASS', confirmed_at: Time.now); puts 'user_created'; else; puts 'user_exists'; end\"" || true
    echo "✅ Usuário automático processado (verifique no GitLab)."
    echo "   Credenciais de teste: $DEV_USER / $DEV_PASS"
fi
