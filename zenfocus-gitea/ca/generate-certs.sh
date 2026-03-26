#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_DIR="${CA_DIR:-$SCRIPT_DIR/../gitea/ssl}"
DOMAIN="${GITEA_DOMAIN:-gitea.zenfocus.com}"
DAYS_VALID=365

FORCE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force) FORCE=true; shift ;;
    *) break ;;
  esac
done

prepare_dir() {
  mkdir -p "${CA_DIR}" 2>/dev/null || true
  if [ ! -w "${CA_DIR}" ]; then
    echo "Aviso: ${CA_DIR} não é gravável – tentando ajustar permissões..."
    if sudo chown -R "$(id -u):$(id -g)" "${CA_DIR}" 2>/dev/null; then
      echo "Permissões ajustadas."
    else
      echo "Erro: não foi possível ajustar a propriedade de ${CA_DIR}."
      exit 1
    fi
  fi
}

if [ "$FORCE" = true ]; then
  echo "=== Forçando geração de novos certificados (removendo existentes) ==="
  rm -f "${CA_DIR}"/*.crt "${CA_DIR}"/*.key "${CA_DIR}"/*.csr "${CA_DIR}"/ca.srl "${CA_DIR}"/*.ext
fi

prepare_dir
echo "=== Gerando CA e certificados para ${DOMAIN} ==="
echo "Usando CA_DIR=${CA_DIR}"

# Gerar chave privada da CA
openssl genrsa -out "${CA_DIR}/ca.key" 4096

# Gerar certificado autoassinado da CA
openssl req -new -x509 -days ${DAYS_VALID} -key "${CA_DIR}/ca.key" -out "${CA_DIR}/ca.crt" \
    -subj "/C=BR/ST=Parana/L=Curitiba/O=Zenfocus Solutions/OU=IT/CN=Zenfocus CA"

echo "=== CA criada com sucesso ==="

# Gerar chave privada para o dominio
openssl genrsa -out "${CA_DIR}/${DOMAIN}.key" 2048

# Gerar CSR
openssl req -new -key "${CA_DIR}/${DOMAIN}.key" -out "${CA_DIR}/${DOMAIN}.csr" \
    -subj "/C=BR/ST=Parana/L=Curitiba/O=Zenfocus Solutions/OU=IT/CN=${DOMAIN}"

# FIX: criar arquivo de extensões com SubjectAltName
# Navegadores modernos (Chrome, Firefox, Brave) ignoram o CN e exigem SAN.
# Sem esse campo o erro é: SSL_ERROR_BAD_CERT_DOMAIN / NET::ERR_CERT_COMMON_NAME_INVALID
cat > "${CA_DIR}/${DOMAIN}.ext" <<EXTEOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:${DOMAIN},DNS:*.${DOMAIN},DNS:localhost,IP:127.0.0.1
EXTEOF

# Assinar certificado com a CA incluindo as extensões SAN
openssl x509 -req -days ${DAYS_VALID} -in "${CA_DIR}/${DOMAIN}.csr" \
    -CA "${CA_DIR}/ca.crt" -CAkey "${CA_DIR}/ca.key" -CAcreateserial \
    -extfile "${CA_DIR}/${DOMAIN}.ext" \
    -out "${CA_DIR}/${DOMAIN}.crt"

echo "=== Certificado para ${DOMAIN} gerado com sucesso ==="

# Verificar SAN no certificado gerado
echo ""
echo "=== Verificando SAN no certificado ==="
openssl x509 -in "${CA_DIR}/${DOMAIN}.crt" -noout -text \
  | grep -A2 "Subject Alternative Name" || echo "⚠️  SAN não encontrado!"

echo ""
echo "Certificados gerados em ${CA_DIR}:"
ls -lh "${CA_DIR}"/*.crt "${CA_DIR}"/*.key 2>/dev/null || true