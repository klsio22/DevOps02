# Guia de Gerenciamento de Usuários - GitLab Zenfocus

## 📋 Resumo Rápido

Este guia mostra como criar, listar e gerenciar usuários no GitLab containerizado.

## 🆕 Criar Novo Usuário

Use o script automatizado:

```bash
./scripts/criar-usuario-gitlab.sh <username> <email> <nome> <senha>
```

**Exemplo**:

```bash
./scripts/criar-usuario-gitlab.sh dev1 dev1@gitlab.zenfocus.com 'Developer 1' 'SenhaSeg@2024!'
```

O script irá:
- ✅ Verificar se o usuário já existe
- ✅ Criar novo usuário (se não existir) ou redefinir senha (se já existir)
- ✅ Pular confirmação de email
- ✅ Exibir credenciais para login

## 📊 Listar Usuários

```bash
./scripts/listar-usuarios-gitlab.sh
```

Exibe uma tabela com:
- ID do usuário
- Username
- Email
- Status de Admin

## 👥 Usuários Existentes

| Username | Email | Senha | Admin |
|----------|-------|-------|-------|
| root | admin@gitlab.zenfocus.com | (senha root definida) | ✓ |
| dev1 | dev1@zenfocus.com | DevUser2024!Pass@ | ✗ |
| dev4 | dev4@gitlab.zenfocus.com | DevUser2024!Pass@ | ✗ |

## 🔐 Fazer Login na Plataforma

1. **Abra o navegador** e acesse:
   ```
   https://gitlab.zenfocus.com
   ```

2. **Use o email do usuário**:
   - Para dev4: `dev4@gitlab.zenfocus.com`

3. **Digite a senha**:
   - `DevUser2024!Pass@`

4. **Clique em "Sign in"**

## 🔧 Comandos Úteis Via Terminal

### Redefinir senha de usuário específico

```bash
docker exec zenfocus-gitlab gitlab-rails runner "
user = User.find_by_username('dev1')
user.password = 'NovaSenha@123!'
user.password_confirmation = 'NovaSenha@123!'
user.save(validate: false)
puts 'Senha atualizada!'
"
```

### Ver detalhes de um usuário

```bash
docker exec zenfocus-gitlab gitlab-rails runner "
user = User.find_by_username('dev1')
puts \"Username: #{user.username}\"
puts \"Email: #{user.email}\"
puts \"Nome: #{user.name}\"
puts \"Admin: #{user.admin}\"
puts \"Confirmado: #{user.confirmed?}\"
"
```

### Listar todos os emails

```bash
docker exec zenfocus-gitlab gitlab-rails runner "
User.all.each { |u| puts \"#{u.username}: #{u.email}\" }
"
```

### Tornar usuário admin

```bash
docker exec zenfocus-gitlab gitlab-rails runner "
user = User.find_by_username('dev1')
user.admin = true
user.save!
puts 'Usuário agora é admin!'
"
```

## 🚀 Próximos Passos

Após fazer login:

1. **Configure seu perfil**
   - Adicione foto de perfil
   - Configure notificações

2. **Crie um projeto**
   - Clique em "New project"
   - Escolha "Create blank project"

3. **Configure SSH (opcional)**
   - Vá em Settings > SSH Keys
   - Adicione sua chave pública SSH

4. **Clone um repositório**
   ```bash
   git clone https://gitlab.zenfocus.com/<username>/<projeto>.git
   ```

## 📝 Notas Importantes

- ⚠️ As senhas devem ser fortes (letras maiúsculas, minúsculas, números e símbolos)
- ⚠️ O GitLab não aceita senhas comuns ou fracas
- ✅ Confirmação de email é automaticamente ignorada
- ✅ Usuários podem logar imediatamente após criação

## 🆘 Troubleshooting

### Problema: "Senha muito fraca"

**Solução**: Use uma senha com pelo menos:
- 8 caracteres
- Letras maiúsculas e minúsculas
- Números
- Símbolos especiais (@, #, $, !, etc.)

### Problema: "Não consigo fazer login"

**Soluções**:
1. Verifique se está usando o **email**, não o username
2. Verifique se a senha está correta (case-sensitive)
3. Tente redefinir a senha com o script

### Problema: "Container não está rodando"

**Solução**:
```bash
# Verificar status
docker ps -a | grep gitlab

# Iniciar se necessário
docker compose up -d gitlab
```

## 📧 Formato de Emails

Por padrão, os emails seguem o formato:
```
<username>@zenfocus.com
```

Exemplos:
- dev1 → dev1@zenfocus.com
- dev2 → dev2@zenfocus.com
- johndoe → johndoe@zenfocus.com

## ⚙️ Scripts Disponíveis

| Script | Descrição |
|--------|-----------|
| `scripts/criar-usuario-gitlab.sh` | Criar ou redefinir senha de usuário |
| `scripts/listar-usuarios-gitlab.sh` | Listar todos os usuários |

## 🔗 Links Úteis

- GitLab Web: <https://gitlab.zenfocus.com>
- GitLab SSH: `git@gitlab.zenfocus.com:2222`
- Documentação GitLab: <https://docs.gitlab.com>
