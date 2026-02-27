# 🔐 Scripts de Gerenciamento de Usuários - GitLab Zenfocus

## 📚 Visão Geral

Este diretório contém scripts para gerenciar usuários do GitLab de forma fácil e segura.

## 🛠️ Scripts Disponíveis

### 1. **trocar-senha-usuario.sh** - Trocar Senha
Altera a senha de qualquer usuário do GitLab.

**Uso**:
```bash
./scripts/trocar-senha-usuario.sh <username> <nova_senha>
```

**Exemplo**:
```bash
./scripts/trocar-senha-usuario.sh dev01 'NovaSenh@2024!'
```

**O que faz**:
- ✅ Encontra o usuário
- ✅ Altera a senha
- ✅ Exibe as credenciais para login
- ✅ Fornece próximos passos

**Saída esperada**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Informações do Usuário:
  Username:   dev01
  Email:      dev01@zenfocus.com
  Nome:       Developer 01
  Admin:      ❌ Não
  Confirmado: ✅ Sim
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Senha alterada com sucesso!

📝 Credenciais para login:
  URL:      https://gitlab.zenfocus.com
  Email:    dev01@zenfocus.com
  Senha:    NovaSenh@2024!
```

---

### 2. **listar-usuarios-detalhado.sh** - Listar Usuários
Lista todos os usuários com informações detalhadas.

**Uso**:
```bash
./scripts/listar-usuarios-detalhado.sh
```

**O que mostra**:
- 📊 Resumo geral (total, admins, usuários normais)
- 👥 Listagem detalhada de cada usuário
- 🔑 Lista de administradores
- 👤 Lista de usuários normais
- 🔗 Links de edição para admin

**Exemplo de saída**:
```
📊 RESUMO GERAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total de usuários: 4
Administradores: 2
Usuários normais: 2

👥 LISTAGEM DETALHADA
┌─ ID: 2
│  Username: dev01
│  Email: dev01@zenfocus.com
│  Nome: Developer 01
│  Status: 🔑 ADMIN
│  Link de edição: https://gitlab.zenfocus.com/admin/users/2/edit
└─

🔑 ADMINISTRADORES
1. root (gitlab_admin_f6e9ef@example.com) - ID: 1
2. dev01 (dev01@zenfocus.com) - ID: 2
```

---

### 3. **gerenciador-usuarios-interativo.sh** - Gerenciador Interativo
Menu interativo para gerenciar usuários de forma visual.

**Uso**:
```bash
./scripts/gerenciador-usuarios-interativo.sh
```

**Menu de opções**:
```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║        🔐 Gerenciador de Usuários - GitLab Zenfocus       ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

1) 📋 Listar todos os usuários
2) ➕ Criar novo usuário
3) 🔑 Trocar senha de um usuário
4) 👑 Tornar usuário administrador
5) 👤 Remover privilégios de administrador
6) 🔍 Ver detalhes de um usuário
7) 🧪 Testar login de um usuário
8) ❌ Sair
```

**Como usar**:
1. Digite o número da opção
2. Siga as instruções
3. O script faz o resto automaticamente

**Exemplos de uso**:

#### Criar novo usuário (Opção 2):
```
Username: dev04
Email: dev04@zenfocus.com
Nome completo: Developer 04
Senha: ••••••••••••••
Confirme a senha: ••••••••••••••
```

#### Trocar senha (Opção 3):
```
Username: dev02
Nova Senha: ••••••••••••••

✅ Senha alterada com sucesso!
Email: dev02@zenfocus.com
Senha: NovaSenha@2024!
```

#### Tornar admin (Opção 4):
```
Username: dev03

✅ Usuário 'dev03' agora é administrador!
```

#### Testar login (Opção 7):
```
Email: dev01@zenfocus.com
Senha: ••••••••••••••

✅ Credenciais válidas!
Username: dev01
Admin: Sim
```

---

## 📋 Exemplo de Fluxo Completo

### Cenário: Criar usuários e gerenciá-los

```bash
# 1. Criar novo usuário
./scripts/criar-usuario-gitlab.sh dev04 'dev04@zenfocus.com' 'Developer 04' 'DevPass@2024!'

# 2. Listar todos
./scripts/listar-usuarios-detalhado.sh

# 3. Trocar senha do dev04
./scripts/trocar-senha-usuario.sh dev04 'NovaSenha@2024!'

# 4. Abrir gerenciador interativo
./scripts/gerenciador-usuarios-interativo.sh
# Escolher opção 4 para tornar dev04 admin
```

---

## 👥 Usuários de Teste Criados

| Username | Email | Senha | Admin |
|----------|-------|-------|-------|
| root | gitlab_admin_* | (varia) | ✅ |
| dev01 | dev01@zenfocus.com | DevUser2024!Pass@ | ✅ |
| dev02 | dev02@zenfocus.com | NovaSenha@2024! | ❌ |
| dev03 | dev03@zenfocus.com | GitLab@Secure123! | ❌ |

---

## 🔒 Senhas Recomendadas

Use senhas fortes com:
- ✅ Letras maiúsculas (A-Z)
- ✅ Letras minúsculas (a-z)
- ✅ Números (0-9)
- ✅ Símbolos especiais (@#$!%)

**Exemplos testados**:
```
DevUser2024!Pass@      ✅ RECOMENDADA
AdminRoot2024!Pass@    ✅ RECOMENDADA
SecurePass@2024!       ✅ RECOMENDADA
GitLab@Secure123!      ✅ RECOMENDADA
NovaSenha@2024!        ✅ RECOMENDADA
```

---

## 🌐 URLs Importantes

| Ação | URL |
|------|-----|
| Página inicial | https://gitlab.zenfocus.com |
| Fazer login | https://gitlab.zenfocus.com/users/sign_in |
| Admin Area | https://gitlab.zenfocus.com/admin |
| Usuários (Admin) | https://gitlab.zenfocus.com/admin/users |
| Editar usuário | https://gitlab.zenfocus.com/admin/users/{ID}/edit |

---

## 📝 Comandos Úteis via Terminal

### Ver informações de um usuário
```bash
docker exec zenfocus-gitlab gitlab-rails runner "
user = User.find_by_username('dev01')
puts \"Username: #{user.username}\"
puts \"Email: #{user.email}\"
puts \"Admin: #{user.admin}\"
"
```

### Tornar usuário admin
```bash
docker exec zenfocus-gitlab gitlab-rails runner "
user = User.find_by_username('dev03')
user.update_column(:admin, true)
puts '✅ Usuário agora é admin!'
"
```

### Remover privilégios de admin
```bash
docker exec zenfocus-gitlab gitlab-rails runner "
user = User.find_by_username('dev02')
user.update_column(:admin, false)
puts '✅ Privilégios removidos!'
"
```

### Contar usuários
```bash
docker exec zenfocus-gitlab gitlab-rails runner "
puts \"Total: #{User.count}\"
puts \"Admins: #{User.where(admin: true).count}\"
puts \"Usuários: #{User.where(admin: false).count}\"
"
```

---

## 🆘 Troubleshooting

### Script não encontrado
```bash
# Certifique-se de estar no diretório correto
cd /home/klsio27/Documentos/www/DevOps02/zenfocus-gitlab

# Tornando executável
chmod +x scripts/*.sh
```

### Container não está rodando
```bash
# Iniciar containers
docker compose up -d

# Verificar status
docker ps | grep zenfocus
```

### Erro "Usuário não encontrado"
```bash
# Listar usuários existentes
./scripts/listar-usuarios-detalhado.sh

# Ou via terminal
docker exec zenfocus-gitlab gitlab-rails runner "
User.all.each { |u| puts \"#{u.username}\" }
"
```

### Erro 422 ao fazer login
**Causa**: Senha problemática ou não escapada
**Solução**: Use uma das senhas recomendadas acima

---

## 📊 Testes Realizados

✅ **Criar usuário**: dev01, dev02, dev03
✅ **Trocar senha**: dev02 (de SecurePass@2024! para NovaSenha@2024!)
✅ **Tornar admin**: dev01 (confirmado)
✅ **Listar usuários**: Todos aparecem corretamente
✅ **Verificar status**: Admin e usuário normal diferenciados

---

## 💡 Dicas Práticas

1. **Salve as senhas em local seguro** (gerenciador de senhas)
2. **Use o script interativo** para operações frequentes
3. **Faça backup das credenciais** dos admins
4. **Teste o login** após criar/modificar usuário
5. **Revise as permissões** regularmente

---

## 🚀 Próximos Passos

Após gerenciar usuários:

1. **Faça login** com as credenciais criadas
2. **Configure perfil** pessoal
3. **Crie projetos** para trabalhar
4. **Configure SSH keys** para git via linha de comando
5. **Explore recursos** do GitLab

---

## 📞 Suporte

Para mais informações:
- Consulte `docs/ADMIN_GUIDE.md` para guia completo de admin
- Veja `docs/GUIA_USUARIOS.md` para gerenciamento de usuários
- Consulte `docs/TROUBLESHOOTING.md` para solução de problemas

---

**Última atualização**: 2 de novembro de 2025
