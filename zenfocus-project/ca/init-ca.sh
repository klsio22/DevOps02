#!/bin/bash
set -e

echo "🔐 Inicializando Autoridade Certificadora Zenfocus..."

# Inicializar Easy-RSA
make-cadir /opt/easy-rsa/ca-setup
cd /opt/easy-rsa/ca-setup

# Configurar variáveis
cat > vars <<EOF
set_var EASYRSA_REQ_COUNTRY    "BR"
set_var EASYRSA_REQ_PROVINCE   "Parana"
set_var EASYRSA_REQ_CITY       "Curitiba"
set_var EASYRSA_REQ_ORG        "Zenfocus Solutions"
set_var EASYRSA_REQ_EMAIL      "admin@zenfocus.com.br"
set_var EASYRSA_REQ_OU         "DevOps Department"
set_var EASYRSA_KEY_SIZE       2048
set_var EASYRSA_ALGO           rsa
set_var EASYRSA_CA_EXPIRE      3650
set_var EASYRSA_CERT_EXPIRE    825
EOF

# Inicializar PKI
./easyrsa init-pki

# Criar CA sem senha
./easyrsa --batch build-ca nopass

echo "✅ CA criada com sucesso!"

# Gerar certificado para o servidor web
./easyrsa --batch --subject-alt-name="DNS:www.zenfocus.com.br,DNS:zenfocus.com.br,DNS:*.zenfocus.com.br" build-server-full www.zenfocus.com.br nopass

echo "✅ Certificado do servidor criado!"

# Gerar certificado para GitLab
./easyrsa --batch --subject-alt-name="DNS:gitlab.zenfocus.com.br" build-server-full gitlab.zenfocus.com.br nopass

echo "✅ Certificado do GitLab criado!"

# Copiar certificados para volume compartilhado
mkdir -p /opt/easy-rsa/pki/issued
cp pki/ca.crt /opt/easy-rsa/pki/
cp pki/issued/*.crt /opt/easy-rsa/pki/issued/
cp pki/private/*.key /opt/easy-rsa/pki/private/ 2>/dev/null || true

echo "📋 Certificados disponíveis em /opt/easy-rsa/pki/"
echo ""
echo "📁 Arquivos gerados:"
ls -lh /opt/easy-rsa/pki/ca.crt
ls -lh /opt/easy-rsa/pki/issued/
ls -lh /opt/easy-rsa/pki/private/

# Manter container rodando
echo ""
echo "🎉 Autoridade Certificadora rodando!"
echo "💡 Para acessar os certificados, use: docker cp <container>:/opt/easy-rsa/pki ."
tail -f /dev/null
