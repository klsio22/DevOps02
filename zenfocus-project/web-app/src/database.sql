-- Banco de dados para Zenfocus - Sistema Pomodoro
-- Criação da tabela de tarefas

CREATE DATABASE IF NOT EXISTS zenfocus_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE zenfocus_db;

CREATE TABLE IF NOT EXISTS tarefas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    tempo_estimado INT NOT NULL DEFAULT 25 COMMENT 'Tempo em minutos',
    pomodoros_concluidos INT NOT NULL DEFAULT 0,
    data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pendente', 'em_andamento', 'concluida') NOT NULL DEFAULT 'pendente',
    INDEX idx_status (status),
    INDEX idx_data_criacao (data_criacao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dados de exemplo
INSERT INTO tarefas (titulo, descricao, tempo_estimado, pomodoros_concluidos, status) VALUES
('Estudar DevOps', 'Aprender sobre Docker e CI/CD', 50, 2, 'em_andamento'),
('Implementar API REST', 'Criar endpoints para CRUD', 75, 0, 'pendente'),
('Configurar GitLab Runner', 'Setup do runner para pipeline', 25, 1, 'pendente'),
('Documentar projeto', 'Escrever README completo', 50, 3, 'concluida');
