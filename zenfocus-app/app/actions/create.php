<?php

declare(strict_types=1);

require_once __DIR__ . '/../core/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit('Method not allowed');
}

$title = trim((string) ($_POST['title'] ?? ''));
$estimated = max(1, (int) ($_POST['pomodoros_estimated'] ?? 1));
$status = (string) ($_POST['status'] ?? 'todo');
$redirect = (string) ($_POST['redirect'] ?? '../index.php');

if ($title === '') {
    header('Location: ' . $redirect . '?error=Task+title+is+required.');
    exit;
}

try {
    $connection = db_connect();
    $stmt = $connection->prepare(
        'INSERT INTO tasks (title, pomodoros_estimated, status) VALUES (?, ?, ?)'
    );
    $stmt->bind_param('sis', $title, $estimated, $status);
    $stmt->execute();

    header('Location: ../index.php?message=created');
    exit;
} catch (Throwable $exception) {
    header('Location: ' . $redirect . '?error=' . rawurlencode('Database error: ' . $exception->getMessage()));
    exit;
}
