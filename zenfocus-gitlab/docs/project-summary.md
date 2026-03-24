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

- Docker Compose com servicos de DNS, CA, GitLab, proxy e app
- DNS com BIND9 para a zona zenfocus.com
- Registros para ns, gitlab e www na rede docker

### 3) Certificados e TLS

- CA local dedicada ao projeto
- Certificados para:
  - gitlab.zenfocus.com
  - www.zenfocus.com

### 4) GitLab e CI/CD

- GitLab CE com runner Docker
- Pipeline com estagios de build, test, deploy e notify
- Testes automatizados e health checks

## Resumo tecnico das mudancas aplicadas

- `docker-compose.yml`
  - Hostname do GitLab atualizado para gitlab.zenfocus.com
  - `external_url` e caminhos SSL ajustados para `.com`

- `ca/generate-certs.sh`
  - Geracao de CA local e certificado para gitlab.zenfocus.com

- `proxy/site.conf`
  - Server blocks para gitlab.zenfocus.com e www.zenfocus.com
  - Proxy do GitLab para `https://10.10.10.20:443`

- `dns/data/named.conf.local` e `dns/data/db.zenfocus.com`
  - Zona configurada para zenfocus.com
  - A records para ns, gitlab e www

- `start-zenfocus.sh`
  - Fluxo de inicializacao alinhado ao dominio `.com`
  - Inicializacao dos servicos do GitLab sem bootstrap de usuario
  - Chamada do script `show-gitlab-credentials.sh` para exibir credenciais iniciais do root

- `show-gitlab-credentials.sh`
  - Script dedicado para consultar e exibir a senha inicial do usuario `root`
  - Pode ser executado de forma independente apos o ambiente subir

## Diagnostico realizado (acesso web)

### Sintoma

Ao abrir `http://www.zenfocus.com`, ocorreu erro de resolucao DNS no navegador.

### Causa

O host local nao tinha o nome esperado no `/etc/hosts`, entao o navegador nao resolvia o dominio para o proxy local.

### Validacao feita

- Teste interno no proxy com header Host retornou HTTP 200
- Servicos principais estavam em execucao: dns, gitlab, proxy e app

### Correcao recomendada

Adicionar entradas de hosts locais quando necessario, por exemplo:

```bash
sudo sh -c "echo '127.0.0.1 www.zenfocus.com' >> /etc/hosts"
sudo sh -c "echo '127.0.0.1 gitlab.zenfocus.com' >> /etc/hosts"
```

Depois, limpar cache DNS do sistema e do navegador.

## Passo a passo para concluir a migracao no host com Docker

1. Parar servicos e preparar diretorios persistentes do GitLab.
2. Gerar certificados com o servico `ca`.
3. Subir `dns`, `gitlab`, `proxy` e `app`.
4. Exibir credenciais iniciais do root com `./scripts/show-gitlab-credentials.sh`.
5. Rodar `gitlab-ctl reconfigure` no container GitLab, se necessario.
6. Validar logs, portas e conectividade HTTPS.
7. Instalar a CA local no sistema para remover alertas de certificado.

## Diagnostico rapido para erro 502 no proxy

Principais causas:

- GitLab indisponivel ou em crash
- GitLab sem listener em 443
- Certificados ausentes/invalidos no volume `gitlab/ssl`

Checagens uteis:

- `docker-compose ps`
- `docker logs zenfocus-proxy`
- `docker logs zenfocus-gitlab`
- `docker exec -it zenfocus-gitlab gitlab-ctl status`

## Diferenciais implementados

- Health checks em servicos
- Pipeline com testes reais
- Automacao de inicializacao
- Documentacao tecnica consolidada

## Conclusao

O projeto Zenfocus atende aos objetivos de um ambiente DevOps completo para uma aplicacao CRUD, cobrindo provisionamento local, DNS, certificados, GitLab, runner e pipeline CI/CD com deploy e validacoes.