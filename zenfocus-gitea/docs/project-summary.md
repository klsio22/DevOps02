# Projeto Zenfocus

## Visao geral

- Nome: Zenfocus - Sistema de Gerenciamento Pomodoro
- Empresa ficticia: Zenfocus Solutions
- Dominio principal do ambiente: zenfocus.com
- Tipo: aplicacao web CRUD com infraestrutura DevOps completa

## Entregas principais

### 1) Aplicacao web

- Stack: PHP 8.2 com HTML/CSS/JS
- Banco: MariaDB
- Funcionalidades:
  - CRUD de tarefas
  - Temporizador Pomodoro (25 min foco / 5 min pausa)
  - Contagem de pomodoros
  - Interface responsiva

### 2) Infraestrutura e rede

- Docker Compose com servicos de DNS, CA, Gitea, proxy e app
- DNS com BIND9 para a zona zenfocus.com
- Registros para ns, gitea e www na rede docker (10.30.30.0/24)

### 3) Certificados e TLS

- CA local dedicada ao projeto
- Certificados para:
  - gitea.zenfocus.com
  - www.zenfocus.com

### 4) Gitea e CI/CD

- Gitea como plataforma de versionamento Git
- Pipeline com estagios de build, test, deploy e notify
- Testes automatizados e health checks

## Resumo tecnico das mudancas aplicadas

- `docker-compose.yml`
  - Hostname do Gitea atualizado para gitea.zenfocus.com
  - `external_url` e caminhos SSL ajustados para `.com`
  - Subnet alterada para 10.30.30.0/24

- `ca/generate-certs.sh`
  - Geracao de CA local e certificado para gitea.zenfocus.com

- `proxy/site.conf`
  - Server blocks para gitea.zenfocus.com e www.zenfocus.com
  - Proxy do Gitea para `http://gitea:3000`
  - Proxy do App para `http://app:80`

- `dns/data/named.conf.local` e `dns/data/db.zenfocus.com`
  - Zona configurada para zenfocus.com
  - A records para ns, gitea, www e db

- `start-zenfocus.sh`
  - Fluxo de inicializacao alinhado ao dominio `.com`
  - Inicializacao dos servicos do Gitea
  - Chamada do script `show-gitea-credentials.sh` para exibir credenciais

- `show-gitea-credentials.sh`
  - Script dedicado para consultar e exibir credenciais do Gitea
  - Pode ser executado de forma independente apos o ambiente subir

## Diagnostico realizado (acesso web)

### Sintoma

Ao abrir `http://www.zenfocus.com`, ocorreu erro de resolucao DNS no navegador.

### Causa

O host local nao tinha o nome esperado no `/etc/hosts`, entao o navegador nao resolvia o dominio para o proxy local.

### Validacao feita
ea, proxy e app

### Correcao recomendada

Adicionar entradas de hosts locais quando necessario, por exemplo:

```bash
sudo sh -c "echo '127.0.0.1 www.zenfocus.com' >> /etc/hosts"
sudo sh -c "echo '127.0.0.1 gitea.zenfocus.com' >> /etc/hosts"
```

Depois, limpar cache DNS do sistema e do navegador.

## Passo a passo para inicializacao no host com Docker

1. Clonar repositorio do projeto.
2. Copiar `.env.example` para `.env` e ajustar variaveis.
3. Gerar certificados com o servico `ca`: `./start-zenfocus.sh`
4. Subir `dns`, `gitea`, `proxy`, `db` e `app`.
5. Exibir credenciais com `./scripts/show-gitea-credentials.sh`.
6. Aguardar 2-5 minutos para inicializacao completa do Gitea.
7. Validar logs, portas e conectividade HTTPS.
8. Instalar a CA local no sistema para remover alertas de certificado.

## Diagnostico rapido para erro 502 no proxy

Principais causas:

- Gitea indisponivel ou em inicializacao
- Gitea sem listener em 3000
- Certificados ausentes/invalidos no volume `gitea/ssl`

Checagens uteis:

- `docker compose ps`
- `docker logs zenfocus-gitea-proxy`
- `docker logs zenfocus-gitea`
- `docker exec -it zenfocus-gitea /bin/bash
- `docker logs zenfocus-gitlab`
- `docker exec -it zenfocus-gitlab gitlab-ctl status`

## Diferenciais implementados

- Health checks em servicos
- Pipeline com testes reais
- Automacao de inicializacao
- Documentacao tecnica consolidada

## Conclusao

O projeto Zenfocus atende aos objetivos de um ambiente DevOps completo para uma aplicacao CRUD, cobrindo provisionamento local, DNS, certificados, GitLab, runner e pipeline CI/CD com deploy e validacoes.