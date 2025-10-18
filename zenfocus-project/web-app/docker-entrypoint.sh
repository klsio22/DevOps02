#!/bin/bash
set -e

echo "🚀 Iniciando Zenfocus Web Application..."

# Aguardar o banco de dados estar disponível
echo "⏳ Aguardando banco de dados..."
until php -r "new PDO('mysql:host=${DB_HOST:-zenfocus-db};dbname=${DB_NAME:-zenfocus_db}', '${DB_USER:-root}', '${DB_PASS:-zenfocus123}');" 2>/dev/null; do
    echo "   Banco de dados não está pronto - aguardando..."
    sleep 2
done

echo "✅ Banco de dados conectado!"

# Executar SQL de inicialização se necessário
if [ -f /var/www/html/database.sql ]; then
    echo "📊 Inicializando banco de dados..."
    mysql -h"${DB_HOST:-zenfocus-db}" -u"${DB_USER:-root}" -p"${DB_PASS:-zenfocus123}" < /var/www/html/database.sql 2>/dev/null || echo "Banco já inicializado."
fi

# Iniciar PHP-FPM em background
echo "🐘 Iniciando PHP-FPM..."
php-fpm -D

# Iniciar Nginx em foreground
echo "🌐 Iniciando Nginx..."
nginx -g 'daemon off;'
