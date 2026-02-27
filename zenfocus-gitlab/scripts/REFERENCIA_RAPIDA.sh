#!/bin/bash
# REFERÊNCIA RÁPIDA - Scripts de Gerenciamento de Usuários GitLab
# Cole estes comandos no terminal para usar os scripts

# ============================================================================
# 1. TROCAR SENHA DE UM USUÁRIO
# ============================================================================

# Mudar senha de dev02
./scripts/trocar-senha-usuario.sh dev02 'NovaSenha@2024!'

# Mudar senha de dev01
./scripts/trocar-senha-usuario.sh dev01 'OutraSenha@2024!'

# ============================================================================
# 2. LISTAR TODOS OS USUÁRIOS
# ============================================================================

./scripts/listar-usuarios-detalhado.sh

# ============================================================================
# 3. GERENCIADOR INTERATIVO (RECOMENDADO!)
# ============================================================================

./scripts/gerenciador-usuarios-interativo.sh

# Opções do menu:
# 1) Listar usuários
# 2) Criar novo usuário
# 3) Trocar senha
# 4) Tornar admin
# 5) Remover admin
# 6) Ver detalhes
# 7) Testar login
# 8) Sair

# ============================================================================
# 4. COMANDOS VIA TERMINAL (AVANÇADO)
# ============================================================================

# Ver informações de um usuário
docker exec zenfocus-gitlab gitlab-rails runner "
user = User.find_by_username('dev01')
puts \"Username: #{user.username}\"
puts \"Email: #{user.email}\"
puts \"Admin: #{user.admin}\"
"

# Listar todos os usuários rapidamente
docker exec zenfocus-gitlab gitlab-rails runner "
User.all.each { |u| puts \"#{u.username} (#{u.email}) - Admin: #{u.admin}\" }
"

# Tornar usuário admin
docker exec zenfocus-gitlab gitlab-rails runner "
user = User.find_by_username('dev03')
user.update_column(:admin, true)
puts 'Usuário agora é admin!'
"

# Remover privilegios de admin
docker exec zenfocus-gitlab gitlab-rails runner "
user = User.find_by_username('dev02')
user.update_column(:admin, false)
puts 'Privilégios removidos!'
"

# Contar usuários
docker exec zenfocus-gitlab gitlab-rails runner "
puts \"Total: #{User.count}\"
puts \"Admins: #{User.where(admin: true).count}\"
puts \"Normais: #{User.where(admin: false).count}\"
"

# ============================================================================
# 5. SENHAS RECOMENDADAS (JÁ TESTADAS)
# ============================================================================

# DevUser2024!Pass@      ✅
# AdminRoot2024!Pass@    ✅
# SecurePass@2024!       ✅
# GitLab@Secure123!      ✅
# NovaSenha@2024!        ✅

# ============================================================================
# 6. URLs IMPORTANTES
# ============================================================================

# Página inicial
# https://gitlab.zenfocus.com

# Login
# https://gitlab.zenfocus.com/users/sign_in

# Admin Area
# https://gitlab.zenfocus.com/admin

# Listar usuários (como admin)
# https://gitlab.zenfocus.com/admin/users

# Editar usuário (substituir {ID} pelo ID do usuário)
# https://gitlab.zenfocus.com/admin/users/{ID}/edit

# Exemplos:
# https://gitlab.zenfocus.com/admin/users/2/edit  (dev01)
# https://gitlab.zenfocus.com/admin/users/3/edit  (dev02)
# https://gitlab.zenfocus.com/admin/users/4/edit  (dev03)

# ============================================================================
# 7. USUÁRIOS DISPONÍVEIS
# ============================================================================

# root - Admin
# Email: gitlab_admin_* (varia)
# Senha: (verificar com trocar-senha-usuario.sh)

# dev01 - Admin
# Email: dev01@zenfocus.com
# Senha: DevUser2024!Pass@
# ID: 2

# dev02 - Usuário Normal
# Email: dev02@zenfocus.com
# Senha: NovaSenha@2024! (alterada)
# ID: 3

# dev03 - Usuário Normal
# Email: dev03@zenfocus.com
# Senha: GitLab@Secure123!
# ID: 4

# ============================================================================
# 8. DICAS PRÁTICAS
# ============================================================================

# ✅ Sempre use o gerenciador interativo para operações frequentes
# ✅ Cole credenciais em local seguro (gerenciador de senhas)
# ✅ Use senhas fortes com MAIÚSCULA + minúscula + número + símbolo
# ✅ Teste o login após criar ou modificar usuário
# ✅ Revise permissões regularmente
# ✅ Não compartilhe credenciais de admin
# ✅ Consulte scripts/README.md para mais detalhes

# ============================================================================
# 9. EXEMPLO DE FLUXO COMPLETO
# ============================================================================

# 1. Criar novo usuário
# ./scripts/criar-usuario-gitlab.sh dev04 'dev04@zenfocus.com' 'Developer 04' 'DevPass@2024!'

# 2. Listar para verificar
# ./scripts/listar-usuarios-detalhado.sh

# 3. Abrir gerenciador para operações
# ./scripts/gerenciador-usuarios-interativo.sh
# Escolher opção 3 para trocar senha se necessário
# Escolher opção 4 para tornar admin

# 4. Testar login
# Acesse https://gitlab.zenfocus.com
# Use: dev04@zenfocus.com + senha

# ============================================================================
# FIM DA REFERÊNCIA RÁPIDA
# ============================================================================
