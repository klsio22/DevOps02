# DevOps02 - Trabalho Academico de Pipeline Web

Este repositorio contem um **trabalho academico** da disciplina de DevOps (UTFPR), focado em montar um fluxo completo de **construcao, teste e implantacao** de uma aplicacao web CRUD.

Os objetivos e requisitos deste trabalho estao baseados no enunciado oficial em [docs/objectives-for-work.md](docs/objectives-for-work.md).

## Objetivo do Trabalho

Demonstrar, na pratica, a capacidade de:

- personalizar uma aplicacao CRUD;
- organizar infraestrutura de apoio (DNS, certificados, servicos de Git, servidor web);
- construir uma esteira CI/CD com etapas de build, teste e deploy;
- apresentar evidencias de funcionamento em ambiente de demonstracao.

## Visao Geral do Projeto

O workspace foi dividido em dois blocos principais:

### 1) Aplicacao CRUD - `zenfocus-app/`

Aplicacao web em PHP puro (sem framework), com frontend HTML/CSS/JS e banco MariaDB.

- Empresa ficticia: **Zenfocus**
- Produto: **PulseFocus Tasks / Pomofocus**
- Execucao local (sem dominio): `http://localhost:8081/index.php`
- Regra de negocio: CRUD com **uma unica tabela** (`tasks`)

Componentes principais:

- `public/`: entrada web da aplicacao
- `app/actions/`: logica CRUD
- `app/core/`: configuracoes e conexao com banco
- `database/schema.sql`: estrutura inicial do banco

### 2) Ambiente DevOps - `zenfocus-gitea/`

Stack de infraestrutura para hospedar servicos de apoio ao ciclo DevOps local.

- Servico Git: **Gitea**
- DNS local: **BIND9**
- Certificacao local: **CA propria**
- Reverse proxy: **Nginx**
- Integracao com aplicacao web e banco de dados

Componentes principais:

- `docker-compose.yml`: orquestracao dos servicos
- `dns/`: zona e configuracoes DNS
- `ca/`: geracao de certificados
- `proxy/`: configuracoes HTTPS/reverse proxy
- `scripts/`: utilitarios de inicializacao e manutencao

## Relacao com o Enunciado

Este repositorio foi organizado para atender os requisitos do enunciado, com foco em:

- aplicacao CRUD com escopo controlado;
- topologia de servicos para DevOps;
- preparacao de ambiente para pipeline;
- demonstracao de build, teste e deploy.

Para os detalhes completos e criterios de avaliacao, consulte diretamente:

- [docs/objectives-for-work.md](docs/objectives-for-work.md)

## Como Navegar no Workspace

- Projeto da aplicacao: [zenfocus-app/](zenfocus-app/)
- Projeto da infraestrutura: [zenfocus-gitea/](zenfocus-gitea/)
- Enunciado e objetivos: [docs/](docs/)

## Observacao

Este material tem finalidade **academica** e foi desenvolvido para a disciplina, seguindo os requisitos definidos pelo professor.
