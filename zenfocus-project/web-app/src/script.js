// Variáveis globais do timer
let timerInterval;
let timeLeft = 25 * 60; // 25 minutos em segundos
let isRunning = false;
let isWorkMode = true;

// Carregar tarefas ao iniciar
document.addEventListener('DOMContentLoaded', function() {
    loadTasks();
    
    // Event listener para o formulário
    document.getElementById('taskForm').addEventListener('submit', handleFormSubmit);
});

// ========== TEMPORIZADOR POMODORO ==========

function startTimer() {
    if (!isRunning) {
        isRunning = true;
        document.getElementById('startBtn').disabled = true;
        document.getElementById('pauseBtn').disabled = false;
        
        timerInterval = setInterval(() => {
            timeLeft--;
            updateTimerDisplay();
            
            if (timeLeft <= 0) {
                completePomodoro();
            }
        }, 1000);
    }
}

function pauseTimer() {
    isRunning = false;
    clearInterval(timerInterval);
    document.getElementById('startBtn').disabled = false;
    document.getElementById('pauseBtn').disabled = true;
}

function resetTimer() {
    pauseTimer();
    timeLeft = isWorkMode ? 25 * 60 : 5 * 60;
    updateTimerDisplay();
}

function updateTimerDisplay() {
    const minutes = Math.floor(timeLeft / 60);
    const seconds = timeLeft % 60;
    document.getElementById('timerDisplay').textContent = 
        `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

function completePomodoro() {
    pauseTimer();
    
    // Notificação
    alert(isWorkMode ? '🎉 Pomodoro concluído! Hora da pausa!' : '✅ Pausa concluída! Vamos trabalhar!');
    
    // Alternar modo
    isWorkMode = !isWorkMode;
    timeLeft = isWorkMode ? 25 * 60 : 5 * 60;
    
    const modeLabel = document.getElementById('modeLabel');
    modeLabel.textContent = isWorkMode ? 'Modo: Trabalho (25min)' : 'Modo: Pausa (5min)';
    
    updateTimerDisplay();
}

// ========== CRUD DE TAREFAS ==========

async function loadTasks() {
    try {
        const response = await fetch('api.php?action=list');
        const tasks = await response.json();
        
        const tasksList = document.getElementById('tasksList');
        
        if (tasks.length === 0) {
            tasksList.innerHTML = '<p style="text-align: center; color: #888;">Nenhuma tarefa cadastrada ainda.</p>';
            return;
        }
        
        tasksList.innerHTML = tasks.map(task => `
            <div class="task-item ${task.status}">
                <div class="task-header">
                    <h3 class="task-title">${escapeHtml(task.titulo)}</h3>
                    <span class="task-status ${task.status}">${formatStatus(task.status)}</span>
                </div>
                
                <p class="task-description">${escapeHtml(task.descricao || 'Sem descrição')}</p>
                
                <div class="task-meta">
                    <span>⏱️ ${task.tempo_estimado} min</span>
                    <span>🍅 ${task.pomodoros_concluidos} pomodoros</span>
                    <span>📅 ${formatDate(task.data_criacao)}</span>
                </div>
                
                <div class="task-actions">
                    <button class="btn btn-primary" onclick="editTask(${task.id})">Editar</button>
                    <button class="btn btn-success" onclick="incrementPomodoro(${task.id})">+1 Pomodoro</button>
                    <button class="btn btn-danger" onclick="deleteTask(${task.id})">Excluir</button>
                </div>
            </div>
        `).join('');
        
    } catch (error) {
        console.error('Erro ao carregar tarefas:', error);
        alert('Erro ao carregar tarefas. Verifique a conexão com o banco de dados.');
    }
}

async function handleFormSubmit(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const taskId = document.getElementById('taskId').value;
    
    // Definir ação correta
    formData.set('action', taskId ? 'update' : 'create');
    
    try {
        const response = await fetch('api.php', {
            method: 'POST',
            body: formData
        });
        
        const result = await response.json();
        
        if (result.success) {
            alert(taskId ? 'Tarefa atualizada com sucesso!' : 'Tarefa criada com sucesso!');
            e.target.reset();
            document.getElementById('taskId').value = '';
            loadTasks();
        } else {
            alert('Erro: ' + result.message);
        }
        
    } catch (error) {
        console.error('Erro ao salvar tarefa:', error);
        alert('Erro ao salvar tarefa.');
    }
}

async function editTask(id) {
    try {
        const response = await fetch(`api.php?action=get&id=${id}`);
        const task = await response.json();
        
        document.getElementById('taskId').value = task.id;
        document.getElementById('titulo').value = task.titulo;
        document.getElementById('descricao').value = task.descricao;
        document.getElementById('tempo_estimado').value = task.tempo_estimado;
        document.getElementById('status').value = task.status;
        
        // Scroll para o formulário
        document.querySelector('.task-form').scrollIntoView({ behavior: 'smooth' });
        
    } catch (error) {
        console.error('Erro ao carregar tarefa:', error);
        alert('Erro ao carregar tarefa para edição.');
    }
}

async function deleteTask(id) {
    if (!confirm('Tem certeza que deseja excluir esta tarefa?')) {
        return;
    }
    
    try {
        const formData = new FormData();
        formData.append('action', 'delete');
        formData.append('id', id);
        
        const response = await fetch('api.php', {
            method: 'POST',
            body: formData
        });
        
        const result = await response.json();
        
        if (result.success) {
            alert('Tarefa excluída com sucesso!');
            loadTasks();
        } else {
            alert('Erro ao excluir tarefa: ' + result.message);
        }
        
    } catch (error) {
        console.error('Erro ao excluir tarefa:', error);
        alert('Erro ao excluir tarefa.');
    }
}

async function incrementPomodoro(id) {
    try {
        const formData = new FormData();
        formData.append('action', 'increment_pomodoro');
        formData.append('id', id);
        
        const response = await fetch('api.php', {
            method: 'POST',
            body: formData
        });
        
        const result = await response.json();
        
        if (result.success) {
            loadTasks();
        } else {
            alert('Erro ao incrementar pomodoro: ' + result.message);
        }
        
    } catch (error) {
        console.error('Erro ao incrementar pomodoro:', error);
    }
}

function cancelEdit() {
    document.getElementById('taskForm').reset();
    document.getElementById('taskId').value = '';
}

// ========== FUNÇÕES AUXILIARES ==========

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatStatus(status) {
    const statusMap = {
        'pendente': 'Pendente',
        'em_andamento': 'Em Andamento',
        'concluida': 'Concluída'
    };
    return statusMap[status] || status;
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}
