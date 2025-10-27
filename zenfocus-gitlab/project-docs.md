
# Documentação rápida do projeto Zenfocus (acesso à app Pomodoro)

## Resumo do que foi feito

- Adicionado serviço `app` (PHP 8.2 + Apache) em `docker-compose.yml` com IP fixo 10.10.10.21 na rede `zenfocus-net`.
- Configurado `zenfocus-proxy` (Nginx) em `proxy/site.conf` para rotear `www.zenfocus.com` para `http://10.10.10.21:80`.
- Criado um CRUD mínimo em `app/` (arquivos `index.php`, `styles.css`, `data/tasks.json`) para testar a aplicação Pomodoro.
- Subidos os containers `dns`, `ca`, `gitlab`, `proxy` e `app` via `docker compose up -d`.

## Sintoma observado no browser

Ao abrir `http://www.zenfocus.com` o navegador mostrou: "Não é possível acessar esse site - Não foi possível encontrar o endereço DNS de www.zenfocus.com. DNS_PROBE_POSSIBLE".

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

Observação: falta a entrada `www.zenfocus.com`. Por isso o navegador não resolveu o nome. O curl funcionou porque eu forçei o header `Host` e a conexão foi feita para `127.0.0.1` diretamente.

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


```bash
sudo systemd-resolve --flush-caches
```


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

### Usuário de desenvolvimento automático

Ao iniciar o ambiente com o script `start-zenfocus.sh`, o processo tentará criar automaticamente um usuário de teste chamado `dev1` assim que o GitLab estiver pronto.

Padrões criados pelo script:

- Usuário: `dev1`
- E-mail: `dev1@zenfocus.local`
- Senha: `Dev1Passw0rd!`

Observações:

- O script verifica se o GitLab está pronto e só cria o usuário se ele não existir.
- Você pode alterar as credenciais editando `start-zenfocus.sh` (variáveis `DEV_USER`, `DEV_EMAIL`, `DEV_PASS`) antes de iniciar.
- Para segurança, altere a senha do `dev1` após o primeiro login ou crie um usuário com credenciais diferentes para uso real.

Comandos úteis para gerenciar o usuário (dentro do container GitLab):

```bash
# listar usuários com Rails runner
docker exec -it zenfocus-gitlab gitlab-rails runner "puts User.all.map{|u| [u.id,u.username,u.email] }.inspect"

# resetar senha de dev1
docker exec -it zenfocus-gitlab gitlab-rails runner "u = User.find_by_username('dev1'); u.password = 'NovaSenha123!'; u.password_confirmation = 'NovaSenha123!'; u.save!"

# remover usuário dev1
docker exec -it zenfocus-gitlab gitlab-rails runner "u = User.find_by_username('dev1'); u.destroy if u"
```


## TLS / CA — tornar o certificado do GitLab confiável localmente

Se ao abrir `https://gitlab.zenfocus.local` o navegador mostrar "Não seguro", siga este passo-a-passo. Essas instruções cobrem criação da cadeia completa (fullchain), instalação da CA no sistema e importação no navegador.

1) Garantir que o servidor entregue a cadeia completa (fullchain)

```bash
cd /home/$(whoami)/Documentos/www/DevOps02/zenfocus-gitlab/gitlab/ssl

# backup
sudo cp gitlab.zenfocus.local.crt gitlab.zenfocus.local.crt.bak

# criar fullchain (certificado do servidor seguido pelo CA)
sudo bash -c 'cat gitlab.zenfocus.local.crt zenfocus-ca.crt.pem > gitlab.zenfocus.local.fullchain.crt'

# substituir o arquivo usado pelo proxy/GitLab
sudo mv -f gitlab.zenfocus.local.fullchain.crt gitlab.zenfocus.local.crt
sudo chown root:root gitlab.zenfocus.local.crt
sudo chmod 644 gitlab.zenfocus.local.crt

# reiniciar proxy (e GitLab se necessário)
docker restart zenfocus-proxy
# se você quiser que o GitLab reconfigure internamente
docker exec -it zenfocus-gitlab gitlab-ctl reconfigure || true
```

2) Instalar/registrar a CA no sistema (Ubuntu / Pop!_OS)

```bash
# copiar a CA para o diretório de CAs locais
sudo cp /home/$(whoami)/Documentos/www/DevOps02/zenfocus-gitlab/gitlab/ssl/zenfocus-ca.crt.pem /usr/local/share/ca-certificates/zenfocus-ca.crt

# atualizar o store de CAs
sudo update-ca-certificates
```

3) Verificar TLS com OpenSSL (rápido teste)

```bash
openssl s_client -connect 127.0.0.1:443 -servername gitlab.zenfocus.local -CAfile /home/$(whoami)/Documentos/www/DevOps02/zenfocus-gitlab/gitlab/ssl/zenfocus-ca.crt.pem </dev/null
# procure por: Verify return code: 0 (ok)
```

4) Reinicie o navegador e limpe caches

```bash
# garantir que o navegador foi fechado
pkill -f brave || true
pkill -f chrome || true

# (abra o navegador manualmente e limpe o cache TLS/host) ou:
# Chrome/Brave -> chrome://net-internals/#dns  -> Clear host cache
# Chrome/Brave -> chrome://net-internals/#sockets -> Flush socket pools
```

5) Importar a CA no perfil do Brave/Chromium (se o navegador não usar o store do sistema)

```bash
# instalar utilitário NSS
sudo apt update && sudo apt install -y libnss3-tools

# exemplo para Brave; ajuste o caminho do PROFILE se usar Chromium/Chrome
PROFILE="$HOME/.config/BraveSoftware/Brave-Browser/Default"
certutil -d sql:$PROFILE -A -n "Zenfocus CA" -t "CT,C,C" -i /home/$(whoami)/Documentos/www/DevOps02/zenfocus-gitlab/gitlab/ssl/zenfocus-ca.crt.pem

# reinicie o navegador
```

6) Importar a CA no Firefox (opcional)

Via GUI: Preferências → Privacidade & Segurança → Ver certificados → Autoridades → Importar → selecione `zenfocus-ca.crt.pem` e marque "Confiar nesta autoridade para identificar sites".

Via linha (com libnss3-tools):

```bash
PROFILE_FF=$(ls -d $HOME/.mozilla/firefox/*.default-release | head -n1)
certutil -d sql:$PROFILE_FF -A -n "Zenfocus CA" -t "CT,C,C" -i /home/$(whoami)/Documentos/www/DevOps02/zenfocus-gitlab/gitlab/ssl/zenfocus-ca.crt.pem
```

7) Troubleshooting rápido

- Se o OpenSSL mostra `Verify return code: 0 (ok)` mas o navegador ainda marca inseguro:
	- Verifique mixed content no DevTools Console (recursos HTTP bloqueados em página HTTPS).
	- Confirme que o navegador foi reiniciado após importação da CA.
	- Confirme que importou a CA no perfil correto do navegador (pasta Default ou o profile que você realmente usa).

- Para verificar certs no perfil (se `certutil` instalado):

```bash
certutil -L -d sql:$PROFILE
```

8) Checklist rápido (resumo)

- [ ] Criar fullchain em `gitlab/ssl` e reiniciar `zenfocus-proxy`
- [ ] Copiar `zenfocus-ca.crt.pem` para `/usr/local/share/ca-certificates/` e `update-ca-certificates`
- [ ] Reiniciar navegador
- [ ] Se necessário, importar CA no perfil do navegador com `certutil`

Se quiser, eu executo os passos 1, 2 e 5 aqui (posso precisar de `sudo` para copiar/atualizar CAs e instalar `libnss3-tools`). Diga se quer que eu proceda e eu seguirei adiante.

