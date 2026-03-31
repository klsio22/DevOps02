<?php

declare(strict_types=1);

return [
    'app' => [
        'company_name' => getenv('APP_COMPANY_NAME') ?: 'ChronaPulse Labs',
        'domain' => getenv('APP_DOMAIN') ?: 'focus.chronapulse.com.br',
        'tool_name' => 'PulseFocus Tasks',
    ],
    'db' => [
        'host' => getenv('DB_HOST') ?: '127.0.0.1',
        'port' => (int) (getenv('DB_PORT') ?: 3306),
        'database' => getenv('DB_NAME') ?: 'pulsefocus_db',
        'username' => getenv('DB_USER') ?: 'pulsefocus_user',
        'password' => getenv('DB_PASSWORD') ?: 'change_this_password',
        'charset' => getenv('DB_CHARSET') ?: 'utf8mb4',
    ],
];
