#!/bin/bash
set -e

CA_DIR="/certs"
DOMAIN="${GITEA_DOMAIN:-gitea.zenfocus.com}"
DAYS_VALID=365

echo "=== Gerando CA e certificados para ${DOMAIN} ==="

# Gerar chave privada da CA
openssl genrsa -out "${CA_DIR}/ca.key" 4096

# Gerar certificado autoassinado da CA
openssl req -new -x509 -days ${DAYS_VALID} -key "${CA_DIR}/ca.key" -out "${CA_DIR}/ca.crt" \
    -subj "/C=BR/ST=Parana/L=Curitiba/O=Zenfocus Solutions/OU=IT/CN=Zenfocus CA"

echo "=== CA criada com sucesso ==="

# Gerar chave privada para o dominio
openssl genrsa -out "${CA_DIR}/${DOMAIN}.key" 2048

# Gerar CSR (Certificate Signing Request)
openssl req -new -key "${CA_DIR}/${DOMAIN}.key" -out "${CA_DIR}/${DOMAIN}.csr" \
    -subj "/C=BR/ST=Parana/L=Curitiba/O=Zenfocus Solutions/OU=IT/CN=${DOMAIN}"

# Assinar certificado com a CA
openssl x509 -req -days ${DAYS_VALID} -in "${CA_DIR}/${DOMAIN}.csr" \
    -CA "${CA_DIR}/ca.crt" -CAkey "${CA_DIR}/ca.key" -CAcreateserial \
    -out "${CA_DIR}/${DOMAIN}.crt"

echo "=== Certificado para ${DOMAIN} gerado com sucesso ==="

# Listar certificados gerados
echo ""
echo "Certificados gerados em ${CA_DIR}:"
ls -lh "${CA_DIR}"/*.crt "${CA_DIR}"/*.key 2>/dev/null || true
