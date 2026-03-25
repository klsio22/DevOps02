-- Criar banco de dados e usuario para o Gitea
CREATE DATABASE IF NOT EXISTS gitea CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'gitea'@'%' IDENTIFIED BY 'gitea123';
GRANT ALL PRIVILEGES ON gitea.* TO 'gitea'@'%';
FLUSH PRIVILEGES;
