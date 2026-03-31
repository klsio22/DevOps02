<?php

declare(strict_types=1);

require __DIR__ . '/db.php';

$pageTitle = 'Edit Task';
$error = '';
$id = (int) ($_GET['id'] ?? 0);

if ($id <= 0) {
    header('Location: index.php');
    exit;
}

try {
    $connection = db_connect();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $title = trim((string) ($_POST['title'] ?? ''));
        $estimated = max(1, (int) ($_POST['pomodoros_estimated'] ?? 1));
        $completed = max(0, (int) ($_POST['pomodoros_completed'] ?? 0));
        $status = (string) ($_POST['status'] ?? 'todo');

        if ($title === '') {
            $error = 'Task title is required.';
        } else {
            $updateStmt = $connection->prepare(
                'UPDATE tasks SET title = ?, pomodoros_estimated = ?, pomodoros_completed = ?, status = ? WHERE id = ?'
            );
            $updateStmt->bind_param('siisi', $title, $estimated, $completed, $status, $id);
            $updateStmt->execute();

            header('Location: index.php?message=updated');
            exit;
        }
    }

    $selectStmt = $connection->prepare(
        'SELECT id, title, pomodoros_estimated, pomodoros_completed, status, created_at FROM tasks WHERE id = ? LIMIT 1'
    );
    $selectStmt->bind_param('i', $id);
    $selectStmt->execute();
    $record = $selectStmt->get_result()->fetch_assoc();

    if (!$record) {
        header('Location: index.php');
        exit;
    }
} catch (Throwable $exception) {
    $record = null;
    $error = 'Database error: ' . $exception->getMessage();
}

require __DIR__ . '/includes/header.php';
?>
<section class="panel panel-form">
    <h1>Edit Task #<?= $id ?></h1>

    <?php if ($error !== ''): ?>
        <p class="notice notice-error"><?= escape_html($error) ?></p>
    <?php endif; ?>

    <?php if ($record): ?>
        <form method="post" class="form-grid">
            <label>
                Task title
                <input type="text" name="title" value="<?= escape_html($record['title']) ?>" required>
            </label>

            <label>
                Estimated pomodoros
                <input type="number" name="pomodoros_estimated" min="1" max="20" value="<?= (int) $record['pomodoros_estimated'] ?>" required>
            </label>

            <label>
                Completed pomodoros
                <input type="number" name="pomodoros_completed" min="0" max="99" value="<?= (int) $record['pomodoros_completed'] ?>" required>
            </label>

            <label>
                Status
                <select name="status">
                    <option value="todo" <?= $record['status'] === 'todo' ? 'selected' : '' ?>>todo</option>
                    <option value="active" <?= $record['status'] === 'active' ? 'selected' : '' ?>>active</option>
                    <option value="done" <?= $record['status'] === 'done' ? 'selected' : '' ?>>done</option>
                </select>
            </label>

            <div class="form-actions">
                <a class="button button-soft" href="index.php">Cancel</a>
                <button class="button" type="submit">Update</button>
            </div>
        </form>
    <?php endif; ?>
</section>
<?php require __DIR__ . '/includes/footer.php'; ?>
