
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
 # Documentação do projeto Zenfocus — mudanças aplicadas e estado atual

 Este documento resume tudo que foi feito até agora no repositório, quais arquivos foram alterados, quais comandos foram executados durante a sessão e os próximos passos necessários para completar a migração de domínio e TLS (de .local → .com).

 ## Resumo de alto nível

 - Migramos o domínio usado pelo ambiente de `zenfocus.local` para `zenfocus.com` (hostnames, certificados e DNS).
 - Atualizamos compose, scripts de geração de certificados, configuração do proxy (Nginx) e arquivos de zona DNS.
 - Geramos (ou preparamos para gerar) uma CA local e certificados para `gitlab.zenfocus.com` e `www.zenfocus.com` via o container `ca`.
 - Atualizamos documentação e scripts auxiliares para usar `.com`.

 ## Alterações principais (arquivos e propósito)

 - `docker-compose.yml`
	 - hostname do container `gitlab` atualizado para `gitlab.zenfocus.com`.
	 - `GITLAB_OMNIBUS_CONFIG` atualizado com `external_url 'https://gitlab.zenfocus.com'` e caminhos de SSL `/etc/gitlab/ssl/gitlab.zenfocus.com.crt`/`.key`.

 - `ca/generate-certs.sh` (container CA)
	 - Script ajustado para gerar CA (`zenfocus-ca.*`) e certificados para `gitlab.zenfocus.com` com SANs apropriados (localhost, 127.0.0.1).

 - `proxy/site.conf`
	 - Server blocks atualizados para `gitlab.zenfocus.com` e `www.zenfocus.com` e apontam os certificados para `/etc/nginx/ssl/gitlab.zenfocus.com.crt` e `.key`.
	 - Proxy para GitLab configurado para `https://10.10.10.20:443` com `proxy_ssl_verify off` (para permitir certificados autoassinados durante testes).

 - `dns/data/named.conf.local` e `dns/data/db.zenfocus.com` (zone)
	 - Zona renomeada para `zenfocus.com` e criado/atualizado `db.zenfocus.com` com A records para `ns`, `gitlab` e `www` apontando aos IPs usados na rede Docker (`10.10.10.10`, `10.10.10.20`, `10.10.10.21`).

 - `README.md`, `ca/README.md`, `app/README.md`, `project-docs.md`
	 - Documentação e exemplos atualizados para usar `.com` (hosts, dig, instruções de instalação da CA, etc.).

 - `start-zenfocus.sh`
	 - Script de inicialização atualizado: valida Docker, cria diretórios, cria rede `zenfocus-net` se necessário, sobe compose e tenta criar automaticamente um usuário `dev1`.
	 - O e-mail padrão do usuário automático foi atualizado para `dev1@gitlab.zenfocus.com`.

 ## Comandos executados / tentativas feitas nesta sessão

 - Tentei executar `docker-compose down` e outras ações com `docker-compose` para parar e recriar o ambiente aqui, mas o ambiente onde estou executando não tem acesso funcional ao Docker daemon (erro: `Not supported URL scheme http+docker`). Resultado: não foi possível rodar containers a partir daqui.

 - Localmente (controle do repositório), apliquei várias edições de arquivos (veja acima). Essas mudanças estão no repositório e prontas para serem usadas quando você executar o compose no seu host com Docker.

 ## Estado atual esperado no host (após rodar os passos locais)

 - `gitlab/ssl/` deverá conter:
	 - `zenfocus-ca.crt.pem` (CA pública)
	 - `zenfocus-ca.key.pem` (CA privada)
	 - `gitlab.zenfocus.com.crt` e `gitlab.zenfocus.com.key`

 - O `proxy` (nginx) deve usar o par `gitlab.zenfocus.com.crt`/`.key` e reverse-proxy para `10.10.10.20:443`.
 - O GitLab Omnibus irá usar `/etc/gitlab/ssl/gitlab.zenfocus.com.crt` quando estiverem montados e, após `gitlab-ctl reconfigure`, expor corretamente HTTPS internamente.

 ## Passo a passo recomendado para completar a migração (executar localmente)

 IMPORTANTE: executar estes comandos no host com Docker. Faça backup em vez de apagar a pasta `gitlab/` se quiser preservar dados.

 1) Parar os serviços e fazer backup da pasta `gitlab` (recomendado):

 ```bash
 cd /home/klsio27/Documentos/www/DevOps02/zenfocus-gitlab
 docker-compose down
 mv gitlab gitlab.bak    # mantém um backup seguro
 mkdir -p gitlab/config gitlab/logs gitlab/data gitlab/ssl
 ```

 2) Gerar certificados com o container CA (vai escrever em `./gitlab/ssl`):

 ```bash
 docker-compose build ca
 docker-compose run --rm ca
 ls -l gitlab/ssl
 ```

 3) Subir os serviços (ou apenas gitlab/proxy/dns):

 ```bash
 docker-compose up -d dns gitlab proxy app
 ```

 4) Se o GitLab não configurar automaticamente o Nginx interno com os novos certificados, forçar reconfigure:

 ```bash
 docker exec -it zenfocus-gitlab gitlab-ctl reconfigure
 ```

 5) Verificações rápidas:

 ```bash
 docker-compose ps
 ls -l gitlab/ssl
 docker logs --tail 200 zenfocus-proxy
 docker logs --tail 200 zenfocus-gitlab
 curl -vk https://gitlab.zenfocus.com --resolve gitlab.zenfocus.com:443:10.10.10.20
 ```

 6) Instalar a CA no host (para confiar no certificado gerado):

 ```bash
 sudo cp gitlab/ssl/zenfocus-ca.crt.pem /usr/local/share/ca-certificates/zenfocus-ca.crt
 sudo update-ca-certificates
 ```

 ## Diagnóstico de 502 Bad Gateway (proxy)

 Se você está vendo `502 Bad Gateway` no `zenfocus-proxy`, os motivos mais prováveis são:

 - GitLab container não está rodando ou está em crash.
 - GitLab não está escutando em 443 (o proxy aponta para `https://10.10.10.20:443`).
 - Falta de certificados montados em `gitlab/ssl` → o nginx interno do GitLab pode não ter iniciado corretamente.

 Verifique (local):

 ```bash
 docker-compose ps
 docker logs zenfocus-proxy
 docker logs zenfocus-gitlab
 docker exec -it zenfocus-gitlab gitlab-ctl status
 docker exec -it zenfocus-gitlab ss -ltnp || docker exec -it zenfocus-gitlab netstat -ltnp
 ```

 Se preferir, eu crio um script `scripts/zenfocus-debug.sh` que executa essas checagens automaticamente e imprime um diagnóstico; posso adicionar ao repo para você rodar localmente.

 ## Mudanças na automação / usuário dev1

 - O `start-zenfocus.sh` foi mantido e ajustado para usar o domínio `.com`. Ele cria a rede `zenfocus-net`, sobe o compose e tenta criar automaticamente o usuário `dev1` com e-mail `dev1@gitlab.zenfocus.com`.
 - Nota: a criação automática de usuário depende do GitLab estar totalmente pronto — o script aguarda e executa um runner Rails para criar o usuário.

 ## Pendências e próximos passos (prioridade)

 1. No host, gerar os certificados usando o container `ca` (passo 2 acima) — essencial.
 2. Subir containers e rodar `gitlab-ctl reconfigure` dentro do container GitLab para atualizar arquivos gerados (`gitlab/data/..`) — não edite esses arquivos manualmente.
 3. Verificar e corrigir qualquer referência remanescente a `.local` em scripts auxiliares e docs (eu já atualizei a maior parte, mas faça uma busca rápida: `git grep zenfocus.local`).
 4. Instalar a CA no sistema / navegadores para eliminar avisos de TLS.

 ## Notas finais

 - Eu atualizei os arquivos de configuração e documentação no repositório; porém não pude executar os comandos Docker aqui por falta de acesso ao daemon — você precisa rodar os passos de runtime no seu host com Docker instalado.
 - Se quiser, eu adiciono o script de debug mencionado e um script seguro `scripts/recreate-certs.sh` que faz backup automático (mv), roda o container CA e sobe os serviços — você só precisa executá-lo localmente.

 Se quiser que eu gere esses scripts agora (debug + recreate-certs) e os adicione ao repositório, diga que eu crio e aplico o patch. Se preferir que eu apenas te guie passo-a-passo, me diga qual etapa quer executar agora e eu forneço os comandos e o que olhar nas saídas.


