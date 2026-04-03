<?php

declare(strict_types=1);

require __DIR__ . '/../app/core/database.php';

$pageTitle = 'Create Task';

$error = (string) ($_GET['error'] ?? '');

require __DIR__ . '/../views/partials/header.php';
?>
<section class="panel panel-form">
    <h1>Create Task</h1>

    <?php if ($error !== ''): ?>
        <p class="notice notice-error"><?= escape_html($error) ?></p>
    <?php endif; ?>

    <form method="post" action="actions/create.php" class="form-grid">
        <input type="hidden" name="redirect" value="../create.php">
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
<?php require __DIR__ . '/../views/partials/footer.php'; ?>
