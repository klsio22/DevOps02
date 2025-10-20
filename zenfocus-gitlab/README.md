# Zenfocus GitLab (Docker)

Este projeto cria uma instância local do GitLab usando Docker e um container DNS para resolver `gitlab.zenfocus.local` dentro da rede do Docker.

Estrutura do projeto:

```
zenfocus-gitlab/
├── docker-compose.yml
├── start-zenfocus.sh
├── dns/
│   └── data/
│       ├── named.conf.local
│       └── db.zenfocus.local
└── gitlab/
    ├── config/
    ├── logs/
    ├── data/
    └── ssl/
```

Passos rápidos:

1. Ajuste o `/etc/hosts` (no host) para apontar `gitlab.zenfocus.local` para `127.0.0.1` durante testes locais (opcional):

```bash
sudo -- sh -c "echo '127.0.0.1 gitlab.zenfocus.local' >> /etc/hosts"
```

2. Tornar o script executável e iniciar:

```bash
chmod +x start-zenfocus.sh
./start-zenfocus.sh
```

3. Recuperar senha root (dentro do container GitLab):

```bash
# Acesse o container
docker exec -it zenfocus-gitlab bash
# Reset de senha
gitlab-rake "gitlab:password:reset[root]"
```

4. Habilitar SSL (opcional):

- Coloque `gitlab.zenfocus.local.crt` e `.key` em `gitlab/ssl/` e ajuste `docker-compose.yml` como descrito no guia.

Gerar certificados com o serviço `ca` (recomendado):

```bash
# Constrói e roda o container de CA que gera os certificados em ./gitlab/ssl
docker-compose build ca
docker-compose run --rm ca
```

Isso irá criar em `gitlab/ssl/` os arquivos:

- `zenfocus-ca.crt.pem` (CA pública)
- `zenfocus-ca.key.pem` (CA privada)
- `gitlab.zenfocus.local.crt` (certificado do GitLab assinado pela CA)
- `gitlab.zenfocus.local.key` (chave privada do GitLab)

Após isso, reinicie o GitLab:

```bash
docker-compose up -d gitlab
```

Comandos úteis:

```bash
# Parar serviços
docker-compose down
# Reiniciar GitLab
docker-compose restart gitlab
# Backup dos dados
docker-compose exec gitlab gitlab-backup create
# Atualizar imagens e reiniciar
docker-compose pull
docker-compose up -d
```

Notas:
- O GitLab leva alguns minutos para inicializar na primeira execução.
- Se você usar o DNS interno, verifique conflitos de porta 53 no host.
- Esse setup é pensado para ambientes de laboratório e desenvolvimento.

DNS via porta alternativa
------------------------

Para evitar conflitos com serviços do host (ex.: systemd-resolved), o DNS do container está mapeado para a porta 1053 do host. Para consultar diretamente use:

```bash
dig @127.0.0.1 -p 1053 gitlab.zenfocus.local A
```

Se quiser que o sistema use essa resolução automaticamente, você pode configurar temporariamente o gerenciador de DNS do seu host para encaminhar consultas para 127.0.0.1:1053 ou ajustar `/etc/resolv.conf` (aviso: essas mudanças podem impactar o sistema).
