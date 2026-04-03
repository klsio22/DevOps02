CREATE DATABASE IF NOT EXISTS pulsefocus_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pulsefocus_db;

CREATE TABLE IF NOT EXISTS tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(180) NOT NULL,
    pomodoros_estimated INT NOT NULL DEFAULT 1,
    pomodoros_completed INT NOT NULL DEFAULT 0,
    status ENUM('todo', 'active', 'done') NOT NULL DEFAULT 'todo',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO tasks (title, pomodoros_estimated, pomodoros_completed, status)
VALUES
    ('Plan CI pipeline steps', 3, 1, 'active'),
    ('Write deployment checklist', 2, 0, 'todo'),
    ('Review merge request', 1, 1, 'done');
