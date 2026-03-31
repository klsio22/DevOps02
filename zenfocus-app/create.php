<?php

declare(strict_types=1);

require __DIR__ . '/db.php';

$pageTitle = 'Create Task';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = trim((string) ($_POST['title'] ?? ''));
    $estimated = max(1, (int) ($_POST['pomodoros_estimated'] ?? 1));
    $status = (string) ($_POST['status'] ?? 'todo');

    if ($title === '') {
        $error = 'Task title is required.';
    } else {
        try {
            $connection = db_connect();
            $stmt = $connection->prepare(
                'INSERT INTO tasks (title, pomodoros_estimated, status) VALUES (?, ?, ?)'
            );
            $stmt->bind_param('sis', $title, $estimated, $status);
            $stmt->execute();
            header('Location: index.php?message=created');
            exit;
        } catch (Throwable $exception) {
            $error = 'Database error: ' . $exception->getMessage();
        }
    }
}

require __DIR__ . '/includes/header.php';
?>
<section class="panel panel-form">
    <h1>Create Task</h1>

    <?php if ($error !== ''): ?>
        <p class="notice notice-error"><?= escape_html($error) ?></p>
    <?php endif; ?>

    <form method="post" class="form-grid">
        <label>
            Task title
            <input type="text" name="title" required>
        </label>

        <label>
            Estimated pomodoros
            <input type="number" name="pomodoros_estimated" min="1" max="20" value="2" required>
        </label>

        <label>
            Status
            <select name="status">
                <option value="todo">todo</option>
                <option value="active">active</option>
                <option value="done">done</option>
            </select>
        </label>

        <div class="form-actions">
            <a class="button button-soft" href="index.php">Cancel</a>
            <button class="button" type="submit">Save</button>
        </div>
    </form>
</section>
<?php require __DIR__ . '/includes/footer.php'; ?>
