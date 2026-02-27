#!/bin/bash
# Script para redefinir senha de usuários do GitLab como Admin
# Uso: ./trocar-senha-usuario.sh <username> <nova_senha>

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir erro
erro() {
    echo -e "${RED}❌ ERRO: $1${NC}" >&2
}

# Função para exibir sucesso
sucesso() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Função para exibir info
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Função para exibir aviso
aviso() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Função para separador
separador() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Verificar argumentos
if [ $# -lt 2 ]; then
    echo ""
    echo -e "${BLUE}🔐 Script para Trocar Senha de Usuários GitLab${NC}"
    echo ""
    echo "Uso: $0 <username> <nova_senha>"
    echo ""
    echo "Exemplos:"
    echo "  $0 dev01 'NovaSenh@2024!'"
    echo "  $0 root 'AdminRoot@2024!'"
    echo ""
    echo "Senhas Recomendadas (Testadas):"
    echo "  DevUser2024!Pass@"
    echo "  AdminRoot2024!Pass@"
    echo "  SecurePass@2024!"
    echo ""
    exit 1
fi

USERNAME="$1"
NEW_PASSWORD="$2"

echo ""
separador
echo "🔄 Iniciando mudança de senha..."
separador
echo ""

# Verificar se o container está rodando
if ! docker ps | grep -q zenfocus-gitlab; then
    erro "Container zenfocus-gitlab não está rodando!"
    echo "Execute: docker compose up -d"
    exit 1
fi

info "Usuário: $USERNAME"
info "Nova Senha: ••••••••••••••• (oculta)"
echo ""

# Criar script Ruby para trocar a senha
cat > /tmp/change_password.rb << 'EOF'
username = ARGV[0]
new_password = ARGV[1]

# Encontrar usuário
user = User.find_by_username(username)

if user.nil?
  puts "❌ Usuário '#{username}' não encontrado!"
  puts ""
  puts "Usuários existentes:"
  User.all.each { |u| puts "  - #{u.username} (#{u.email})" }
  exit 1
end

# Exibir informações antes da mudança
puts "📋 Informações do Usuário:"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "  Username:   #{user.username}"
puts "  Email:      #{user.email}"
puts "  Nome:       #{user.name}"
puts "  Admin:      #{user.admin ? '✅ Sim' : '❌ Não'}"
puts "  Confirmado: #{user.confirmed? ? '✅ Sim' : '❌ Não'}"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts ""

# Trocar a senha
puts "🔄 Alterando senha..."
user.password = new_password
user.password_confirmation = new_password

# Salvar sem validações (para evitar erro 422)
if user.save(validate: false)
  puts ""
  puts "✅ Senha alterada com sucesso!"
  puts ""
  puts "📝 Credenciais para login:"
  puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  puts "  URL:      https://gitlab.zenfocus.com"
  puts "  Email:    #{user.email}"
  puts "  Senha:    #{new_password}"
  puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  puts ""
  puts "Próximos passos:"
  puts "  1. Faça logout se estiver logado"
  puts "  2. Acesse: https://gitlab.zenfocus.com"
  puts "  3. Faça login com o email e a nova senha"
else
  puts ""
  puts "❌ Erro ao alterar senha:"
  user.errors.full_messages.each { |msg| puts "  - #{msg}" }
  exit 1
end
EOF

# Executar o script no container
info "Conectando ao container GitLab..."
docker cp /tmp/change_password.rb zenfocus-gitlab:/tmp/ > /dev/null 2>&1

info "Executando alteração de senha..."
docker exec zenfocus-gitlab gitlab-rails runner /tmp/change_password.rb "$USERNAME" "$NEW_PASSWORD"

# Limpar arquivo temporário
rm -f /tmp/change_password.rb

echo ""
separador
sucesso "Operação concluída!"
separador
echo ""
