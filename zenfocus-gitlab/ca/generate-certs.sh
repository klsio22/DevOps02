#!/bin/bash
set -e

# Diretorio destino:
# - No container CA: /certs (volume montado)
# - Execucao local: ../gitlab/ssl
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${TARGET_DIR:-/certs}"

if ! mkdir -p "$TARGET_DIR" 2>/dev/null; then
  TARGET_DIR="${SCRIPT_DIR}/../gitlab/ssl"
  mkdir -p "$TARGET_DIR"
  echo "Sem permissao para usar /certs no host; usando $TARGET_DIR"
fi

CA_KEY="$TARGET_DIR/zenfocus-ca.key.pem"
CA_CERT="$TARGET_DIR/zenfocus-ca.crt.pem"
CERT_KEY="$TARGET_DIR/gitlab.zenfocus.com.key"
CERT_CSR="$TARGET_DIR/gitlab.zenfocus.com.csr"
CERT_CERT="$TARGET_DIR/gitlab.zenfocus.com.crt"

DAYS_VALID=3650

certs_are_valid() {
  [ -f "$CA_KEY" ] && [ -f "$CA_CERT" ] && [ -f "$CERT_KEY" ] && [ -f "$CERT_CERT" ] || return 1

  openssl x509 -in "$CA_CERT" -noout >/dev/null 2>&1 || return 1
  openssl x509 -in "$CERT_CERT" -noout >/dev/null 2>&1 || return 1
  openssl verify -CAfile "$CA_CERT" "$CERT_CERT" >/dev/null 2>&1 || return 1

  return 0
}

# Se já existe CA e certificado válidos, não recriar
if certs_are_valid; then
  echo "CA e certificado do GitLab já existem e estão válidos em $TARGET_DIR"
  exit 0
fi

# Se já existe CA, não recriar apenas a CA
if [ -f "$CA_KEY" ] && [ -f "$CA_CERT" ]; then
  echo "CA já existe em $TARGET_DIR, validando e prosseguindo com o certificado do GitLab"
else
  echo "Gerando CA..."
  openssl genrsa -out "$CA_KEY" 4096
  openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days $DAYS_VALID -out "$CA_CERT" -subj "/C=BR/ST=SP/L=City/O=Zenfocus/OU=DevOps/CN=zenfocus.com"
fi

# Gerar key e CSR para gitlab
if [ -f "$CERT_KEY" ] && [ -f "$CERT_CERT" ]; then
  echo "Certificado do GitLab existe, mas a validação falhou; regenerando"
fi

echo "Gerando chave e CSR para gitlab.zenfocus.com..."
openssl genrsa -out "$CERT_KEY" 2048

# Criar um arquivo de extensão para SAN
EXTFILE="/tmp/gitlab_ext.cnf"
cat > "$EXTFILE" <<EOF
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[ req_distinguished_name ]

[ v3_req ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = gitlab.zenfocus.com
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

openssl req -new -key "$CERT_KEY" -out "$CERT_CSR" -subj "/C=BR/ST=SP/L=City/O=Zenfocus/OU=DevOps/CN=gitlab.zenfocus.com" -config <(cat /etc/ssl/openssl.cnf "$EXTFILE")

# Assinar CSR com a CA
openssl x509 -req -in "$CERT_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial -out "$CERT_CERT" -days $DAYS_VALID -sha256 -extensions v3_req -extfile "$EXTFILE"

# Ajustar permissões
chmod 644 "$CA_CERT" "$CERT_CERT"
chmod 600 "$CA_KEY" "$CERT_KEY"

echo "Certificados gerados em $TARGET_DIR"
ls -l "$TARGET_DIR"

# Manter o container curto: não ficar em foreground
exit 0
