#!/bin/bash
# Script para listar todos os usuários do GitLab

echo "📋 Listando usuários do GitLab..."
echo ""

docker exec zenfocus-gitlab gitlab-rails runner "
puts '═══════════════════════════════════════════════════════════════'
puts '  ID │ Username        │ Email                       │ Admin'
puts '═══════════════════════════════════════════════════════════════'

User.all.each do |user|
  admin_badge = user.admin ? '✓' : ' '
  printf '%4d │ %-15s │ %-27s │ %s', user.id, user.username, user.email, admin_badge
  puts
end

puts '═══════════════════════════════════════════════════════════════'
puts \"Total de usuários: #{User.count}\"
"
