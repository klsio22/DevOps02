#!/bin/bash
# Script para criar ou redefinir senha de usuário no GitLab
# Uso: ./criar-usuario-gitlab.sh <username> <email> <nome_completo> <senha>

set -e

if [ $# -lt 4 ]; then
    echo "❌ Uso: $0 <username> <email> <nome_completo> <senha>"
    echo ""
    echo "Exemplo:"
    echo "$0 dev2 dev2@gitlab.zenfocus.com 'Developer 2' 'MinhaSenh@123!'"
    exit 1
fi

USERNAME="$1"
EMAIL="$2"
NAME="$3"
PASSWORD="$4"

echo "🔄 Verificando se usuário $USERNAME já existe..."

# Criar script Ruby temporário
cat > /tmp/manage_user.rb << EOF
username = '$USERNAME'
email = '$EMAIL'
name = '$NAME'
password = '$PASSWORD'

user = User.find_by_username(username)

if user
  puts "⚠️  Usuário #{username} já existe. Redefinindo senha..."
  user.password = password
  user.password_confirmation = password
  user.save(validate: false)
  puts "✅ Senha redefinida com sucesso!"
else
  puts "🆕 Criando novo usuário #{username}..."
  user = User.new(
    username: username,
    email: email,
    name: name,
    password: password,
    password_confirmation: password
  )
  user.skip_confirmation!
  user.save(validate: false)
  puts "✅ Usuário criado com sucesso!"
end

puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "Username: #{user.username}"
puts "Email: #{user.email}"
puts "Nome: #{user.name}"
puts "Senha: $password"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts ""
puts "🌐 Para fazer login:"
puts "   URL: https://gitlab.zenfocus.com"
puts "   Email: #{user.email}"
puts "   Senha: $password"
EOF

# Executar no container
docker cp /tmp/manage_user.rb zenfocus-gitlab:/tmp/
docker exec zenfocus-gitlab gitlab-rails runner /tmp/manage_user.rb

# Limpar
rm -f /tmp/manage_user.rb

echo ""
echo "✅ Operação concluída!"
