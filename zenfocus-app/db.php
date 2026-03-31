<?php

declare(strict_types=1);

function app_config(): array
{
    static $config = null;

    if ($config === null) {
        $config = require __DIR__ . '/config.php';
    }

    return $config;
}

function db_connect(): mysqli
{
    $db = app_config()['db'];

    mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

    $connection = new mysqli(
        $db['host'],
        $db['username'],
        $db['password'],
        $db['database'],
        (int) $db['port']
    );

    $connection->set_charset($db['charset']);

    return $connection;
}

function escape_html(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
}
