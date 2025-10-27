#!/bin/bash
# create-gitlab-user-api.sh

GITLAB_URL="https://gitlab.zenfocus.com"
USERNAME="${1:-devuser}"  # Valor padrão se não fornecido
EMAIL="${2:-devuser@zenfocus.com}"
PASSWORD="${3:-DevPass123!}"

echo "📝 Criando usuário: $USERNAME ($EMAIL)"

# Obter token root
get_root_token() {
    docker exec zenfocus-gitlab gitlab-rails runner \
      "token = PersonalAccessToken.where(name: 'root-token').first&.token || PersonalAccessToken.create!(name: 'root-token', user: User.find(1), scopes: [:api], expires_at: 1.year.from_now).token; puts token" 2>/dev/null
}

# Criar usuário via API
create_user_api() {
    local token=$1
    response=$(curl -s -w "%{http_code}" -X POST "$GITLAB_URL/api/v4/users" \
      -H "PRIVATE-TOKEN: $token" \
      -H "Content-Type: application/json" \
      -d "{
        \"name\": \"$USERNAME\",
        \"username\": \"$USERNAME\",
        \"email\": \"$EMAIL\",
        \"password\": \"$PASSWORD\",
        \"skip_confirmation\": true
      }")
    
    echo "Response: $response"
}

# Main execution
ROOT_TOKEN=$(get_root_token)
echo "🔑 Token obtido: ${ROOT_TOKEN:0:10}..."

create_user_api "$ROOT_TOKEN"
echo "✅ Concluído!"

# Verificar se foi criado
echo "🔍 Verificando usuários existentes..."
docker exec zenfocus-gitlab gitlab-rails runner "puts 'Usuários no GitLab:'; User.all.each { |u| puts \"  - #{u.username} (#{u.email})\" }"