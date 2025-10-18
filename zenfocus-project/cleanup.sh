#!/bin/bash

# ========================================
# Script de Limpeza - Zenfocus
# ========================================

echo "🧹 Limpeza do projeto Zenfocus..."
echo ""

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  ATENÇÃO: Este script irá remover:${NC}"
echo "  - Todos os containers do Zenfocus"
echo "  - Todos os volumes (dados serão perdidos!)"
echo "  - Imagens Docker do projeto"
echo "  - Entradas do /etc/hosts"
echo ""

read -p "Deseja continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

echo ""
echo -e "${GREEN}[1/5]${NC} Parando containers..."
docker-compose down

echo ""
echo -e "${GREEN}[2/5]${NC} Removendo volumes..."
docker-compose down -v

echo ""
echo -e "${GREEN}[3/5]${NC} Removendo imagens..."
docker images | grep zenfocus | awk '{print $3}' | xargs -r docker rmi -f

echo ""
echo -e "${GREEN}[4/5]${NC} Limpando sistema Docker..."
docker system prune -f

echo ""
echo -e "${GREEN}[5/5]${NC} Removendo entradas do /etc/hosts..."
if [ -f /etc/hosts ]; then
    sudo sed -i.backup '/zenfocus.com.br/d' /etc/hosts
    echo "  Backup criado: /etc/hosts.backup"
fi

echo ""
echo -e "${GREEN}✅ Limpeza concluída!${NC}"
echo ""
echo "Para reinstalar, execute: ./setup.sh"
