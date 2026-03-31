<?php

declare(strict_types=1);

require __DIR__ . '/db.php';

$pageTitle = 'PulseFocus';
$message = '';
$clockModeDefault = 'pomodoro';

try {
    $connection = db_connect();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = (string) ($_POST['action'] ?? '');

        if ($action === 'create') {
            $title = trim((string) ($_POST['title'] ?? ''));
            $estimated = max(1, (int) ($_POST['pomodoros_estimated'] ?? 1));
            if ($title !== '') {
                $insertStmt = $connection->prepare('INSERT INTO tasks (title, pomodoros_estimated) VALUES (?, ?)');
                $insertStmt->bind_param('si', $title, $estimated);
                $insertStmt->execute();
                header('Location: index.php?message=created');
                exit;
            }
        }

        if ($action === 'delete') {
            $deleteId = (int) ($_POST['id'] ?? 0);
            $deleteStmt = $connection->prepare('DELETE FROM tasks WHERE id = ?');
            $deleteStmt->bind_param('i', $deleteId);
            $deleteStmt->execute();
            header('Location: index.php?message=deleted');
            exit;
        }

        if ($action === 'focus') {
            $focusId = (int) ($_POST['id'] ?? 0);
            $normalizeStmt = $connection->prepare("UPDATE tasks SET status = IF(status = 'done', 'done', 'todo')");
            $normalizeStmt->execute();

            if ($focusId > 0) {
                $focusStmt = $connection->prepare('UPDATE tasks SET status = ? WHERE id = ?');
                $activeStatus = 'active';
                $focusStmt->bind_param('si', $activeStatus, $focusId);
                $focusStmt->execute();
            }

            header('Location: index.php?message=focused');
            exit;
        }
    }

    $rawMessage = (string) ($_GET['message'] ?? '');
    $messages = [
        'created' => 'Task created.',
        'deleted' => 'Task deleted.',
        'focused' => 'Focus task selected.',
        'updated' => 'Task updated.',
    ];
    $message = $messages[$rawMessage] ?? '';

    $result = $connection->query('SELECT id, title, pomodoros_estimated, pomodoros_completed, status, created_at FROM tasks ORDER BY id DESC');
    $tasks = $result->fetch_all(MYSQLI_ASSOC);
    $activeTask = null;
    foreach ($tasks as $task) {
        if ($task['status'] === 'active') {
            $activeTask = $task;
            break;
        }
    }
} catch (Throwable $exception) {
    $tasks = [];
    $activeTask = null;
    $message = 'Database error: ' . $exception->getMessage();
}

require __DIR__ . '/includes/header.php';
?>
<section class="home-layout" data-initial-mode="<?= escape_html($clockModeDefault) ?>" data-pomodoro-minutes="40" data-short-break-minutes="5" data-long-break-minutes="15" data-active-estimated="<?= $activeTask ? (int) $activeTask['pomodoros_estimated'] : 1 ?>" data-active-completed="<?= $activeTask ? (int) $activeTask['pomodoros_completed'] : 0 ?>">
    <section class="timer-shell panel">
        <div class="timer-tabs" role="tablist" aria-label="Timer modes">
            <button class="tab-btn is-active" type="button" data-mode="pomodoro">Pomodoro</button>
            <button class="tab-btn" type="button" data-mode="short_break">Short Break</button>
            <button class="tab-btn" type="button" data-mode="long_break">Long Break</button>
        </div>

        <p class="timer-value" id="timer-value" aria-live="polite">40:00</p>

        <div class="timer-controls">
            <button class="control-main" id="pause-btn" type="button">Pause</button>
            <button class="control-icon" id="start-btn" type="button" aria-label="Start">
                <span class="play-triangle" aria-hidden="true"></span>
            </button>
            <button class="control-reset" id="reset-btn" type="button">Reset</button>
        </div>
    </section>

    <section class="tasks-shell panel">
        <div class="active-task-block">
            <?php if ($activeTask): ?>
                <p class="active-id">#<?= (int) $activeTask['id'] ?></p>
                <h2 class="active-title"><?= escape_html($activeTask['title']) ?></h2>
                <p class="active-meta" id="active-meta">
                    Pomos: <strong><?= (int) $activeTask['pomodoros_completed'] ?>/<?= (int) $activeTask['pomodoros_estimated'] ?></strong>
                    Finish At: <strong id="finish-at">--:--</strong>
                    (<span id="remaining-hours">0.0h</span>)
                </p>
            <?php else: ?>
                <p class="active-id">No active task</p>
                <h2 class="active-title">Select a task below</h2>
                <p class="active-meta" id="active-meta">Pomos: <strong>0/1</strong> Finish At: <strong id="finish-at">--:--</strong> (<span id="remaining-hours">0.0h</span>)</p>
            <?php endif; ?>
        </div>

        <div class="tasks-head">
            <h3>Tasks</h3>
            <a class="button button-mini button-soft" href="edit.php<?= $activeTask ? '?id=' . (int) $activeTask['id'] : '' ?>">Setting</a>
        </div>

        <?php if ($message !== ''): ?>
            <p class="notice"><?= escape_html($message) ?></p>
        <?php endif; ?>

        <ul class="task-list compact">
            <?php if ($tasks === []): ?>
                <li class="task-empty">No tasks yet.</li>
            <?php else: ?>
                <?php foreach ($tasks as $task): ?>
                    <li class="task-row <?= $task['status'] === 'active' ? 'task-row-active' : '' ?>">
                        <div class="task-main">
                            <span class="task-name"><?= escape_html($task['title']) ?></span>
                            <span class="task-progress"><?= (int) $task['pomodoros_completed'] ?>/<?= (int) $task['pomodoros_estimated'] ?></span>
                        </div>
                        <div class="task-actions">
                            <form method="post">
                                <input type="hidden" name="action" value="focus">
                                <input type="hidden" name="id" value="<?= (int) $task['id'] ?>">
                                <button class="button button-mini" type="submit">Focus</button>
                            </form>
                            <a class="button button-mini button-soft" href="edit.php?id=<?= (int) $task['id'] ?>">Edit</a>
                            <form method="post" data-delete-form="true">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="id" value="<?= (int) $task['id'] ?>">
                                <button class="button button-mini button-danger" type="submit">Delete</button>
                            </form>
                        </div>
                    </li>
                <?php endforeach; ?>
            <?php endif; ?>
        </ul>

        <form method="post" class="add-task-bar">
            <input type="hidden" name="action" value="create">
            <input type="text" name="title" placeholder="Add Task" required>
            <input type="number" name="pomodoros_estimated" min="1" max="20" value="1" required>
            <button class="button" type="submit">Add Task</button>
        </form>
    </section>
</section>

<?php require __DIR__ . '/includes/footer.php'; ?>
