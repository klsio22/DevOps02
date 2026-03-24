Container CA simples

Este container gera a CA local e o certificado do GitLab.

## Uso no Docker

- O `docker-compose.yml` monta `./gitlab/ssl` em `/certs`.
- Ao subir, o container gera:
	- `zenfocus-ca.crt.pem`
	- `zenfocus-ca.key.pem`
	- `gitlab.zenfocus.com.crt`
	- `gitlab.zenfocus.com.key`
- O container encerra após gerar os arquivos.

## Uso no host

Se você executar `./generate-certs.sh` diretamente dentro da pasta `ca/`, o script tenta usar `/certs` primeiro. Se não tiver permissão, ele faz fallback automático para:

- `../gitlab/ssl`

Por isso, rode o script a partir da raiz do projeto ou da pasta `ca/`, mas sempre garantindo que o destino real seja o diretório do projeto:

```bash
cd /home/knlinux/Documents/www/utfpr/DevOps02/zenfocus-gitlab/ca
./generate-certs.sh
```

## Permissões recomendadas

Se os arquivos ficarem com dono `root`, ajuste no host assim:

```bash
cd /home/knlinux/Documents/www/utfpr/DevOps02/zenfocus-gitlab
sudo chown -R "$USER:$USER" gitlab/ssl
chmod 755 gitlab/ssl
chmod 600 gitlab/ssl/*.key
chmod 644 gitlab/ssl/*.crt gitlab/ssl/*.csr 2>/dev/null || true
```

## Validação dos certificados

O script também valida se a cadeia está correta antes de parar:

```bash
openssl verify -CAfile gitlab/ssl/zenfocus-ca.crt.pem gitlab/ssl/gitlab.zenfocus.com.crt
```

Se o resultado for `OK`, a CA e o certificado estão válidos.
