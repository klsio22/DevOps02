#!/bin/bash

# ========================================
# Script de Teste da Aplicação Zenfocus
# ========================================

set -e

echo "🧪 Iniciando testes da aplicação Zenfocus..."
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

test_endpoint() {
    local name=$1
    local url=$2
    local expected=$3
    
    echo -n "  Testing $name... "
    response=$(curl -s "$url")
    
    if echo "$response" | grep -q "$expected"; then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED=$((PASSED+1))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "    Expected: $expected"
        echo "    Got: $response"
        FAILED=$((FAILED+1))
    fi
}

echo "🌐 Testando Aplicação Web..."
echo ""

# Test 1: Health Check
test_endpoint "Health Check" \
    "http://www.zenfocus.com.br/api.php?action=health" \
    '"status":"healthy"'

# Test 2: List Tasks
test_endpoint "List Tasks" \
    "http://www.zenfocus.com.br/api.php?action=list" \
    '['

# Test 3: Create Task
echo -n "  Testing Create Task... "
response=$(curl -s -X POST http://www.zenfocus.com.br/api.php \
    -d "action=create" \
    -d "titulo=Test Task" \
    -d "descricao=Test Description" \
    -d "tempo_estimado=25")

if echo "$response" | grep -q '"success":true'; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED=$((PASSED+1))
    TASK_ID=$(echo "$response" | grep -o '"id":"[0-9]*"' | grep -o '[0-9]*')
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED=$((FAILED+1))
fi

# Test 4: Get Task
if [ ! -z "$TASK_ID" ]; then
    test_endpoint "Get Task" \
        "http://www.zenfocus.com.br/api.php?action=get&id=$TASK_ID" \
        '"titulo":"Test Task"'
fi

# Test 5: Frontend
echo -n "  Testing Frontend... "
response=$(curl -s -o /dev/null -w "%{http_code}" http://www.zenfocus.com.br/)
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED=$((PASSED+1))
else
    echo -e "${RED}✗ FAILED (HTTP $response)${NC}"
    FAILED=$((FAILED+1))
fi

echo ""
echo "🐳 Testando Containers..."
echo ""

# Test Containers
containers=("zenfocus-dns" "zenfocus-db" "zenfocus-web" "zenfocus-gitlab" "zenfocus-runner")

for container in "${containers[@]}"; do
    echo -n "  Testing $container... "
    if docker ps | grep -q "$container"; then
        echo -e "${GREEN}✓ RUNNING${NC}"
        PASSED=$((PASSED+1))
    else
        echo -e "${RED}✗ NOT RUNNING${NC}"
        FAILED=$((FAILED+1))
    fi
done

echo ""
echo "🌐 Testando DNS..."
echo ""

# Test DNS
echo -n "  Testing DNS resolution... "
if nslookup www.zenfocus.com.br 10.164.59.91 &> /dev/null; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED=$((PASSED+1))
else
    echo -e "${YELLOW}⚠ WARNING (usando /etc/hosts)${NC}"
fi

echo ""
echo "📊 Resultados:"
echo ""
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ Todos os testes passaram!${NC}"
    exit 0
else
    echo -e "${RED}❌ Alguns testes falharam!${NC}"
    exit 1
fi
