<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zenfocus - Gerenciador Pomodoro</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <!-- Header -->
        <header>
            <div class="logo">
                <svg width="40" height="40" viewBox="0 0 40 40">
                    <circle cx="20" cy="20" r="18" fill="none" stroke="#4CAF50" stroke-width="2"/>
                    <circle cx="20" cy="20" r="12" fill="#4CAF50" opacity="0.3"/>
                    <path d="M 20 8 L 20 20 L 28 20" stroke="#4CAF50" stroke-width="2" fill="none" stroke-linecap="round"/>
                </svg>
                <h1>Zenfocus</h1>
            </div>
            <p class="subtitle">Gerenciador de Tarefas Pomodoro</p>
        </header>

        <!-- Temporizador Pomodoro -->
        <div class="pomodoro-timer">
            <div class="timer-display" id="timerDisplay">25:00</div>
            <div class="timer-controls">
                <button class="btn btn-primary" id="startBtn" onclick="startTimer()">Iniciar</button>
                <button class="btn btn-secondary" id="pauseBtn" onclick="pauseTimer()" disabled>Pausar</button>
                <button class="btn btn-danger" id="resetBtn" onclick="resetTimer()">Resetar</button>
            </div>
            <div class="timer-mode">
                <span class="mode-label" id="modeLabel">Modo: Trabalho (25min)</span>
            </div>
        </div>

        <!-- Formulário de Nova Tarefa -->
        <div class="task-form">
            <h2>Nova Tarefa</h2>
            <form id="taskForm" method="POST" action="api.php">
                <input type="hidden" name="action" value="create">
                <input type="hidden" name="id" id="taskId">
                
                <div class="form-group">
                    <label for="titulo">Título:</label>
                    <input type="text" id="titulo" name="titulo" required>
                </div>
                
                <div class="form-group">
                    <label for="descricao">Descrição:</label>
                    <textarea id="descricao" name="descricao" rows="3"></textarea>
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label for="tempo_estimado">Tempo Estimado (min):</label>
                        <input type="number" id="tempo_estimado" name="tempo_estimado" value="25" min="1">
                    </div>
                    
                    <div class="form-group">
                        <label for="status">Status:</label>
                        <select id="status" name="status">
                            <option value="pendente">Pendente</option>
                            <option value="em_andamento">Em Andamento</option>
                            <option value="concluida">Concluída</option>
                        </select>
                    </div>
                </div>
                
                <div class="form-actions">
                    <button type="submit" class="btn btn-success">Salvar Tarefa</button>
                    <button type="button" class="btn btn-secondary" onclick="cancelEdit()">Cancelar</button>
                </div>
            </form>
        </div>

        <!-- Lista de Tarefas -->
        <div class="tasks-list">
            <h2>Minhas Tarefas</h2>
            <div id="tasksList">
                <!-- Tarefas serão carregadas aqui via JavaScript -->
            </div>
        </div>
    </div>

    <footer>
        <p>&copy; 2024 Zenfocus Solutions - Sistema de Gerenciamento Pomodoro</p>
    </footer>

    <script src="script.js"></script>
</body>
</html>
