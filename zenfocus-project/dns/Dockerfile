FROM ubuntu:22.04

# Evitar interações durante instalação
ENV DEBIAN_FRONTEND=noninteractive

# Instalar BIND9
RUN apt-get update && \
    apt-get install -y bind9 bind9utils bind9-doc dnsutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copiar arquivos de configuração
COPY config/named.conf.local /etc/bind/named.conf.local
COPY config/named.conf.options /etc/bind/named.conf.options
COPY config/db.zenfocus.com.br /etc/bind/db.zenfocus.com.br

# Permissões corretas
RUN chown -R bind:bind /etc/bind && \
    chmod 644 /etc/bind/db.zenfocus.com.br

# Expor porta DNS
EXPOSE 53/udp
EXPOSE 53/tcp

# Iniciar BIND9 em foreground
CMD ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf", "-u", "bind"]
