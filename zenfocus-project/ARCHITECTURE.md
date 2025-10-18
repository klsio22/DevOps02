# 🏗️ Arquitetura do Projeto Zenfocus

## Visão Geral da Infraestrutura

```
┌────────────────────────────────────────────────────────────────────┐
│                         CLIENTE (Host Local)                       │
│                                                                    │
│  Browser ──► http://www.zenfocus.com.br                           │
│  Browser ──► http://gitlab.zenfocus.com.br:8080                   │
└────────────────────────────────┬───────────────────────────────────┘
                                 │
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│                    DOCKER NETWORK: zenfocus-net                    │
│                      Subnet: 10.164.59.0/24                        │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │                    CAMADA DE SERVIÇOS                        │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   DNS       │  │     CA      │  │   GitLab    │              │
│  │   BIND9     │  │  Easy-RSA   │  │  gitlab-ce  │              │
│  │             │  │             │  │             │              │
│  │ :91 Port 53 │  │ :96         │  │ :92 Port    │              │
│  │             │  │             │  │   8080      │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                       │
│         └────────┬───────┴────────────────┘                       │
│                  │                                                │
│  ┌──────────────┴─────────────────────────────────────────────┐  │
│  │                 CAMADA DE APLICAÇÃO                        │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Runner    │  │   Web App   │  │   MySQL     │              │
│  │gitlab-runner│  │ nginx+php   │  │   mysql:8   │              │
│  │             │  │             │  │             │              │
│  │ :93         │  │ :94 Port 80 │  │ :95 Port    │              │
│  │             │  │             │  │   3306      │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                       │
│         └────────────────┴────────────────┘                       │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

## Fluxo de Dados

### 1. Acesso do Usuário

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│ Browser │────►│   DNS   │────►│  Nginx  │────►│   PHP   │
└─────────┘     └─────────┘     └─────────┘     └────┬────┘
                                                      │
                                                      ▼
                                                 ┌─────────┐
                                                 │  MySQL  │
                                                 └─────────┘
```

### 2. Pipeline CI/CD

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│   Git   │────►│ GitLab  │────►│ Runner  │────►│  Docker │
│  Push   │     │   CI    │     │  Build  │     │  Deploy │
└─────────┘     └─────────┘     └─────────┘     └─────────┘
```

### 3. Resolução DNS

```
Cliente ──► DNS Server ──► Resolve ──► Retorna IP
  (query)      (BIND9)     (db.zone)    (10.164.59.94)
```

## Componentes Detalhados

### 🌐 DNS Server (10.164.59.91)

**Imagem:** Custom (BIND9 on Ubuntu)  
**Função:** Resolver nomes de domínio .zenfocus.com.br  
**Portas:** 53 (UDP/TCP)  
**Volumes:** Nenhum (configuração embutida)

**Zonas DNS:**
- `zenfocus.com.br` → Forward zone
- `59.164.10.in-addr.arpa` → Reverse zone

**Registros:**
```
dns.zenfocus.com.br      → 10.164.59.91
gitlab.zenfocus.com.br   → 10.164.59.92
runner.zenfocus.com.br   → 10.164.59.93
www.zenfocus.com.br      → 10.164.59.94
db.zenfocus.com.br       → 10.164.59.95
ca.zenfocus.com.br       → 10.164.59.96
```

---

### 🔐 CA Server (10.164.59.96)

**Imagem:** Custom (Easy-RSA on Ubuntu)  
**Função:** Autoridade Certificadora para SSL/TLS  
**Volumes:** `ca-certs` (persistência de certificados)

**Certificados Gerados:**
- `ca.crt` - Certificado raiz da CA
- `www.zenfocus.com.br.crt` - Certificado do servidor web
- `gitlab.zenfocus.com.br.crt` - Certificado do GitLab

---

### 🦊 GitLab (10.164.59.92)

**Imagem:** `gitlab/gitlab-ce:latest`  
**Função:** Repositório Git e CI/CD  
**Portas:**
- 8080 (HTTP)
- 8443 (HTTPS)
- 2222 (SSH)

**Volumes:**
- `gitlab-config` → `/etc/gitlab`
- `gitlab-logs` → `/var/log/gitlab`
- `gitlab-data` → `/var/opt/gitlab`

**Recursos:**
- PostgreSQL (embutido)
- Redis (embutido)
- Nginx (embutido)
- GitLab Runner integration

---

### 🏃 GitLab Runner (10.164.59.93)

**Imagem:** `gitlab/gitlab-runner:latest`  
**Função:** Executor de pipelines CI/CD  
**Executor:** Docker  
**Privileged:** Sim

**Volumes:**
- `/var/run/docker.sock` (acesso ao Docker host)
- `runner-config` → `/etc/gitlab-runner`

**Capabilities:**
- Build Docker images
- Run Docker containers
- Access Docker network

---

### 🌐 Web Application (10.164.59.94)

**Imagem:** Custom (PHP 8.2 + Nginx)  
**Função:** Aplicação Zenfocus (CRUD Pomodoro)  
**Portas:**
- 80 (HTTP)
- 443 (HTTPS - futuro)

**Stack:**
- Nginx 1.24
- PHP-FPM 8.2
- PHP Extensions: PDO, MySQL, GD

**Volumes:**
- `./web-app/src` → `/var/www/html` (código-fonte)
- `ca-certs` → `/etc/ssl/zenfocus` (certificados SSL)

**Endpoints:**
- `/` - Frontend HTML/CSS/JS
- `/api.php` - REST API
- `/api.php?action=health` - Health check

---

### 🗄️ MySQL (10.164.59.95)

**Imagem:** `mysql:8.0`  
**Função:** Banco de dados relacional  
**Porta:** 3306

**Volumes:**
- `mysql-data` → `/var/lib/mysql` (persistência)
- `./web-app/src/database.sql` → `/docker-entrypoint-initdb.d/init.sql`

**Database Schema:**
```sql
CREATE TABLE tarefas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    tempo_estimado INT,
    pomodoros_concluidos INT DEFAULT 0,
    data_criacao DATETIME,
    status ENUM('pendente', 'em_andamento', 'concluida')
);
```

**Credenciais:**
- Root: `zenfocus123`
- User: `zenfocus` / `zenfocus123`
- Database: `zenfocus_db`

---

## Fluxo de Requisição Web

```
┌──────────────────────────────────────────────────────────────┐
│ 1. Cliente faz requisição                                    │
│    http://www.zenfocus.com.br/api.php?action=list            │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. DNS resolve www.zenfocus.com.br → 10.164.59.94            │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 3. Nginx recebe na porta 80                                  │
│    - Verifica location /api.php                              │
│    - Passa para PHP-FPM (127.0.0.1:9000)                     │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 4. PHP processa api.php                                      │
│    - Conecta ao MySQL (zenfocus-db:3306)                     │
│    - Executa query: SELECT * FROM tarefas                    │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 5. MySQL retorna dados                                       │
│    - Resultado em formato array                              │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 6. PHP formata resposta JSON                                 │
│    - json_encode($tasks)                                     │
│    - Header: Content-Type: application/json                  │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 7. Cliente recebe resposta JSON                              │
│    - JavaScript processa com fetch()                         │
│    - Atualiza DOM dinamicamente                              │
└──────────────────────────────────────────────────────────────┘
```

## Fluxo do Pipeline CI/CD

```
┌──────────────────────────────────────────────────────────────┐
│ 1. Desenvolvedor faz git push                                │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. GitLab detecta push                                       │
│    - Lê .gitlab-ci.yml                                       │
│    - Cria pipeline com jobs                                  │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 3. GitLab envia jobs para Runner                             │
│    - Runner recebe via API                                   │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 4. STAGE: BUILD                                              │
│    - Runner executa: docker build                            │
│    - Salva imagem: docker save > artifact                    │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 5. STAGE: TEST                                               │
│    - Test Syntax: php -l *.php                               │
│    - Test App: curl health endpoint                          │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 6. STAGE: DEPLOY (manual)                                    │
│    - docker load < artifact                                  │
│    - docker stop container antigo                            │
│    - docker run novo container                               │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ 7. STAGE: NOTIFY                                             │
│    - Webhook Discord/Slack                                   │
│    - Notifica sucesso/falha                                  │
└──────────────────────────────────────────────────────────────┘
```

## Comunicação entre Containers

```
┌─────────┐                    ┌─────────┐
│   Web   │◄──────────────────►│  MySQL  │
│  App    │   PDO Connection   │         │
└────┬────┘                    └─────────┘
     │
     │ Health checks
     ▼
┌─────────┐                    ┌─────────┐
│   DNS   │                    │ GitLab  │
│ Server  │                    │   CE    │
└─────────┘                    └────┬────┘
                                    │
                                    │ Jobs
                                    ▼
                               ┌─────────┐
                               │ Runner  │
                               └─────────┘
```

## Segurança

### Network Isolation

- **Rede Interna:** `zenfocus-net` (10.164.59.0/24)
- **Firewall:** Apenas portas necessárias expostas
- **Containers:** Comunicam via rede Docker interna

### Portas Expostas ao Host

| Porta | Serviço | Protocolo |
|-------|---------|-----------|
| 53 | DNS | UDP/TCP |
| 80 | Web App | HTTP |
| 8080 | GitLab | HTTP |
| 2222 | GitLab SSH | SSH |

### Credenciais

**Produção:** Use variáveis de ambiente seguras  
**Desenvolvimento:** Credenciais em `.env.example`

### SSL/TLS

- **CA própria:** Easy-RSA
- **Certificados:** Auto-assinados
- **Futuro:** Let's Encrypt para produção

---

## Recursos e Performance

### Requisitos Mínimos

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disco | 10 GB | 20 GB |

### Uso Estimado por Container

| Container | CPU | RAM | Disco |
|-----------|-----|-----|-------|
| DNS | 0.1 | 64 MB | 100 MB |
| GitLab | 2.0 | 2 GB | 5 GB |
| Runner | 0.5 | 512 MB | 1 GB |
| Web App | 0.3 | 256 MB | 500 MB |
| MySQL | 0.5 | 512 MB | 2 GB |
| CA | 0.1 | 64 MB | 100 MB |

---

## Escalabilidade

### Horizontal Scaling

**Web App:**
```yaml
deploy:
  replicas: 3
  update_config:
    parallelism: 1
```

**Load Balancer:**
```
HAProxy/Nginx → [Web1, Web2, Web3] → MySQL
```

### Vertical Scaling

Ajustar recursos no `docker-compose.yml`:

```yaml
services:
  mysql:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

---

**📚 Documentação técnica detalhada - Zenfocus Project**
