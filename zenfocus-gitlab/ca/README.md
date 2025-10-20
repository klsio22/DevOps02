Container CA simples

Uso:

- O container é construído pelo docker-compose e monta `./gitlab/ssl` em `/certs`.
- Ao subir, o container gera uma CA (zenfocus-ca.*) e um certificado para `gitlab.zenfocus.local`.
- O container sai após gerar os arquivos (restart: no na composição).
