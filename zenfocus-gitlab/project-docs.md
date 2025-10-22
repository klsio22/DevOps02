
# Documentação rápida do projeto Zenfocus (acesso à app Pomodoro)

## Resumo do que foi feito

- Adicionado serviço `app` (PHP 8.2 + Apache) em `docker-compose.yml` com IP fixo 10.10.10.21 na rede `zenfocus-net`.
- Configurado `zenfocus-proxy` (Nginx) em `proxy/site.conf` para rotear `www.zenfocus.local` para `http://10.10.10.21:80`.
- Criado um CRUD mínimo em `app/` (arquivos `index.php`, `styles.css`, `data/tasks.json`) para testar a aplicação Pomodoro.
- Subidos os containers `dns`, `ca`, `gitlab`, `proxy` e `app` via `docker compose up -d`.

## Sintoma observado no browser

Ao abrir `http://www.zenfocus.local` o navegador mostrou: "Não é possível acessar esse site - Não foi possível encontrar o endereço DNS de www.zenfocus.local. DNS_PROBE_POSSIBLE".

Isso indica que o nome `www.zenfocus.local` não estava sendo resolvido pelo sistema operacional do host para `127.0.0.1` (ou para o DNS local que atende a zona).

## Diagnóstico realizado

1. Verifiquei que os containers necessários estavam em execução:

	- `zenfocus-dns` (Bind)
	- `zenfocus-gitlab` (GitLab)
	- `zenfocus-proxy` (Nginx)
	- `zenfocus-app` (PHP/Apache)

2. Testei o proxy internamente no host usando curl com header `Host` para simular o navegador:

	curl -H "Host: www.zenfocus.local" -i http://127.0.0.1/

	Resultado: HTTP/1.1 200 OK com o HTML da aplicação — o proxy está roteando corretamente para o container `app`.

3. Verifiquei o arquivo `/etc/hosts` no host (trecho relevante fornecido):

```
127.0.0.1 localhost
::1       localhost
127.0.0.1 gitlab.zenfocus.local
127.0.0.1 zenfocus.local
```

Observação: falta a entrada `www.zenfocus.local`. Por isso o navegador não resolveu o nome. O curl funcionou porque eu forçei o header `Host` e a conexão foi feita para `127.0.0.1` diretamente.

## Correção recomendada (adicionar host local)

1. Edite `/etc/hosts` como root e adicione a linha para `www.zenfocus.local`:

```bash
sudo -- sh -c "echo '127.0.0.1 www.zenfocus.local' >> /etc/hosts"
```

2. (Opcional) Se você quer que `zenfocus.local` sem `www` também funcione, pode adicionar:

```bash
sudo -- sh -c "echo '127.0.0.1 zenfocus.local' >> /etc/hosts"
```

3. Limpar cache DNS do sistema (varia por distribuição). Exemplos:

- systemd-resolved:

```bash
sudo systemd-resolve --flush-caches
```

- nscd:

```bash
sudo service nscd restart
```

4. Limpar cache do navegador (Chrome/Brave): acesse `chrome://net-internals/#dns` e clique em "Clear host cache"; em seguida, na aba `sockets`, clique em "Flush socket pools".

## Testes pós-correção

1. Teste rápido com curl:

```bash
curl -H "Host: www.zenfocus.local" -i http://127.0.0.1/
```

2. Teste de resolução pelo host:

```bash
ping -c1 www.zenfocus.local
dig @127.0.0.1 -p 1053 www.zenfocus.local A    # se quiser testar o DNS container
```

3. Abrir no navegador:

 - http://www.zenfocus.local

Se tudo estiver correto, a página do app (Zenfocus - Pomodoro) deve aparecer.

## Observações sobre HTTPS

- Atualmente o proxy foi configurado para servir `www.zenfocus.local` via HTTP para simplificar testes (evitando erro de certificado). Se quiser HTTPS, coloque os certificados em `./gitlab/ssl/` (ou configure a CA para emitir `www.zenfocus.local`) e eu ajusto o bloco SSL em `proxy/site.conf`.
- Se preferir que o proxy valide certificados autoassinados gerados pela CA do projeto, copie `zenfocus-ca.crt.pem` para o proxy e habilite `proxy_ssl_trusted_certificate` e `proxy_ssl_verify on`.

## Próximos passos opcionais (posso executar)

- Gerar certificado para `www.zenfocus.local` com a CA interna e habilitar HTTPS no proxy.
- Melhorar o CRUD (editar tarefas, temporizador JS para Pomodoro real).
- Publicar a app em um repositório GitLab local e criar um pipeline CI simples.

---

Arquivo gerado/atualizado automaticamente: `project-docs.md` (este documento).

## Acesso ao GitLab local

Usuário administrativo padrão: `root`

Senha inicial gerada durante a instalação (se disponível):

- A senha inicial pode ser encontrada em `gitlab/config/initial_root_password` no host (se o arquivo existir) ou dentro do container em `/etc/gitlab/initial_root_password`.
- No ambiente atual, a senha inicial encontrada dentro do container foi: `+iTPqn0PrwuCX7d2QmUvvSKXXuQjZgE44mm/1wIVWxI=` (válida somente se você não a alterou depois da primeira inicialização).

Como resetar a senha root (se a senha acima não funcionar):

1) Reset rápido via rake (interativo):

```bash
docker exec -it zenfocus-gitlab gitlab-rake "gitlab:password:reset[root]"
```

2) Reset definitivo via runner (define senha direta):

```bash
docker exec -it zenfocus-gitlab gitlab-rails runner "user = User.find_by_username('root'); user.password = 'NovaSenhaSegura123'; user.password_confirmation = 'NovaSenhaSegura123'; user.save!"
```

Substitua `NovaSenhaSegura123` pela senha desejada.

URL de acesso web (via proxy):

- http://gitlab.zenfocus.local  (ou https://gitlab.zenfocus.local se configurar TLS no proxy)

Acesso SSH para Git (porta mapeada no host):

- Host: gitlab.zenfocus.local
- Porta SSH no host: 2222 (mapeada para 22 do container)
- Exemplo de clone:

```bash
git clone ssh://git@localhost:2222/root/nome-do-projeto.git
```

Dica: se usar o DNS local (`www.zenfocus.local` ou `gitlab.zenfocus.local`) certifique-se de adicionar entradas em `/etc/hosts` ou resolver via o DNS container.

