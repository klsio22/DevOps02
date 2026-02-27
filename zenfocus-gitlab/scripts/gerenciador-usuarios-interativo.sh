#!/bin/bash
# Script interativo para gerenciar usuários GitLab

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configurações
CONTAINER_NAME="zenfocus-gitlab"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Funções de display
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║        🔐 Gerenciador de Usuários - GitLab Zenfocus       ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

show_menu() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} 📋 Listar todos os usuários"
    echo -e "${GREEN}2)${NC} ➕ Criar novo usuário"
    echo -e "${GREEN}3)${NC} 🔑 Trocar senha de um usuário"
    echo -e "${GREEN}4)${NC} 👑 Tornar usuário administrador"
    echo -e "${GREEN}5)${NC} 👤 Remover privilégios de administrador"
    echo -e "${GREEN}6)${NC} 🔍 Ver detalhes de um usuário"
    echo -e "${GREEN}7)${NC} 🧪 Testar login de um usuário"
    echo -e "${GREEN}8)${NC} ❌ Sair"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -n "Digite o número da opção: "
}

# Função para listar usuários
listar_usuarios() {
    clear
    show_header
    echo -e "${YELLOW}Carregando usuários...${NC}"
    echo ""
    
    docker exec "$CONTAINER_NAME" gitlab-rails runner << 'RUBY'
puts "📊 Usuários Registrados"
puts "="*70
printf "%-4s | %-15s | %-30s | %-7s\n", "ID", "Username", "Email", "Admin"
puts "-"*70

User.all.order(:id).each do |user|
  admin = user.admin ? "✅ Sim" : "❌ Não"
  printf "%-4d | %-15s | %-30s | %-7s\n", user.id, user.username, user.email, admin
end

puts "="*70
RUBY
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Função para criar novo usuário
criar_usuario() {
    clear
    show_header
    
    read -p "Username: " username
    read -p "Email: " email
    read -p "Nome completo: " name
    read -s -p "Senha: " password
    echo ""
    read -s -p "Confirme a senha: " password_confirm
    echo ""
    
    if [ "$password" != "$password_confirm" ]; then
        echo -e "${RED}❌ Senhas não coincidem!${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Criando usuário...${NC}"
    
    docker cp /tmp/temp_create.rb "$CONTAINER_NAME":/tmp/ 2>/dev/null || true
    
    docker exec "$CONTAINER_NAME" gitlab-rails runner << RUBY
user = User.find_by_username('$username')

if user
  puts "⚠️  Usuário '$username' já existe!"
else
  user = User.new(
    username: '$username',
    email: '$email',
    name: '$name',
    password: '$password',
    password_confirmation: '$password'
  )
  user.skip_confirmation!
  
  if user.save(validate: false)
    puts "✅ Usuário criado com sucesso!"
    puts ""
    puts "Informações do novo usuário:"
    puts "  Username: #{user.username}"
    puts "  Email: #{user.email}"
    puts "  Nome: #{user.name}"
    puts "  ID: #{user.id}"
  else
    puts "❌ Erro ao criar: #{user.errors.full_messages.join(', ')}"
  end
end
RUBY
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Função para trocar senha
trocar_senha() {
    clear
    show_header
    
    read -p "Username: " username
    read -s -p "Nova Senha: " password
    echo ""
    
    echo ""
    echo -e "${YELLOW}Alterando senha...${NC}"
    
    docker exec "$CONTAINER_NAME" gitlab-rails runner << RUBY
user = User.find_by_username('$username')

if user.nil?
  puts "❌ Usuário '$username' não encontrado!"
else
  user.password = '$password'
  user.password_confirmation = '$password'
  
  if user.save(validate: false)
    puts "✅ Senha alterada com sucesso!"
    puts ""
    puts "Informações para login:"
    puts "  URL: https://gitlab.zenfocus.com"
    puts "  Email: #{user.email}"
    puts "  Senha: $password"
  else
    puts "❌ Erro: #{user.errors.full_messages.join(', ')}"
  end
end
RUBY
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Função para tornar admin
tornar_admin() {
    clear
    show_header
    
    read -p "Username: " username
    
    echo ""
    echo -e "${YELLOW}Concedendo privilégios de admin...${NC}"
    
    docker exec "$CONTAINER_NAME" gitlab-rails runner << RUBY
user = User.find_by_username('$username')

if user.nil?
  puts "❌ Usuário '$username' não encontrado!"
elsif user.admin
  puts "⚠️  Usuário '$username' já é administrador!"
else
  user.update_column(:admin, true)
  puts "✅ Usuário '$username' agora é administrador!"
end
RUBY
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Função para remover admin
remover_admin() {
    clear
    show_header
    
    read -p "Username: " username
    
    if [ "$username" = "root" ]; then
        echo -e "${RED}❌ Não é permitido remover admin do usuário root!${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Removendo privilégios de admin...${NC}"
    
    docker exec "$CONTAINER_NAME" gitlab-rails runner << RUBY
user = User.find_by_username('$username')

if user.nil?
  puts "❌ Usuário '$username' não encontrado!"
elsif !user.admin
  puts "⚠️  Usuário '$username' não é administrador!"
else
  user.update_column(:admin, false)
  puts "✅ Privilégios de admin removidos de '$username'!"
end
RUBY
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Função para ver detalhes
ver_detalhes() {
    clear
    show_header
    
    read -p "Username: " username
    
    echo ""
    echo -e "${YELLOW}Carregando informações...${NC}"
    echo ""
    
    docker exec "$CONTAINER_NAME" gitlab-rails runner << RUBY
user = User.find_by_username('$username')

if user.nil?
  puts "❌ Usuário '$username' não encontrado!"
else
  puts "📋 Informações do Usuário"
  puts "="*50
  puts "ID: #{user.id}"
  puts "Username: #{user.username}"
  puts "Email: #{user.email}"
  puts "Nome: #{user.name}"
  puts "Admin: #{user.admin ? '✅ Sim' : '❌ Não'}"
  puts "Confirmado: #{user.confirmed? ? '✅ Sim' : '❌ Não'}"
  puts "Bloqueado: #{user.blocked? ? '✅ Sim' : '❌ Não'}"
  puts "Criado em: #{user.created_at}"
  puts "Último login: #{user.last_sign_in_at || 'Nunca'}"
  puts "="*50
  puts ""
  puts "Link de edição (Admin):"
  puts "https://gitlab.zenfocus.com/admin/users/#{user.id}/edit"
end
RUBY
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Função para testar login
testar_login() {
    clear
    show_header
    
    read -p "Email: " email
    read -s -p "Senha: " password
    echo ""
    
    echo ""
    echo -e "${YELLOW}Testando credenciais...${NC}"
    
    docker exec "$CONTAINER_NAME" gitlab-rails runner << RUBY
user = User.find_by_email('$email')

if user.nil?
  puts "❌ Usuário com email '$email' não encontrado!"
else
  if user.valid_password?('$password')
    puts "✅ Credenciais válidas!"
    puts ""
    puts "Informações do usuário:"
    puts "  Username: #{user.username}"
    puts "  Email: #{user.email}"
    puts "  Admin: #{user.admin ? 'Sim' : 'Não'}"
    puts ""
    puts "Você pode fazer login em: https://gitlab.zenfocus.com"
  else
    puts "❌ Senha incorreta!"
  end
end
RUBY
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Loop principal
while true; do
    show_header
    show_menu
    read -r option
    
    case $option in
        1) listar_usuarios ;;
        2) criar_usuario ;;
        3) trocar_senha ;;
        4) tornar_admin ;;
        5) remover_admin ;;
        6) ver_detalhes ;;
        7) testar_login ;;
        8) 
            echo ""
            echo -e "${GREEN}Até logo!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            sleep 1
            ;;
    esac
done
