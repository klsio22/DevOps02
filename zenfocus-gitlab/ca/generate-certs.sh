#!/bin/bash
set -e

# Diretório destino (montado)
TARGET_DIR=/certs
mkdir -p "$TARGET_DIR"

CA_KEY="$TARGET_DIR/zenfocus-ca.key.pem"
CA_CERT="$TARGET_DIR/zenfocus-ca.crt.pem"
CERT_KEY="$TARGET_DIR/gitlab.zenfocus.local.key"
CERT_CSR="$TARGET_DIR/gitlab.zenfocus.local.csr"
CERT_CERT="$TARGET_DIR/gitlab.zenfocus.local.crt"

DAYS_VALID=3650

# Se já existe CA, não recriar
if [ -f "$CA_KEY" ] && [ -f "$CA_CERT" ]; then
  echo "CA já existe em $TARGET_DIR, pulando criação da CA"
else
  echo "Gerando CA..."
  openssl genrsa -out "$CA_KEY" 4096
  openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days $DAYS_VALID -out "$CA_CERT" -subj "/C=BR/ST=SP/L=City/O=Zenfocus/OU=DevOps/CN=zenfocus.local"
fi

# Gerar key e CSR para gitlab
if [ -f "$CERT_KEY" ] && [ -f "$CERT_CERT" ]; then
  echo "Certificado do GitLab já existe, pulando geração"
  exit 0
fi

echo "Gerando chave e CSR para gitlab.zenfocus.local..."
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
DNS.1 = gitlab.zenfocus.local
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

openssl req -new -key "$CERT_KEY" -out "$CERT_CSR" -subj "/C=BR/ST=SP/L=City/O=Zenfocus/OU=DevOps/CN=gitlab.zenfocus.local" -config <(cat /etc/ssl/openssl.cnf "$EXTFILE")

# Assinar CSR com a CA
openssl x509 -req -in "$CERT_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial -out "$CERT_CERT" -days $DAYS_VALID -sha256 -extensions v3_req -extfile "$EXTFILE"

# Ajustar permissões
chmod 644 "$CA_CERT" "$CERT_CERT"
chmod 600 "$CA_KEY" "$CERT_KEY"

echo "Certificados gerados em $TARGET_DIR"
ls -l "$TARGET_DIR"

# Manter o container curto: não ficar em foreground
exit 0
