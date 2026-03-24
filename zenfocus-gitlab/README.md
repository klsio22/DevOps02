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

4. (Opcional) Redefinir senha root manualmente:

- Interativa (prompt):

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
