#!/bin/bash
# filepath: /home/klsio27/Documentos/www/DevOps02/zenfocus-gitlab/scripts/criar-usuario-gitlab-v2.sh

set -e

if [ $# -lt 4 ]; then
    echo "❌ Uso: $0 <username> <email> <nome_completo> <senha>"
    echo ""
    echo "Exemplo:"
    echo "$0 dev01 dev1@gitlab.zenfocus.com 'Developer 01' 'DevUser2024!Pass@'"
    exit 1
fi

USERNAME="$1"
EMAIL="$2"
NAME="$3"
PASSWORD="$4"

echo "🔄 Processando usuário $USERNAME..."

# Criar script Ruby temporário com escape correto
cat > /tmp/manage_user_v2.rb << 'EOF'
username = ARGV[0]
email = ARGV[1]
name = ARGV[2]
password = ARGV[3]

user = User.find_by_username(username)

if user
  puts "⚠️  Usuário #{username} já existe. Redefinindo senha..."
  user.password = password
  user.password_confirmation = password
  if user.save(validate: false)
    puts "✅ Senha redefinida com sucesso!"
  else
    puts "❌ Erro ao redefinir: #{user.errors.full_messages.join(', ')}"
  end
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
  if user.save(validate: false)
    puts "✅ Usuário criado com sucesso!"
  else
    puts "❌ Erro ao criar: #{user.errors.full_messages.join(', ')}"
  end
end

puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "Username: #{user.username}"
puts "Email: #{user.email}"
puts "Nome: #{user.name}"
puts "Senha: #{password}"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EOF

# Executar no container
docker cp /tmp/manage_user_v2.rb zenfocus-gitlab:/tmp/
docker exec zenfocus-gitlab gitlab-rails runner /tmp/manage_user_v2.rb "$USERNAME" "$EMAIL" "$NAME" "$PASSWORD"

# Limpar
rm -f /tmp/manage_user_v2.rb

echo ""
echo "✅ Operação concluída!"