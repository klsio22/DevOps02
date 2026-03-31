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
- **Gitea nao inicia

Verifique logs:
```bash
docker compose logs gitea
```
Aguarde 2-5 minutos para inicializacao completa.

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

Regere os certificados:
```bash
docker compose up --build --force-recreate ca
docker compose restart gitea proxy
```

### Conflito de Portas

Edite `.env` e altere:
```
GITEA_SSH_PORT=2222
DNS_PORT=1053
APP_PORT=8080
PROXY_HTTP_PORT=80
PROXY_HTTPS_PORT=443
```r web com FQDN e certificados  
✅ **REQ15:** Ambiente Docker orquestrado  

## Troubleshooting

### DNS nao resolve

Verifique se o container DNS esta rodando:
```bash
docker ps | grep zenfocus-gitea-dns
```

Teste resolucao DNS:
```bash
dig @127.0.0.1 -p 1053 gitea.zenfocus.com A
```

### Certificado SSL invalido

Regere os certificados:
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
```

## Documentacao

- [Project Summary](docs/project-summary.md)
- [Objectives for Work](docs/objectives-for-work.md)
- [Create Users GitLab](docs/create-users-gitlab.md)

## Licenca

Este projeto é parte de trabalho academico - UTFPR - DevOps02

```bash
sudo -- sh -c "echo '127.0.0.1 gitlab.zenfocus.com' >> /etc/hosts"
```

2. Tornar o script executável e iniciar:

```bash
chmod +x start-zenfocus.sh
./start-zenfocus.sh
```

3. Exibir senha inicial do root:

Ao final do `./start-zenfocus.sh`, as credenciais iniciais do root ja sao exibidas automaticamente.

Se quiser consultar novamente depois, execute:

```bash
chmod +x scripts/show-gitlab-credentials.sh
./scripts/show-gitlab-credentials.sh
```

Tambem e possivel informar container e dominio manualmente:

```bash
./scripts/show-gitlab-credentials.sh zenfocus-gitlab gitlab.zenfocus.com
```

Observacao: se a senha inicial nao estiver disponivel (por exemplo, ja consumida na primeira autenticacao), o script exibira `NAO_ENCONTRADA`.

Importante: a senha inicial do `root` é temporária e o arquivo `/etc/gitlab/initial_root_password` normalmente
deixa de existir após 24h. Salve a senha assim que ela aparecer.

Scripts Disponíveis
-------------------

### `show-gitlab-credentials.sh`
Exibe a senha inicial do root do GitLab. Útil para resgatar as credenciais após a inicialização.

**Uso:**
```bash
./scripts/show-gitlab-credentials.sh
# ou com argumentos customizados:
./scripts/show-gitlab-credentials.sh zenfocus-gitlab gitlab.zenfocus.com
```

### `delete-gitlab-user.rb`
Script Ruby para deletar usuários do GitLab por nome de usuário, nome completo ou email. Inclui validações de segurança (impede deleção do root) e suporta deleção hard (remove contribuições).

**Uso:**
```bash
# Deletar por nome de usuário
./scripts/delete-gitlab-user.rb "nome_usuario"

# Deletar por nome completo
./scripts/delete-gitlab-user.rb "Nome Completo"

# Deletar por email
./scripts/delete-gitlab-user.rb "email@example.com"

# Hard delete (remove contribuições)
./scripts/delete-gitlab-user.rb "nome_usuario" --hard-delete
```

**Exemplos:**
```bash
# Deletar o usuário 'zenadmin'
./scripts/delete-gitlab-user.rb "zenadmin"

# Hard delete do usuário 'admin_test'
./scripts/delete-gitlab-user.rb "admin_test" --hard-delete
```

**Notas:**
- O script valida se o usuário é root e nega a deleção para evitar acidentes
- Retorna código de saída 0 em caso de sucesso, 1 em caso de erro
- A deleção sem `--hard-delete` mantém as contribuições e dados associados
- A deleção com `--hard-delete` remove todas as contribuições do usuário

Configuração de Recursos
------------------------

O `docker-compose.yml` está otimizado para ambientes de laboratório com recursos limitados (6GB de RAM, 4 CPUs). As seguintes configurações estão aplicadas:

- **Puma (Web Server Rails)**:
  - `worker_processes = 2` (reduzido de auto-scale para limitar uso de memória)
  - `min_threads = 4` e `max_threads = 4` (concorrência controlada)
  
- **Sidekiq (Background Jobs)**:
  - `max_concurrency = 10` (limitado para evitar picos de memória)
  
- **Shared Memory**:
  - `shm_size: 512m` (suficiente para o Puma tuning)

**Por que essas mudanças?**

O GitLab por padrão tenta auto-escalar Puma para o número de CPUs disponíveis na máquina hospedeira. Em ambientes lab com restrições de memória, isso pode causar Out-of-Memory e reinicializações em cascata. Essas configurações reduzem o footprint de memória mantendo a funcionalidade.

Se você aumentar os limites de recursos no `docker-compose.yml` (ex: `mem_limit`), poderá aumentar correspondentemente:
```yaml
puma['worker_processes'] = 4  # Aumentar conforme necessário
sidekiq['max_concurrency'] = 20  # Aumentar conforme necessário
services:
  gitlab:
    mem_limit: 8g  # Aumentado de 6g
```

4. (Opcional) Redefinir senha root manualmente:

```bash
docker exec -it zenfocus-gitlab bash
gitlab-rake "gitlab:password:reset[root]"
```

- Nao interativa (definir uma nova senha diretamente):

```bash
docker exec -it zenfocus-gitlab \
    gitlab-rails runner "user = User.find_by_username('root'); user.password = 'NovaSenhaSegura123!'; user.password_confirmation = 'NovaSenhaSegura123!'; user.save!; puts 'Senha root alterada.'"
```

5. Habilitar SSL (opcional):

- Coloque `gitlab.zenfocus.com.crt` e `.key` em `gitlab/ssl/` e ajuste `docker-compose.yml` como descrito no guia.

Gerar certificados com o serviço `ca` (recomendado):

```bash
# Constrói e roda o container de CA que gera os certificados em ./gitlab/ssl
docker compose build ca
docker compose run --rm ca
```

Isso irá criar em `gitlab/ssl/` os arquivos:

- `zenfocus-ca.crt.pem` (CA pública)
- `zenfocus-ca.key.pem` (CA privada)
- `gitlab.zenfocus.com.crt` (certificado do GitLab assinado pela CA)
- `gitlab.zenfocus.com.key` (chave privada do GitLab)

Após isso, reinicie o GitLab:

```bash
docker compose up -d gitlab
```

Comandos úteis:

```bash
#como fechar todos os containers
docker stop $(docker ps -aq)
# Parar serviços
docker compose down
# Reiniciar GitLab
docker compose restart gitlab
# Backup dos dados
docker compose exec gitlab gitlab-backup create
# Atualizar imagens e reiniciar
docker compose pull
docker compose up -d
```

Notas:
- O GitLab leva alguns minutos para inicializar na primeira execução.
- Se você usar o DNS interno, verifique conflitos de porta 53 no host.
- Esse setup é pensado para ambientes de laboratório e desenvolvimento.

DNS via porta alternativa
------------------------

Para evitar conflitos com serviços do host (ex.: systemd-resolved), o DNS do container está mapeado para a porta 1053 do host. Para consultar diretamente use:

```bash
dig @127.0.0.1 -p 1053 gitlab.zenfocus.com A
```

Se quiser que o sistema use essa resolução automaticamente, você pode configurar temporariamente o gerenciador de DNS do seu host para encaminhar consultas para 127.0.0.1:1053 ou ajustar `/etc/resolv.conf` (aviso: essas mudanças podem impactar o sistema).

Troubleshooting
---------------

### HTTP 502 Bad Gateway

**Sintoma:** Você recebe erros HTTP 502 em operações (ex: salvar configurações de admin, deletar usuários) e posteriormente "Waiting for GitLab to boot".

**Causa comum:** O processo Puma (servidor Rails) morreu ou foi reiniciado em cascata. Em ambientes com recursos limitados, isso acontece quando a configuração de workers não está ajustada para a máquina.

**Solução:**

1. Verifique os logs do Puma:
```bash
docker exec zenfocus-gitlab tail -f /var/log/gitlab/puma/puma_stdout.log
```

2. Se ver "Detected parent died, dying" repetidamente, a configuração de workers está consumindo muita memória. Reduza os workers em `docker-compose.yml`:

```yaml
environment:
  GITLAB_OMNIBUS_CONFIG: |
    puma['worker_processes'] = 2
    puma['min_threads'] = 4
    puma['max_threads'] = 4
    sidekiq['max_concurrency'] = 10
```

3. Reinicie o container:
```bash
docker compose down gitlab
docker compose up -d gitlab
```

### GitLab demora muito para inicializar

**Solução:** A primeira inicialização pode levar 5-15 minutos dependendo dos recursos da máquina. Verifique o status:

```bash
docker compose logs -f gitlab
```

Procure por mensagens como "GitLab is booting" ou espere por uma mensagem de "ready" ou "started".

### Certificados SSL não funcionam

**Solução:** Use o script de geração de certificados:

```bash
docker compose build ca
docker compose run --rm ca
docker compose up -d gitlab
```

Verifique se os arquivos foram criados em `gitlab/ssl/`:
```bash
ls -la gitlab/ssl/
```
