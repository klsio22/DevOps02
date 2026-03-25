#!/bin/bash
set -e

echo "=== Zenfocus Gitea - Credenciais ==="
echo ""

# Tentar obter as credenciais do Gitea
GITEA_CONTAINER="zenfocus-gitea"

if docker ps | grep -q "$GITEA_CONTAINER"; then
    echo "Container Gitea em execucao. Consultando credenciais..."
    echo ""
    
    # Tentar ler o arquivo de configuracao do Gitea
    if docker exec "$GITEA_CONTAINER" cat /var/lib/gitea/gitea.ini 2>/dev/null | grep -i "admin" | head -5; then
        echo ""
        echo "Nota: As credenciais podem estar no arquivo de configuracao ou banco de dados."
    else
        echo "Usuario admin inicial: 'admin' ou 'root'"
        echo "Senha: Consulte o log ou o banco de dados."
    fi
    
    echo ""
    echo "Para ver logs de inicializacao:"
    echo "  docker logs $GITEA_CONTAINER"
    echo ""
    echo "Para consultar o banco de dados:"
    echo "  docker exec -it zenfocus-gitea-db mysql -u root -p"
else
    echo "Erro: Container Gitea nao esta em execucao."
    echo "Execute ./start-zenfocus.sh para iniciar o ambiente."
fi
