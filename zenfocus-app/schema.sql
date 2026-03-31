CREATE DATABASE IF NOT EXISTS orbitvale_crud CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE orbitvale_crud;

CREATE TABLE IF NOT EXISTS service_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_name VARCHAR(120) NOT NULL,
    contact_email VARCHAR(150) NOT NULL,
    request_topic VARCHAR(150) NOT NULL,
    request_status ENUM('open', 'in_progress', 'closed') NOT NULL DEFAULT 'open',
    requested_date DATE NOT NULL
);

INSERT INTO service_requests (client_name, contact_email, request_topic, request_status, requested_date)
VALUES
    ('Acme North', 'ops@acmenorth.com', 'SSL renewal', 'open', '2026-03-30'),
    ('Delta Foods', 'it@deltafoods.com', 'Git webhook setup', 'in_progress', '2026-03-29');
