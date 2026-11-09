const http = require('http');
const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');
const { WebSocketServer, WebSocket } = require('ws');

const app = express();
const PORT = process.env.PORT || 3000;
const DB_FILE = path.join(__dirname, 'tasks.json');

// Middleware
app.use(cors());
app.use(express.json());

// Initial seed data if file does not exist
const initialTasks = [
  {
    id: '1',
    title: 'Мобильді қосымшаны әзірлеу (Lab 6)',
    subject: 'Cross-platform dev',
    description: 'WebSocket және REST API интеграциясын аяқтау',
    deadline: new Date(Date.now() + 86400000).toISOString().split('T')[0],
    priority: 'Жоғары',
    isCompleted: false,
    isFavorite: true,
  },
  {
    id: '2',
    title: 'Деректер қоры курстық жұмысы',
    subject: 'Database Systems',
    description: 'PostgreSQL кестелерін нормализациялау',
    deadline: new Date(Date.now() + 172800000).toISOString().split('T')[0],
    priority: 'Орташа',
    isCompleted: false,
    isFavorite: false,
  },
  {
    id: '3',
    title: 'Алгоритмдер және деректер құрылымы',
    subject: 'Algorithms',
    description: 'Dynamic programming есептерін шығару',
    deadline: new Date(Date.now() + 259200000).toISOString().split('T')[0],
    priority: 'Төмен',
    isCompleted: true,
    isFavorite: false,
  },
];

// Helper to load tasks
function loadTasks() {
  try {
    if (!fs.existsSync(DB_FILE)) {
      saveTasks(initialTasks);
      return initialTasks;
    }
    const data = fs.readFileSync(DB_FILE, 'utf8');
    return JSON.parse(data);
  } catch (err) {
    console.error('Error loading tasks:', err);
    return initialTasks;
  }
}

// Helper to save tasks
function saveTasks(tasks) {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(tasks, null, 2), 'utf8');
  } catch (err) {
    console.error('Error saving tasks:', err);
  }
}

// REST API Endpoints
app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime(), timestamp: new Date() });
});

// GET /tasks
app.get('/tasks', (req, res) => {
  const tasks = loadTasks();
  res.json(tasks);
});

// POST /tasks
app.post('/tasks', (req, res) => {
  const tasks = loadTasks();
  const newTask = {
    ...req.body,
    id: req.body.id ? String(req.body.id) : String(Date.now()),
    isCompleted: req.body.isCompleted === true || req.body.isCompleted === 'true',
    createdAt: new Date().toISOString(),
  };

  tasks.push(newTask);
  saveTasks(tasks);

  // Broadcast realtime event
  broadcast({
    type: 'task_update',
    action: 'create',
    task: newTask,
    timestamp: new Date().toISOString(),
  });

  res.status(201).json(newTask);
});

// PUT /tasks/:id
app.put('/tasks/:id', (req, res) => {
  const tasks = loadTasks();
  const index = tasks.findIndex((t) => String(t.id) === String(req.params.id));

  if (index === -1) {
    return res.status(404).json({ error: 'Тапсырма табылмады (Task not found)' });
  }

  const updatedTask = {
    ...tasks[index],
    ...req.body,
    id: String(req.params.id),
    isCompleted:
      req.body.isCompleted !== undefined
        ? req.body.isCompleted === true || req.body.isCompleted === 'true'
        : tasks[index].isCompleted,
    updatedAt: new Date().toISOString(),
  };

  tasks[index] = updatedTask;
  saveTasks(tasks);

  // Broadcast realtime event
  broadcast({
    type: 'task_update',
    action: 'update',
    task: updatedTask,
    timestamp: new Date().toISOString(),
  });

  res.json(updatedTask);
});

// DELETE /tasks/:id
app.delete('/tasks/:id', (req, res) => {
  const tasks = loadTasks();
  const index = tasks.findIndex((t) => String(t.id) === String(req.params.id));

  if (index === -1) {
    return res.status(404).json({ error: 'Тапсырма табылмады (Task not found)' });
  }

  const [deletedTask] = tasks.splice(index, 1);
  saveTasks(tasks);

  // Broadcast realtime event
  broadcast({
    type: 'task_update',
    action: 'delete',
    task: deletedTask,
    timestamp: new Date().toISOString(),
  });

  res.json(deletedTask);
});

// Create HTTP server
const server = http.createServer(app);

// WebSocket Server attached to the same HTTP server
const wss = new WebSocketServer({ server });

function broadcast(data, senderWs = null) {
  const payload = typeof data === 'string' ? data : JSON.stringify(data);
  wss.clients.forEach((client) => {
    if (client !== senderWs && client.readyState === WebSocket.OPEN) {
      client.send(payload);
    }
  });
}

wss.on('connection', (ws, req) => {
  console.log(`[WS] Client connected from ${req.socket.remoteAddress}`);

  // Send immediate welcome / ready packet
  ws.send(
    JSON.stringify({
      type: 'connection_ack',
      status: 'connected',
      message: 'UniTask Realtime WebSocket Connected',
      timestamp: new Date().toISOString(),
    })
  );

  ws.on('message', (message) => {
    try {
      const parsed = JSON.parse(message.toString());
      console.log('[WS] Received message:', parsed);

      // If client sends a task update, broadcast to other connected clients
      if (parsed.type === 'task_update') {
        broadcast(parsed, ws);
      }
    } catch (err) {
      console.error('[WS] Error processing message:', err.message);
    }
  });

  ws.on('close', () => {
    console.log('[WS] Client disconnected');
  });

  ws.on('error', (err) => {
    console.error('[WS] Socket error:', err.message);
  });
});

// Start listening
server.listen(PORT, () => {
  console.log(`===============================================`);
  console.log(`🚀 UniTask Production Server running on port ${PORT}`);
  console.log(`📡 REST API:   http://localhost:${PORT}/tasks`);
  console.log(`🔌 WebSocket:  ws://localhost:${PORT}`);
  console.log(`===============================================`);
});
