# 🚀 Guia Rápido - Zenfocus

## Início Rápido em 3 Passos

### 1️⃣ Iniciar o Projeto

```bash
cd zenfocus-project
./setup.sh
```

Ou manualmente:

```bash
docker-compose up -d
```

### 2️⃣ Configurar DNS (escolha uma opção)

**Opção A - /etc/hosts (recomendado):**

```bash
sudo bash -c 'cat >> /etc/hosts <<EOF
10.164.59.94 www.zenfocus.com.br zenfocus.com.br
10.164.59.92 gitlab.zenfocus.com.br
EOF'
```

**Opção B - Nameserver:**

```bash
sudo bash -c 'echo "nameserver 10.164.59.91" > /etc/resolv.conf'
```

### 3️⃣ Acessar Aplicação

- **Web App:** http://www.zenfocus.com.br
- **GitLab:** http://gitlab.zenfocus.com.br:8080

---

## 📋 Checklist de Configuração GitLab

### 1. Obter Senha Root

```bash
docker exec zenfocus-gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

### 2. Acessar GitLab

- URL: http://gitlab.zenfocus.com.br:8080
- Usuário: `root`
- Senha: [obtida no passo 1]

### 3. Criar Projeto

1. Clique em "New Project"
2. Nome: `Zenfocus`
3. Visibilidade: Private
4. Criar projeto

### 4. Obter Token do Runner

1. Admin Area (ícone de chave inglesa)
2. CI/CD > Runners
3. Copie o Registration Token

### 5. Registrar Runner

```bash
docker exec -it zenfocus-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab.zenfocus.com.br" \
  --registration-token "SEU_TOKEN_AQUI" \
  --executor "docker" \
  --docker-image "docker:24-dind" \
  --description "zenfocus-docker-runner" \
  --docker-privileged \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"
```

### 6. Fazer Push do Código

```bash
cd /media/klsio27/outher-files/documentos/utfpr/DevOps02/zenfocus-project

git init
git add .
git commit -m "Initial commit: Zenfocus project"

# Substitua com a URL do seu projeto GitLab
git remote add origin http://gitlab.zenfocus.com.br:8080/root/zenfocus.git

# Faça push
git push -u origin main
```

---

## 🧪 Testar Aplicação

```bash
./test.sh
```

Ou manualmente:

```bash
# Health Check
curl http://www.zenfocus.com.br/api.php?action=health

# Listar tarefas
curl http://www.zenfocus.com.br/api.php?action=list

# Testar frontend
curl http://www.zenfocus.com.br/
```

---

## 🔍 Verificar Status

```bash
# Status dos containers
docker-compose ps

# Logs em tempo real
docker-compose logs -f

# Logs de um serviço específico
docker-compose logs -f web-app

# Health checks
docker ps --format "table {{.Names}}\t{{.Status}}"
```

---

## 🛑 Parar/Reiniciar

```bash
# Parar tudo
docker-compose down

# Parar e remover volumes
docker-compose down -v

# Reiniciar serviço específico
docker-compose restart web-app

# Rebuild
docker-compose up -d --build web-app
```

---

## 🐛 Troubleshooting Rápido

### GitLab não carrega

```bash
# Aguarde 5-10 minutos
docker-compose logs -f gitlab

# Se necessário, reinicie
docker-compose restart gitlab
```

### Aplicação não conecta ao banco

```bash
# Verificar MySQL
docker-compose ps mysql

# Ver logs
docker-compose logs mysql

# Reiniciar
docker-compose restart mysql
```

### DNS não resolve

```bash
# Testar DNS
nslookup www.zenfocus.com.br 10.164.59.91

# Ou adicione ao /etc/hosts
sudo bash -c 'echo "10.164.59.94 www.zenfocus.com.br" >> /etc/hosts'
```

### Runner não aparece no GitLab

```bash
# Verificar status
docker exec zenfocus-runner gitlab-runner verify

# Re-registrar
docker exec -it zenfocus-runner gitlab-runner register
```

---

## 📊 Comandos Úteis

### Banco de Dados

```bash
# Acessar MySQL
docker exec -it zenfocus-db mysql -uzenfocus -pzenfocus123 zenfocus_db

# Backup
docker exec zenfocus-db mysqldump -uzenfocus -pzenfocus123 zenfocus_db > backup.sql

# Restaurar
docker exec -i zenfocus-db mysql -uzenfocus -pzenfocus123 zenfocus_db < backup.sql
```

### Monitoramento

```bash
# Uso de recursos
docker stats

# Logs de erro
docker-compose logs | grep -i error

# Espaço em disco
docker system df
```

### Limpeza

```bash
# Script automático
./cleanup.sh

# Manual
docker-compose down -v
docker system prune -a
```

---

## 📚 Estrutura de IPs

| Serviço | IP | Porta | URL |
|---------|------------|-------|-----|
| DNS | 10.164.59.91 | 53 | dns.zenfocus.com.br |
| GitLab | 10.164.59.92 | 8080 | gitlab.zenfocus.com.br:8080 |
| Runner | 10.164.59.93 | - | - |
| Web App | 10.164.59.94 | 80 | www.zenfocus.com.br |
| MySQL | 10.164.59.95 | 3306 | db.zenfocus.com.br |
| CA | 10.164.59.96 | - | ca.zenfocus.com.br |

---

## 🎯 Endpoints da API

```bash
# Health Check
GET /api.php?action=health

# Listar tarefas
GET /api.php?action=list

# Obter tarefa
GET /api.php?action=get&id=1

# Criar tarefa
POST /api.php
  action=create
  titulo=Minha Tarefa
  descricao=Descrição
  tempo_estimado=25
  status=pendente

# Atualizar tarefa
POST /api.php
  action=update
  id=1
  titulo=Tarefa Atualizada
  status=concluida

# Deletar tarefa
POST /api.php
  action=delete
  id=1

# Incrementar pomodoro
POST /api.php
  action=increment_pomodoro
  id=1
```

---

## 🔄 Pipeline CI/CD

### Stages

1. **Build** - Construir imagem Docker
2. **Test** - Testes de sintaxe e integração
3. **Deploy** - Deploy em staging/produção
4. **Notify** - Notificações

### Executar Pipeline

```bash
# Fazer commit
git add .
git commit -m "Update"
git push origin main

# Pipeline roda automaticamente
# Ver em: GitLab > CI/CD > Pipelines
```

---

## 💡 Dicas

1. **Primeiro acesso ao GitLab:** Aguarde 5-10 minutos
2. **Senha expirada:** GitLab pedirá para alterar no primeiro login
3. **Runner não registrado:** Use o token correto do GitLab
4. **Pipeline falha:** Verifique se o runner está ativo
5. **Porta ocupada:** Altere portas no docker-compose.yml

---

## 📖 Documentação Completa

Veja `README.md` para documentação detalhada.

---

**Desenvolvido para o curso de DevOps - UTFPR**
