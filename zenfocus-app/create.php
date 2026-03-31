<?php

declare(strict_types=1);

require __DIR__ . '/db.php';

$pageTitle = 'Create Request';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $clientName = trim((string) ($_POST['client_name'] ?? ''));
    $contactEmail = trim((string) ($_POST['contact_email'] ?? ''));
    $requestTopic = trim((string) ($_POST['request_topic'] ?? ''));
    $requestStatus = trim((string) ($_POST['request_status'] ?? 'open'));
    $requestedDate = trim((string) ($_POST['requested_date'] ?? ''));

    if ($clientName === '' || $contactEmail === '' || $requestTopic === '' || $requestedDate === '') {
        $error = 'All fields are required.';
    } else {
        try {
            $connection = db_connect();
            $stmt = $connection->prepare(
                'INSERT INTO service_requests (client_name, contact_email, request_topic, request_status, requested_date) VALUES (?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('sssss', $clientName, $contactEmail, $requestTopic, $requestStatus, $requestedDate);
            $stmt->execute();

            header('Location: index.php');
            exit;
        } catch (Throwable $exception) {
            $error = 'Database error: ' . $exception->getMessage();
        }
    }
}

require __DIR__ . '/includes/header.php';
?>
<section class="panel panel-form">
    <h1>Create Service Request</h1>

    <?php if ($error !== ''): ?>
        <p class="notice notice-error"><?= escape_html($error) ?></p>
    <?php endif; ?>

    <form method="post" class="form-grid">
        <label>
            Client Name
            <input type="text" name="client_name" required>
        </label>

        <label>
            Contact Email
            <input type="email" name="contact_email" required>
        </label>

        <label>
            Request Topic
            <input type="text" name="request_topic" required>
        </label>

        <label>
            Status
            <select name="request_status">
                <option value="open">open</option>
                <option value="in_progress">in_progress</option>
                <option value="closed">closed</option>
            </select>
        </label>

        <label>
            Requested Date
            <input type="date" name="requested_date" required>
        </label>

        <div class="form-actions">
            <a class="button button-soft" href="index.php">Cancel</a>
            <button class="button" type="submit">Save</button>
        </div>
    </form>
</section>
<?php require __DIR__ . '/includes/footer.php'; ?>
