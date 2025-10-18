#!/bin/bash

# ========================================
# Script de Setup Automático - Zenfocus
# ========================================

set -e

echo "🚀 Iniciando setup do projeto Zenfocus..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se Docker está instalado
print_info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker não está instalado!"
    echo "Instale o Docker: https://docs.docker.com/engine/install/"
    exit 1
fi
print_info "✅ Docker instalado: $(docker --version)"

# Verificar se Docker Compose está instalado
print_info "Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose não está instalado!"
    echo "Instale o Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi
print_info "✅ Docker Compose instalado: $(docker-compose --version)"

# Verificar se o Docker daemon está rodando
print_info "Verificando Docker daemon..."
if ! docker info &> /dev/null; then
    print_error "Docker daemon não está rodando!"
    echo "Inicie o Docker: sudo systemctl start docker"
    exit 1
fi
print_info "✅ Docker daemon rodando"

echo ""
print_info "========================================="
print_info "  Iniciando containers..."
print_info "========================================="
echo ""

# Limpar containers antigos (opcional)
read -p "Deseja limpar containers antigos do Zenfocus? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Limpando containers antigos..."
    docker-compose down -v 2>/dev/null || true
fi

# Iniciar containers
print_info "Iniciando todos os serviços..."
docker-compose up -d

echo ""
print_info "⏳ Aguardando containers iniciarem..."
sleep 10

# Verificar status dos containers
print_info "Verificando status dos containers..."
docker-compose ps

echo ""
print_info "========================================="
print_info "  Configurando DNS Local..."
print_info "========================================="
echo ""

read -p "Deseja configurar o DNS no /etc/hosts? (requer sudo) (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Adicionando entradas ao /etc/hosts..."
    
    # Backup do hosts
    sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d%H%M%S)
    
    # Remover entradas antigas do Zenfocus
    sudo sed -i '/zenfocus.com.br/d' /etc/hosts
    
    # Adicionar novas entradas
    sudo bash -c 'cat >> /etc/hosts <<EOF

# Zenfocus DNS Entries
10.164.59.94 www.zenfocus.com.br zenfocus.com.br
10.164.59.92 gitlab.zenfocus.com.br
10.164.59.91 dns.zenfocus.com.br
EOF'
    
    print_info "✅ DNS configurado no /etc/hosts"
else
    print_warning "Para configurar manualmente, execute:"
    echo "  sudo bash -c 'cat >> /etc/hosts <<EOF"
    echo "  10.164.59.94 www.zenfocus.com.br zenfocus.com.br"
    echo "  10.164.59.92 gitlab.zenfocus.com.br"
    echo "  10.164.59.91 dns.zenfocus.com.br"
    echo "  EOF'"
fi

echo ""
print_info "========================================="
print_info "  Aguardando GitLab inicializar..."
print_info "========================================="
echo ""

print_warning "⏳ O GitLab pode levar 5-10 minutos para iniciar..."
print_info "Aguardando GitLab ficar saudável..."

# Aguardar GitLab
COUNTER=0
MAX_ATTEMPTS=60
until docker-compose ps gitlab | grep "healthy" &> /dev/null || [ $COUNTER -eq $MAX_ATTEMPTS ]; do
    printf "."
    sleep 10
    COUNTER=$((COUNTER+1))
done

echo ""
if [ $COUNTER -eq $MAX_ATTEMPTS ]; then
    print_warning "GitLab ainda está inicializando. Continue verificando com: docker-compose logs -f gitlab"
else
    print_info "✅ GitLab está saudável!"
fi

echo ""
print_info "========================================="
print_info "  Obtendo credenciais..."
print_info "========================================="
echo ""

# Tentar obter senha root do GitLab
print_info "Senha root do GitLab:"
docker exec zenfocus-gitlab grep 'Password:' /etc/gitlab/initial_root_password 2>/dev/null || \
    print_warning "Aguarde mais alguns minutos e execute: docker exec zenfocus-gitlab grep 'Password:' /etc/gitlab/initial_root_password"

echo ""
print_info "========================================="
print_info "  🎉 Setup Concluído!"
print_info "========================================="
echo ""

print_info "📋 Informações de Acesso:"
echo ""
echo "  🌐 Aplicação Web:"
echo "     URL: http://www.zenfocus.com.br"
echo "     Alternativa: http://localhost"
echo ""
echo "  🦊 GitLab:"
echo "     URL: http://gitlab.zenfocus.com.br:8080"
echo "     Usuário: root"
echo "     Senha: [veja acima]"
echo ""
echo "  🗄️  Banco de Dados:"
echo "     Host: zenfocus-db (10.164.59.95)"
echo "     Database: zenfocus_db"
echo "     Usuário: zenfocus"
echo "     Senha: zenfocus123"
echo ""

print_info "📚 Próximos Passos:"
echo ""
echo "  1. Acesse o GitLab e altere a senha root"
echo "  2. Crie um novo projeto chamado 'Zenfocus'"
echo "  3. Registre o GitLab Runner:"
echo "     docker exec -it zenfocus-runner gitlab-runner register"
echo "  4. Faça push do código para o GitLab"
echo "  5. Configure o pipeline CI/CD"
echo ""

print_info "🔧 Comandos Úteis:"
echo ""
echo "  Ver logs: docker-compose logs -f [serviço]"
echo "  Parar tudo: docker-compose down"
echo "  Reiniciar serviço: docker-compose restart [serviço]"
echo "  Status: docker-compose ps"
echo ""

print_info "📖 Documentação completa: README.md"
echo ""
print_info "✨ Projeto Zenfocus configurado com sucesso!"
