<?php
/**
 * API CRUD para Zenfocus - Sistema de Gerenciamento Pomodoro
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');

// Configurações do banco de dados
define('DB_HOST', getenv('DB_HOST') ?: 'zenfocus-db');
define('DB_NAME', getenv('DB_NAME') ?: 'zenfocus_db');
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') ?: 'zenfocus123');

// Conexão com o banco
function getConnection() {
    try {
        $conn = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
            DB_USER,
            DB_PASS,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false
            ]
        );
        return $conn;
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erro de conexão: ' . $e->getMessage()]);
        exit;
    }
}

// Roteamento da API
$action = $_GET['action'] ?? $_POST['action'] ?? '';

switch ($action) {
    case 'list':
        listTasks();
        break;
    
    case 'get':
        getTask();
        break;
    
    case 'create':
        createTask();
        break;
    
    case 'update':
        updateTask();
        break;
    
    case 'delete':
        deleteTask();
        break;
    
    case 'increment_pomodoro':
        incrementPomodoro();
        break;
    
    case 'health':
        healthCheck();
        break;
    
    default:
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Ação inválida']);
        break;
}

// ========== FUNÇÕES DA API ==========

function listTasks() {
    $conn = getConnection();
    
    try {
        $stmt = $conn->query("
            SELECT * FROM tarefas 
            ORDER BY 
                CASE status 
                    WHEN 'em_andamento' THEN 1
                    WHEN 'pendente' THEN 2
                    WHEN 'concluida' THEN 3
                END,
                data_criacao DESC
        ");
        
        $tasks = $stmt->fetchAll();
        echo json_encode($tasks);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function getTask() {
    $id = $_GET['id'] ?? null;
    
    if (!$id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID não fornecido']);
        return;
    }
    
    $conn = getConnection();
    
    try {
        $stmt = $conn->prepare("SELECT * FROM tarefas WHERE id = ?");
        $stmt->execute([$id]);
        
        $task = $stmt->fetch();
        
        if ($task) {
            echo json_encode($task);
        } else {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Tarefa não encontrada']);
        }
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function createTask() {
    $titulo = $_POST['titulo'] ?? '';
    $descricao = $_POST['descricao'] ?? '';
    $tempo_estimado = $_POST['tempo_estimado'] ?? 25;
    $status = $_POST['status'] ?? 'pendente';
    
    if (empty($titulo)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Título é obrigatório']);
        return;
    }
    
    $conn = getConnection();
    
    try {
        $stmt = $conn->prepare("
            INSERT INTO tarefas (titulo, descricao, tempo_estimado, status, data_criacao)
            VALUES (?, ?, ?, ?, NOW())
        ");
        
        $stmt->execute([$titulo, $descricao, $tempo_estimado, $status]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Tarefa criada com sucesso',
            'id' => $conn->lastInsertId()
        ]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function updateTask() {
    $id = $_POST['id'] ?? null;
    $titulo = $_POST['titulo'] ?? '';
    $descricao = $_POST['descricao'] ?? '';
    $tempo_estimado = $_POST['tempo_estimado'] ?? 25;
    $status = $_POST['status'] ?? 'pendente';
    
    if (!$id || empty($titulo)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Dados inválidos']);
        return;
    }
    
    $conn = getConnection();
    
    try {
        $stmt = $conn->prepare("
            UPDATE tarefas 
            SET titulo = ?, descricao = ?, tempo_estimado = ?, status = ?
            WHERE id = ?
        ");
        
        $stmt->execute([$titulo, $descricao, $tempo_estimado, $status, $id]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Tarefa atualizada com sucesso'
        ]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function deleteTask() {
    $id = $_POST['id'] ?? null;
    
    if (!$id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID não fornecido']);
        return;
    }
    
    $conn = getConnection();
    
    try {
        $stmt = $conn->prepare("DELETE FROM tarefas WHERE id = ?");
        $stmt->execute([$id]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Tarefa excluída com sucesso'
        ]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function incrementPomodoro() {
    $id = $_POST['id'] ?? null;
    
    if (!$id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID não fornecido']);
        return;
    }
    
    $conn = getConnection();
    
    try {
        $stmt = $conn->prepare("
            UPDATE tarefas 
            SET pomodoros_concluidos = pomodoros_concluidos + 1
            WHERE id = ?
        ");
        
        $stmt->execute([$id]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Pomodoro incrementado'
        ]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function healthCheck() {
    $conn = getConnection();
    
    try {
        $stmt = $conn->query("SELECT COUNT(*) as count FROM tarefas");
        $result = $stmt->fetch();
        
        echo json_encode([
            'success' => true,
            'status' => 'healthy',
            'database' => 'connected',
            'tasks_count' => $result['count'],
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'status' => 'unhealthy',
            'message' => $e->getMessage()
        ]);
    }
}
