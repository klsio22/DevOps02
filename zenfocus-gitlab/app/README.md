Zenfocus Pomodoro App - mínimo

Arquivos:
- index.php - CRUD simples (usa ./data/tasks.json)
- styles.css - estilos

Como testar localmente com o docker-compose do projeto:

1. Certifique-se de que a rede `zenfocus-net` exista (o script start-zenfocus.sh cria se não existir).
2. Rode: docker compose up -d app
3. Acesse: https://www.zenfocus.com (ou use /etc/hosts apontando para 127.0.0.1)

Observação: o proxy faz o TLS e redireciona para o container da app.
