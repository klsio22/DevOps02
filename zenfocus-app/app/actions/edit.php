<?php

declare(strict_types=1);

require_once __DIR__ . '/../core/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit('Method not allowed');
}

$id = (int) ($_POST['id'] ?? 0);
$title = trim((string) ($_POST['title'] ?? ''));
$estimated = max(1, (int) ($_POST['pomodoros_estimated'] ?? 1));
$completed = max(0, (int) ($_POST['pomodoros_completed'] ?? 0));
$status = (string) ($_POST['status'] ?? 'todo');

if ($id <= 0) {
    header('Location: ../index.php?error=Invalid+task+id');
    exit;
}

if ($title === '') {
    header('Location: ../edit.php?id=' . $id . '&error=Task+title+is+required.');
    exit;
}

try {
    $connection = db_connect();
    $stmt = $connection->prepare(
        'UPDATE tasks SET title = ?, pomodoros_estimated = ?, pomodoros_completed = ?, status = ? WHERE id = ?'
    );
    $stmt->bind_param('siisi', $title, $estimated, $completed, $status, $id);
    $stmt->execute();

    header('Location: ../index.php?message=updated');
    exit;
} catch (Throwable $exception) {
    header('Location: ../edit.php?id=' . $id . '&error=' . rawurlencode('Database error: ' . $exception->getMessage()));
    exit;
}
