<?php
// Pomodoro CRUD mínimo (arquivo json como "DB")
$dbFile = __DIR__ . '/data/tasks.json';
if (!file_exists(dirname($dbFile))) {
    mkdir(dirname($dbFile), 0755, true);
}
if (!file_exists($dbFile)) {
    file_put_contents($dbFile, json_encode([]));
}

$tasks = json_decode(file_get_contents($dbFile), true);
$action = $_REQUEST['action'] ?? '';

if ($action === 'create') {
    $title = trim($_POST['title'] ?? '');
    if ($title !== '') {
        $id = time();
        $tasks[$id] = ['id' => $id, 'title' => $title, 'completed' => false, 'pomodoros' => 0];
        file_put_contents($dbFile, json_encode($tasks, JSON_PRETTY_PRINT));
    }
    header('Location: /');
    exit;
}

if ($action === 'delete') {
    $id = $_GET['id'] ?? null;
    if ($id && isset($tasks[$id])) {
        unset($tasks[$id]);
        file_put_contents($dbFile, json_encode($tasks, JSON_PRETTY_PRINT));
    }
    header('Location: /');
    exit;
}

if ($action === 'start') {
    // incrementar pomodoro como simulação
    $id = $_GET['id'] ?? null;
    if ($id && isset($tasks[$id])) {
        $tasks[$id]['pomodoros'] += 1;
        file_put_contents($dbFile, json_encode($tasks, JSON_PRETTY_PRINT));
    }
    header('Location: /');
    exit;
}

?>
<!doctype html>
<html lang="pt-BR">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Zenfocus - Pomodoro App</title>
    <link rel="stylesheet" href="/styles.css">
</head>
<body>
<div class="container">
    <h1>Zenfocus - Pomodoro</h1>
    <form method="post" action="/?action=create" class="new-task">
        <input name="title" placeholder="Nova tarefa" required>
        <button type="submit">Adicionar</button>
    </form>

    <ul class="tasks">
        <?php foreach ($tasks as $t): ?>
            <li>
                <strong><?php echo htmlspecialchars($t['title']); ?></strong>
                <div class="meta">Pomodoros: <?php echo $t['pomodoros']; ?></div>
                <div class="actions">
                    <a href="/?action=start&id=<?php echo $t['id']; ?>">Iniciar Pomodoro</a>
                    <a href="/?action=delete&id=<?php echo $t['id']; ?>" class="danger">Remover</a>
                </div>
            </li>
        <?php endforeach; ?>
    </ul>

    <p class="note">Esse é um CRUD mínimo rodando dentro do container do app. Não use em produção.</p>
</div>
</body>
</html>
