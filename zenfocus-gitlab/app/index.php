<?php
const REDIRECT_HOME = 'Location: /';

$dbHost = getenv('DB_HOST') ?: 'db';
$dbPort = getenv('DB_PORT') ?: '3306';
$dbName = getenv('DB_NAME') ?: 'zenfocus';
$dbUser = getenv('DB_USER') ?: 'zenfocus';
$dbPass = getenv('DB_PASSWORD') ?: 'zenfocus123';
$appDomain = getenv('APP_DOMAIN') ?: 'www.zenfocus.com';

try {
    $dsn = "mysql:host={$dbHost};port={$dbPort};dbname={$dbName};charset=utf8mb4";
    $pdo = new PDO($dsn, $dbUser, $dbPass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo '<h1>Erro de conexao com banco de dados</h1>';
    echo '<p>Verifique se o container do MariaDB esta em execucao.</p>';
    exit;
}

$pdo->exec(
    "CREATE TABLE IF NOT EXISTS tasks (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(120) NOT NULL,
        description VARCHAR(255) NOT NULL,
        status VARCHAR(20) NOT NULL DEFAULT 'pendente',
        due_date DATE NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
);

$action = $_REQUEST['action'] ?? '';

if ($action === 'create') {
    $title = trim($_POST['title'] ?? '');
    $description = trim($_POST['description'] ?? '');
    $status = $_POST['status'] ?? 'pendente';
    $dueDate = $_POST['due_date'] ?? null;

    if ($title !== '' && $description !== '') {
        $stmt = $pdo->prepare(
            'INSERT INTO tasks (title, description, status, due_date) VALUES (:title, :description, :status, :due_date)'
        );
        $stmt->execute([
            ':title' => $title,
            ':description' => $description,
            ':status' => in_array($status, ['pendente', 'concluida'], true) ? $status : 'pendente',
            ':due_date' => $dueDate ?: null,
        ]);
    }

    header(REDIRECT_HOME);
    exit;
}

if ($action === 'update') {
    $id = (int) ($_POST['id'] ?? 0);
    $title = trim($_POST['title'] ?? '');
    $description = trim($_POST['description'] ?? '');
    $status = $_POST['status'] ?? 'pendente';
    $dueDate = $_POST['due_date'] ?? null;

    if ($id > 0 && $title !== '' && $description !== '') {
        $stmt = $pdo->prepare(
            'UPDATE tasks SET title = :title, description = :description, status = :status, due_date = :due_date WHERE id = :id'
        );
        $stmt->execute([
            ':id' => $id,
            ':title' => $title,
            ':description' => $description,
            ':status' => in_array($status, ['pendente', 'concluida'], true) ? $status : 'pendente',
            ':due_date' => $dueDate ?: null,
        ]);
    }

    header(REDIRECT_HOME);
    exit;
}

if ($action === 'delete') {
    $id = (int) ($_GET['id'] ?? 0);
    if ($id > 0) {
        $stmt = $pdo->prepare('DELETE FROM tasks WHERE id = :id');
        $stmt->execute([':id' => $id]);
    }
    header(REDIRECT_HOME);
    exit;
}

$editingId = (int) ($_GET['edit'] ?? 0);
$editingTask = null;
if ($editingId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM tasks WHERE id = :id');
    $stmt->execute([':id' => $editingId]);
    $editingTask = $stmt->fetch();
}

$tasks = $pdo->query('SELECT * FROM tasks ORDER BY created_at DESC, id DESC')->fetchAll();
?>
<!doctype html>
<html lang="pt-BR">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Zenfocus Solutions - CRUD de Tarefas</title>
    <link rel="stylesheet" href="/styles.css">
</head>
<body>
<div class="container">
    <header class="hero">
        <img src="/logo.svg" alt="Logo Zenfocus Solutions" class="logo">
        <div>
            <h1>Zenfocus Solutions</h1>
            <p>CRUD de tarefas para a empresa ficticia no dominio <?php echo htmlspecialchars($appDomain); ?></p>
        </div>
    </header>

    <section class="card">
        <h2><?php echo $editingTask ? 'Editar tarefa' : 'Nova tarefa'; ?></h2>
        <form method="post" action="/?action=<?php echo $editingTask ? 'update' : 'create'; ?>" class="task-form">
            <?php if ($editingTask): ?>
                <input type="hidden" name="id" value="<?php echo (int) $editingTask['id']; ?>">
            <?php endif; ?>

            <label>
                Titulo
                <input name="title" maxlength="120" required value="<?php echo htmlspecialchars($editingTask['title'] ?? ''); ?>">
            </label>

            <label>
                Descricao
                <input name="description" maxlength="255" required value="<?php echo htmlspecialchars($editingTask['description'] ?? ''); ?>">
            </label>

            <label>
                Status
                <select name="status">
                    <option value="pendente" <?php echo (($editingTask['status'] ?? '') === 'pendente') ? 'selected' : ''; ?>>Pendente</option>
                    <option value="concluida" <?php echo (($editingTask['status'] ?? '') === 'concluida') ? 'selected' : ''; ?>>Concluida</option>
                </select>
            </label>

            <label>
                Data limite
                <input type="date" name="due_date" value="<?php echo htmlspecialchars($editingTask['due_date'] ?? ''); ?>">
            </label>

            <div class="form-actions">
                <button type="submit"><?php echo $editingTask ? 'Salvar alteracoes' : 'Criar tarefa'; ?></button>
                <?php if ($editingTask): ?>
                    <a href="/" class="ghost">Cancelar</a>
                <?php endif; ?>
            </div>
        </form>
    </section>

    <section class="card">
        <h2>Tarefas cadastradas</h2>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Titulo</th>
                <th>Descricao</th>
                <th>Status</th>
                <th>Data limite</th>
                <th>Acoes</th>
            </tr>
            </thead>
            <tbody>
            <?php if (count($tasks) === 0): ?>
                <tr><td colspan="6">Nenhuma tarefa cadastrada.</td></tr>
            <?php endif; ?>

            <?php foreach ($tasks as $task): ?>
                <tr>
                    <td><?php echo (int) $task['id']; ?></td>
                    <td><?php echo htmlspecialchars($task['title']); ?></td>
                    <td><?php echo htmlspecialchars($task['description']); ?></td>
                    <td><?php echo htmlspecialchars($task['status']); ?></td>
                    <td><?php echo htmlspecialchars($task['due_date'] ?: '-'); ?></td>
                    <td class="actions">
                        <a href="/?edit=<?php echo (int) $task['id']; ?>">Editar</a>
                        <a class="danger" href="/?action=delete&id=<?php echo (int) $task['id']; ?>" onclick="return confirm('Remover esta tarefa?');">Excluir</a>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </section>
</div>
</body>
</html>
