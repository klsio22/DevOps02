#!/usr/bin/env bash
set -euo pipefail

# scripts/create-dev-user.sh
# Cria um usuário no GitLab usando Users::CreateService e trata ServiceResponse

USERNAME=${1:-dev1}
EMAIL=${2:-dev1@gitlab.zenfocus.com}
PASSWORD=${3:-}

if [ -z "$PASSWORD" ]; then
  if command -v openssl >/dev/null 2>&1; then
    PASSWORD=$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-16)
  else
    PASSWORD="Dev1Passw0rd!"
  fi
fi

echo "🔐 Tentando criar usuário '$USERNAME' (email: $EMAIL) com senha gerada..."

docker exec zenfocus-gitlab bash -lc "gitlab-rails runner \"begin; root = User.find_by_username('root'); if root.nil?; puts 'ERROR: root user not found'; exit 1; end; params = { name: '${USERNAME}', username: '${USERNAME}', email: '${EMAIL}', password: '${PASSWORD}', password_confirmation: '${PASSWORD}', skip_confirmation: true }; res = Users::CreateService.new(root, params).execute; user = res.respond_to?(:payload) ? res.payload[:user] : (res.is_a?(Hash) ? res[:payload][:user] : nil); if user && user.respond_to?(:persisted?) && user.persisted?; puts 'SUCCESS: Usuario ${USERNAME} criado'; else; msg = res.respond_to?(:message) ? res.message : (res.is_a?(Hash) ? res[:message] : nil); puts 'ERROR: ' + (msg || 'creation failed'); if user && user.respond_to?(:errors); puts user.errors.full_messages.join('; '); end; exit 1; end; rescue => e; puts 'EX: ' + e.message; e.backtrace.each{|l| puts l}; exit 1; end\""
