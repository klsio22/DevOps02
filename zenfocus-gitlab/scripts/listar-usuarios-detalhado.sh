#!/bin/bash
# Script para listar todos os usuários do GitLab com detalhes completos

set -e

# Cores para output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para separador
separador() {
    echo "═════════════════════════════════════════════════════════════════════════════════"
}

echo ""
separador
echo -e "${BLUE}📋 Listagem Completa de Usuários - GitLab Zenfocus${NC}"
separador
echo ""

# Verificar se o container está rodando
if ! docker ps | grep -q zenfocus-gitlab; then
    echo -e "${RED}❌ Container zenfocus-gitlab não está rodando!${NC}"
    echo "Execute: docker compose up -d"
    exit 1
fi

# Criar script Ruby para listar usuários
cat > /tmp/list_users.rb << 'EOF'
puts "📊 RESUMO GERAL"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "Total de usuários: #{User.count}"
puts "Administradores: #{User.where(admin: true).count}"
puts "Usuários normais: #{User.where(admin: false).count}"
puts ""

puts "👥 LISTAGEM DETALHADA"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts ""

User.all.order(:id).each do |user|
  admin_badge = user.admin ? "🔑 ADMIN" : "👤 USER"
  confirmed_badge = user.confirmed? ? "✅" : "⏳"
  
  puts "┌─ ID: #{user.id}"
  puts "│  Username: #{user.username}"
  puts "│  Email: #{user.email}"
  puts "│  Nome: #{user.name}"
  puts "│  Status: #{admin_badge}"
  puts "│  Confirmado: #{confirmed_badge}"
  puts "│  Admin: #{user.admin ? 'Sim' : 'Não'}"
  puts "│  Link de edição: https://gitlab.zenfocus.com/admin/users/#{user.id}/edit"
  puts "└─"
  puts ""
end

puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts ""

puts "🔑 ADMINISTRADORES"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
admin_count = 0
User.where(admin: true).each do |user|
  admin_count += 1
  puts "#{admin_count}. #{user.username} (#{user.email}) - ID: #{user.id}"
end
puts ""

puts "👤 USUÁRIOS NORMAIS"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
normal_count = 0
User.where(admin: false).each do |user|
  normal_count += 1
  puts "#{normal_count}. #{user.username} (#{user.email}) - ID: #{user.id}"
end
puts ""

puts "✨ Dica: Use 'trocar-senha-usuario.sh <username> <senha>' para alterar senhas"
EOF

# Executar o script
docker cp /tmp/list_users.rb zenfocus-gitlab:/tmp/ > /dev/null 2>&1
docker exec zenfocus-gitlab gitlab-rails runner /tmp/list_users.rb

# Limpar
rm -f /tmp/list_users.rb

echo ""
separador
echo ""
