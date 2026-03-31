<?php

declare(strict_types=1);

return [
    'app' => [
        'company_name' => getenv('APP_COMPANY_NAME') ?: 'OrbitVale Systems',
        'domain' => getenv('APP_DOMAIN') ?: 'portal.orbitvale.com.br',
    ],
    'db' => [
        'host' => getenv('DB_HOST') ?: '127.0.0.1',
        'port' => (int) (getenv('DB_PORT') ?: 3306),
        'database' => getenv('DB_NAME') ?: 'orbitvale_crud',
        'username' => getenv('DB_USER') ?: 'orbitvale_user',
        'password' => getenv('DB_PASSWORD') ?: 'change_this_password',
        'charset' => getenv('DB_CHARSET') ?: 'utf8mb4',
    ],
];
