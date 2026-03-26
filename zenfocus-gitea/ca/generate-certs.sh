#!/bin/bash
set -e

# Diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Por padrão, dentro do container usa /certs; ao rodar localmente usa gitea/ssl
CA_DIR="${CA_DIR:-$SCRIPT_DIR/../gitea/ssl}"
DOMAIN="${GITEA_DOMAIN:-gitea.zenfocus.com}"
DAYS_VALID=365

# ---------- Opções ----------
#   -f | --force   : limpa certificados antigos antes de gerar
FORCE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force) FORCE=true; shift ;;
    *) break ;;
  esac
done

# ---------- Função de preparação ----------
prepare_dir() {
  mkdir -p "${CA_DIR}" 2>/dev/null || true
  if [ ! -w "${CA_DIR}" ]; then
    echo "Aviso: ${CA_DIR} não é gravável – tentando ajustar permissões..."
    if sudo chown -R "$(id -u):$(id -g)" "${CA_DIR}" 2>/dev/null; then
      echo "Permissões ajustadas."
    else
      echo "Erro: não foi possível ajustar a propriedade de ${CA_DIR}."
      echo "Execute o script com sudo ou ajuste manualmente."
      exit 1
    fi
  fi
}

# ---------- Limpeza opcional ----------
if [ "$FORCE" = true ]; then
  echo "=== Forçando geração de novos certificados (removendo existentes) ==="
  rm -f "${CA_DIR}"/*.crt "${CA_DIR}"/*.key "${CA_DIR}"/*.csr "${CA_DIR}"/ca.srl
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
