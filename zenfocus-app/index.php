<?php

declare(strict_types=1);

require __DIR__ . '/db.php';

$pageTitle = 'Service Requests';
$message = '';

try {
    $connection = db_connect();

    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_id'])) {
        $deleteId = (int) $_POST['delete_id'];

        $deleteStmt = $connection->prepare('DELETE FROM service_requests WHERE id = ?');
        $deleteStmt->bind_param('i', $deleteId);
        $deleteStmt->execute();

        header('Location: index.php?message=deleted');
        exit;
    }

    if (isset($_GET['message']) && $_GET['message'] === 'deleted') {
        $message = 'Record deleted successfully.';
    }

    $result = $connection->query('SELECT id, client_name, contact_email, request_topic, request_status, requested_date FROM service_requests ORDER BY id DESC');
    $requests = $result->fetch_all(MYSQLI_ASSOC);
} catch (Throwable $exception) {
    $requests = [];
    $message = 'Database error: ' . $exception->getMessage();
}

require __DIR__ . '/includes/header.php';
?>
<section class="panel">
    <div class="panel-head">
        <h1>Service Request CRUD</h1>
        <a class="button" href="create.php">New Request</a>
    </div>

    <?php if ($message !== ''): ?>
        <p class="notice"><?= escape_html($message) ?></p>
    <?php endif; ?>

    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Client</th>
                <th>Email</th>
                <th>Topic</th>
                <th>Status</th>
                <th>Date</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <?php if ($requests === []): ?>
                <tr>
                    <td colspan="7">No records found.</td>
                </tr>
            <?php else: ?>
                <?php foreach ($requests as $request): ?>
                    <tr>
                        <td><?= (int) $request['id'] ?></td>
                        <td><?= escape_html($request['client_name']) ?></td>
                        <td><?= escape_html($request['contact_email']) ?></td>
                        <td><?= escape_html($request['request_topic']) ?></td>
                        <td><?= escape_html($request['request_status']) ?></td>
                        <td><?= escape_html($request['requested_date']) ?></td>
                        <td class="actions">
                            <a class="button button-soft" href="edit.php?id=<?= (int) $request['id'] ?>">Edit</a>
                            <form method="post">
                                <input type="hidden" name="delete_id" value="<?= (int) $request['id'] ?>">
                                <button class="button button-danger" type="submit">Delete</button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
            <?php endif; ?>
        </tbody>
    </table>
</section>
<?php require __DIR__ . '/includes/footer.php'; ?>
