FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalar Easy-RSA e dependências
RUN apt-get update && \
    apt-get install -y easy-rsa openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Criar diretório de trabalho
WORKDIR /opt/easy-rsa

# Copiar scripts de inicialização
COPY init-ca.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-ca.sh

# Volume para persistir certificados
VOLUME /opt/easy-rsa/pki

EXPOSE 8080

CMD ["init-ca.sh"]
