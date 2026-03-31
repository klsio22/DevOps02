# Documentação de Permissões para a Pasta `gitea/ssl`

Este documento descreve como as permissões devem ser configuradas para que o script `ca/generate-certs.sh` (e o container `ca`) consigam gravar os certificados TLS em `gitea/ssl/`.  

---  

## 1. Estrutura esperada

```
gitea/
└─ ssl/
   ├─ ca.crt
   ├─ ca.key
   ├─ ca.srl
   ├─ gitea.zenfocus.com.crt
   ├─ gitea.zenfocus.com.key
   └─ gitea.zenfocus.com.csr
```

- **Arquivos de certificado** (`*.crt`) – leitura pública, escrita apenas pelo dono.  
- **Arquivos de chave privada** (`*.key`) – devem ser **600** (somente dono pode ler/gravá‑la).  
- **Arquivos temporários** (`*.csr`, `ca.srl`) – podem ser 644 ou 600, mas normalmente são removidos após a geração.

## 2. Configuração recomendada de permissões

```bash
# 1) Garantir que o diretório existe
mkdir -p gitea/ssl

# 2) Definir proprietário para o usuário atual (substitua $USER se necessário)
sudo chown -R "$(id -u):$(id -g)" gitea/ssl

# 3) Aplicar permissões típicas
chmod 755 gitea/ssl                 # diretório – permite listagem
chmod 644 gitea/ssl/*.crt           # certificados – leitura pública
chmod 600 gitea/ssl/*.key           # chaves privadas – acesso restrito
chmod 644 gitea/ssl/*.csr gitea/ssl/ca.srl  # arquivos temporários (opcional)
```

> **Por que `sudo`?**  
> Se o diretório foi criado por um container rodado como `root` (ex.: `docker compose up --build ca`), ele ficará com propriedade `root:root`. O comando acima corrige isso para o seu usuário atual, permitindo que o script seja executado sem precisar de `sudo` a cada chamada.

## 3. Como o script lida com permissões

O script `ca/generate-certs.sh` contém lógica de **auto‑correção**:

1. **Tenta escrever em `${CA_DIR}`** (por padrão `../gitea/ssl`).  
2. Se a escrita falhar, ele exibe um aviso e **tenta ajustar a propriedade**:
   ```bash
   sudo chown -R "$(id -u):$(id -g)" "${CA_DIR}"
   ```
3. Se o `sudo` falhar (por exemplo, falta de permissão de sudo), o script aborta com a mensagem:
   ```
   Erro: não foi possível ajustar a propriedade. Execute o script com sudo ou ajuste manualmente.
   ```

> **Dica:** Caso queira evitar a chamada a `sudo` dentro do script, ajuste as permissões **antes** de executá‑lo (com o passo 2 acima).

## 4. Opção `--force` (ou `-f`)

```bash
./ca/generate-certs.sh --force   # limpa certificados antigos e gera novos
./ca/generate-certs.sh -f        # forma abreviada
```

- O flag remove todos os arquivos `*.crt`, `*.key`, `*.csr` e `ca.srl` dentro de `${CA_DIR}` antes de iniciar a geração.  
- Útil quando você deseja **renovar** um certificado ou quando suspeita que algum arquivo ficou corrompido.

## 5. Execução dentro de container (`docker compose`)

Se preferir não mexer nas permissões do host, basta usar o container dedicado:

```bash
# Na raiz do projeto
docker compose up --build ca
```

- O container monta `./gitea/ssl` em `/certs` (configurado no `docker-compose.yml`).  
- Ele gera os certificados com a propriedade correta (uid/gid do container) e os deixa prontos para serem consumidos pelos outros serviços (`proxy`, `gitea`, etc.).  
- Ao terminar, o container para e o diretório `gitea/ssl` já contém os arquivos gerados.

## 6. Validação pós‑geração

Depois de gerar os certificados, verifique se a cadeia está correta:

```bash
openssl verify -CAfile gitea/ssl/ca.crt gitea/ssl/gitea.zenfocus.com.crt
# → deve retornar "OK"
```

Se o comando imprimir `OK`, a CA e o certificado estão válidos e podem ser usados pelo Nginx ou pelo GitLab.

---  

## Resumo rápido (comandos únicos)

```bash
# 1) Ajustar permissões (executar uma única vez)
sudo chown -R "$(id -u):$(id -g)" gitea/ssl
chmod 755 gitea/ssl
chmod 644 gitea/ssl/*.crt
chmod 600 gitea/ssl/*.key

# 2) Gerar certificados normalmente
./ca/generate-certs.sh

# 3) (Opcional) Forçar nova geração
./ca/generate-certs.sh --force
```

Com essas etapas a pasta `gitea/ssl` ficará pronta para ser consumida pelos serviços **proxy**, **gitea** e **gitlab** do seu stack Docker Compose.  

---  

*Documento criado em 25/03/2026 – versão 1.0.*  
