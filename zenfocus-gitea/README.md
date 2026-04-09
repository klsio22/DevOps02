# Zenfocus Gitea - Ambiente DevOps Completo

## Visao Geral

Este projeto implementa um ambiente DevOps completo para a empresa ficticia **Zenfocus Solutions**, com:

- **Gitea** como plataforma de versionamento Git
- **DNS** BIND9 para resolucao de nomes
- **CA** (Autoridade Certificadora) para certificados SSL/TLS
- **Proxy** Nginx para reverse proxy HTTPS
- **Aplicacao Web CRUD** em PHP/MariaDB
- **Banco de Dados** MariaDB para Gitea e aplicacao

## Dominios Configurados

- `gitea.zenfocus.com` - Plataforma Gitea
- `www.zenfocus.com` - Aplicacao Web CRUD
- `zenfocus.com` - Zona DNS principal

## Estrutura do Projeto

```
zenfocus-gitea/
├── docker-compose.yml          # Orquestracao de containers
├── .env.example                # Modelo de variaveis de ambiente
├── start-zenfocus.sh           # Script de inicializacao
├── README.md                   # Este arquivo
├── app/                        # Aplicacao Web CRUD
│   ├── Dockerfile
│   ├── index.php               # CRUD de tarefas
│   ├── init.sql                # Schema da aplicacao
│   ├── init-gitea.sql          # Schema do Gitea
│   ├── styles.css
│   └── logo.svg                # Logotipo Zenfocus
├── ca/                         # Autoridade Certificadora
│   ├── Dockerfile
│   └── generate-certs.sh       # Gera CA e certificados
├── dns/                        # Servidor DNS
│   └── data/
│       ├── named.conf.local    # Configuracao BIND9
│       └── db.zenfocus.com     # Zona DNS
├── gitea/                      # Dados do Gitea (gerados automaticamente)
│   ├── config/
│   ├── data/
│   ├── logs/
│   └── ssl/                    # Certificados SSL
├── proxy/                      # Proxy Nginx
│   ├── nginx.conf
│   └── site.conf
└── scripts/
    └── show-gitea-credentials.sh  # Exibe credenciais
```

## Requisitos

- Docker e Docker Compose instalados
- Permissao para executar comandos Docker
- Ports 80, 443, 2222 (SSH), 1053 (DNS) disponiveis

## Inicializacao Rapida

### 1. Configurar Variaveis de Ambiente

```bash
cp .env.example .env
# Edite o arquivo .env conforme necessario
```

### 2. Configurar Hosts Locais (Opcional para testes)

```bash
sudo sh -c "echo '127.0.0.1 gitea.zenfocus.com' >> /etc/hosts"
sudo sh -c "echo '127.0.0.1 www.zenfocus.com' >> /etc/hosts"
```

### 3. Iniciar Ambiente

```bash
./start-zenfocus.sh
```

O script ira:
1. Criar a rede Docker `zenfocus-gitea-net` (10.30.30.0/24)
2. Gerar certificados SSL com a CA
3. Iniciar todos os 6 containers

### 4. Acessar Servicos

- **Gitea (Web):** https://gitea.zenfocus.com
- **Gitea (SSH):** `ssh://git@gitea.zenfocus.com:2222`
- **Aplicacao:** http://www.zenfocus.com:8080

### 5. Ver Credenciais

```bash
./scripts/show-gitea-credentials.sh
```

### 6. Primeira Execucao

- Aguarde 2-5 minutos para inicializacao completa do Gitea
- Acesse https://gitea.zenfocus.com para configuracao inicial
- Crie usuario administrador no Gitea

## Comandos Uteis

### Gerencia de Containers

```bash
# Ver status dos containers
docker compose ps

# Ver logs em tempo real
docker compose logs -f

# Ver logs de servico especifico
docker compose logs gitea
docker compose logs app
docker compose logs proxy

# Parar ambiente
docker compose down

# Reiniciar ambiente
docker compose down && docker compose up -d

# Reiniciar servico especifico
docker compose restart gitea
```

### Acesso a Containers

```bash
# Acessar terminal do Gitea
docker exec -it zenfocus-gitea /bin/bash

# Acessar terminal da aplicacao
docker exec -it zenfocus-gitea-app /bin/bash

# Acessar banco de dados
docker exec -it zenfocus-gitea-db mysql -u root -p
```

### Teste de DNS

```bash
# Testar resolucao DNS
dig @127.0.0.1 -p 1053 gitea.zenfocus.com A
dig @127.0.0.1 -p 1053 www.zenfocus.com A
```

## Topologia de Rede

```
┌─────────────────────────────────────────────────────┐
│                  zenfocus-gitea-net                  │
│                   10.30.30.0/24                      │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │   DNS    │  │    CA    │  │  Gitea   │          │
│  │ 10.30.30 │  │ 10.30.30 │  │ 10.30.30 │          │
│  │   .10    │  │   .30    │  │   .20    │          │
│  └──────────┘  └──────────┘  └──────────┘          │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │  Proxy   │  │   App    │  │    DB    │          │
│  │   (Nginx)│  │  (PHP)   │  │ (MariaDB)│          │
│  │          │  │ 10.30.30 │  │ 10.30.30 │          │
│  │          │  │   .21    │  │   .22    │          │
│  └──────────┘  └──────────┘  └──────────┘          │
└─────────────────────────────────────────────────────┘
         │                │                │
         │                │                │
    Porta 53/1053    Porta 80/443    Porta 3306
    (DNS)           (HTTP/HTTPS)     (MySQL)
                                      Porta 2222
                                      (Gitea SSH)
```

## Aplicacao Web CRUD

A aplicacao em `app/` implementa um CRUD simples de tarefas com:

- **Tabela:** `tasks`
- **Campos:** id, title, description, status, due_date, created_at

## Troubleshooting

### DNS nao resolve

Verifique se o container DNS esta rodando:
```bash
docker ps | grep zenfocus-gitea-dns
```

Teste resolucao DNS:
```bash
dig @127.0.0.1 -p 1053 gitea.zenfocus.com A
dig @127.0.0.1 -p 1053 www.zenfocus.com A
```

### Certificado SSL invalido

Regenere os certificados:
```bash
docker compose up --build --force-recreate ca
docker compose restart gitea proxy
```

### Gitea nao inicia

Verifique logs:
```bash
docker compose logs gitea
```

Aguarde 2-5 minutos para inicializacao completa.

### Conflito de portas

Edite `.env` e altere as portas:
```
GITEA_SSH_PORT=2222
DNS_PORT=1053
APP_PORT=8080
PROXY_HTTP_PORT=80
PROXY_HTTPS_PORT=443
```

## Documentacao

- [Project Summary](docs/project-summary.md)
- [Objectives for Work](docs/objectives-for-work.md)
- [ACT Runner Gitea](docs/act-runner-gitea.md)
- [SSL Permissions](docs/ssl-permissions.md)

## Licenca

Este projeto e parte de trabalho academico - UTFPR - DevOps02
