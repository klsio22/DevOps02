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

3. Recuperar senha root (dentro do container GitLab):

Existem duas formas comuns de recuperar ou redefinir a senha `root` dentro do container GitLab.

- Interativa (prompt):

```bash
# Acesse o container (shell interativo)
docker exec -it zenfocus-gitlab bash
# Reset de senha (segue prompts interativos)
gitlab-rake "gitlab:password:reset[root]"
```

- Não interativa (definir uma nova senha diretamente):

> Use este método se quiser automatizar ou definir uma senha imediata sem prompts. Substitua
> `NovaSenhaSegura123!` por uma senha forte gerada por você.

```bash
# Executa um comando Ruby dentro do container que altera a senha do usuário root
docker exec -it zenfocus-gitlab \
    gitlab-rails runner "user = User.find_by_username('root'); user.password = 'NovaSenhaSegura123!'; user.password_confirmation = 'NovaSenhaSegura123!'; user.save!; puts 'Senha root alterada.'"
```

Observação: após alterar a senha, faça login via a interface web do GitLab ou via SSH/git conforme necessário. Se preferir, gere uma senha segura com um gerador (pwgen, openssl, etc.) e cole-a no comando acima.

4. Gerenciar usuários do GitLab:

Scripts úteis para gerenciar usuários foram criados na pasta `scripts/`:

- **Criar/Redefinir usuário**:

```bash
./scripts/criar-usuario-gitlab.sh <username> <email> <nome> <senha>

# Exemplo:
./scripts/criar-usuario-gitlab.sh dev1 dev1@zenfocus.com 'Developer 1' 'SenhaSeg@2024!'
```

- **Listar todos os usuários**:

```bash
./scripts/listar-usuarios-gitlab.sh
```

**Usuários existentes atualmente**:

- `root` - `admin@gitlab.zenfocus.com` (Admin)
- `dev1` - `dev1@zenfocus.com` (Senha: DevUser2024!Pass@)
- `dev4` - `dev4@gitlab.zenfocus.com` (Senha: DevUser2024!Pass@)

Para fazer login:

1. Acesse: `https://gitlab.zenfocus.com`
2. Use o email do usuário
3. Use a senha definida

4. Habilitar SSL (opcional):

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
