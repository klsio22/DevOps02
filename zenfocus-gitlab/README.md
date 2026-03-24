Proxy e acesso via navegador
---------------------------

Adicionei um serviço `proxy` (nginx) que expõe as portas 80 e 443 no host e faz reverse-proxy para o container `gitlab` na rede Docker. Isso permite acessar:

 - http://gitlab.zenfocus.com (redireciona para HTTPS)
 - https://gitlab.zenfocus.com

Certifique-se de que o host resolva `gitlab.zenfocus.com`. Para testes locais, adicione no `/etc/hosts`:

```bash
sudo -- sh -c "echo '127.0.0.1 gitlab.zenfocus.com' >> /etc/hosts"
```

Ou consulte diretamente o DNS do container:

```bash
dig @127.0.0.1 -p 1053 gitlab.zenfocus.com A
```
Notas:
- O GitLab leva alguns minutos para inicializar na primeira execução.
- Se você usar o DNS interno, verifique conflitos de porta 53 no host.
- Esse setup é pensado para ambientes de laboratório e desenvolvimento.
# Zenfocus GitLab (Docker)

Este projeto cria uma instância local do GitLab usando Docker e um container DNS para resolver `gitlab.zenfocus.com` dentro da rede do Docker.

Estrutura do projeto:

```
zenfocus-gitlab/
├── docker-compose.yml
├── start-zenfocus.sh
├── scripts/
│   └── show-gitlab-credentials.sh
├── dns/
│   └── data/
│       ├── named.conf.local
│       └── db.zenfocus.com
└── gitlab/
    ├── config/
    ├── logs/
    ├── data/
    └── ssl/
    
```

Passos rápidos:

1. Ajuste o `/etc/hosts` (no host) para apontar `gitlab.zenfocus.com` para `127.0.0.1` durante testes locais (opcional):

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
