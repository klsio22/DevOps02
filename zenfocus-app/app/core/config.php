<?php

declare(strict_types=1);

function env_value(string $key, string $default = ''): string
{
    static $envFileVars = null;

    $fromRuntime = getenv($key);
    if ($fromRuntime !== false && $fromRuntime !== '') {
        return (string) $fromRuntime;
    }

    if ($envFileVars === null) {
        $envFileVars = [];
        $envPath = dirname(__DIR__, 2) . '/.env';
        if (is_file($envPath)) {
            $lines = file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [];
            foreach ($lines as $line) {
                $line = trim($line);
                if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
                    continue;
                }
                [$k, $v] = explode('=', $line, 2);
                $envFileVars[trim($k)] = trim($v);
            }
        }
    }

    if (array_key_exists($key, $envFileVars)) {
        return (string) $envFileVars[$key];
    }

    return $default;
}

return [
    'app' => [
        'company_name' => env_value('APP_COMPANY_NAME', 'ChronaPulse Labs'),
        'domain' => env_value('APP_DOMAIN', 'focus.chronapulse.com.br'),
        'tool_name' => 'PulseFocus',
    ],
    'db' => [
        'host' => env_value('DB_HOST', '127.0.0.1'),
        'port' => (int) env_value('DB_PORT', '3306'),
        'database' => env_value('DB_NAME', 'pulsefocus_db'),
        'username' => env_value('DB_USER', 'pulsefocus_user'),
        'password' => env_value('DB_PASSWORD', 'change_this_password'),
        'charset' => env_value('DB_CHARSET', 'utf8mb4'),
    ],
];
