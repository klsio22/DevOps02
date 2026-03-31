Zenfocus CRUD - Passo I

Aplicacao web CRUD em PHP puro com banco MariaDB, sem framework e sem proxy.

Arquivos principais:
- index.php - CRUD completo (Create, Read, Update, Delete)
- styles.css - estilos da interface
- logo.svg - logotipo da empresa ficticia
- init.sql - criacao da tabela tasks
- Dockerfile - imagem PHP com extensao pdo_mysql

Como executar:

1. Na raiz do projeto, rode:

	./start-zenfocus.sh

2. Acesse no navegador:

	http://localhost:8080

3. Opcional para usar dominio escolhido no trabalho:

	sudo sh -c "echo '127.0.0.1 www.zenfocus.com' >> /etc/hosts"
	http://www.zenfocus.com:8080

Tabela unica usada no projeto:
- tasks (id, title, description, status, due_date, created_at)
