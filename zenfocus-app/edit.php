<?php

declare(strict_types=1);

require __DIR__ . '/db.php';

$pageTitle = 'Edit Request';
$error = '';
$id = (int) ($_GET['id'] ?? 0);

if ($id <= 0) {
    header('Location: index.php');
    exit;
}

try {
    $connection = db_connect();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $clientName = trim((string) ($_POST['client_name'] ?? ''));
        $contactEmail = trim((string) ($_POST['contact_email'] ?? ''));
        $requestTopic = trim((string) ($_POST['request_topic'] ?? ''));
        $requestStatus = trim((string) ($_POST['request_status'] ?? 'open'));
        $requestedDate = trim((string) ($_POST['requested_date'] ?? ''));

        if ($clientName === '' || $contactEmail === '' || $requestTopic === '' || $requestedDate === '') {
            $error = 'All fields are required.';
        } else {
            $updateStmt = $connection->prepare(
                'UPDATE service_requests SET client_name = ?, contact_email = ?, request_topic = ?, request_status = ?, requested_date = ? WHERE id = ?'
            );
            $updateStmt->bind_param('sssssi', $clientName, $contactEmail, $requestTopic, $requestStatus, $requestedDate, $id);
            $updateStmt->execute();

            header('Location: index.php');
            exit;
        }
    }

    $selectStmt = $connection->prepare(
        'SELECT id, client_name, contact_email, request_topic, request_status, requested_date FROM service_requests WHERE id = ? LIMIT 1'
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
    <h1>Edit Service Request #<?= $id ?></h1>

    <?php if ($error !== ''): ?>
        <p class="notice notice-error"><?= escape_html($error) ?></p>
    <?php endif; ?>

    <?php if ($record): ?>
        <form method="post" class="form-grid">
            <label>
                Client Name
                <input type="text" name="client_name" value="<?= escape_html($record['client_name']) ?>" required>
            </label>

            <label>
                Contact Email
                <input type="email" name="contact_email" value="<?= escape_html($record['contact_email']) ?>" required>
            </label>

            <label>
                Request Topic
                <input type="text" name="request_topic" value="<?= escape_html($record['request_topic']) ?>" required>
            </label>

            <label>
                Status
                <select name="request_status">
                    <option value="open" <?= $record['request_status'] === 'open' ? 'selected' : '' ?>>open</option>
                    <option value="in_progress" <?= $record['request_status'] === 'in_progress' ? 'selected' : '' ?>>in_progress</option>
                    <option value="closed" <?= $record['request_status'] === 'closed' ? 'selected' : '' ?>>closed</option>
                </select>
            </label>

            <label>
                Requested Date
                <input type="date" name="requested_date" value="<?= escape_html($record['requested_date']) ?>" required>
            </label>

            <div class="form-actions">
                <a class="button button-soft" href="index.php">Cancel</a>
                <button class="button" type="submit">Update</button>
            </div>
        </form>
    <?php endif; ?>
</section>
<?php require __DIR__ . '/includes/footer.php'; ?>
