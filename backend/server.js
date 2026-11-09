const http = require('http');
const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');
const { WebSocketServer, WebSocket } = require('ws');

const app = express();
const PORT = process.env.PORT || 3000;
const DB_FILE = path.join(__dirname, 'tasks.json');
const USERS_FILE = path.join(__dirname, 'users.json');

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

// Helper to load users
function loadUsers() {
  try {
    if (!fs.existsSync(USERS_FILE)) {
      fs.writeFileSync(USERS_FILE, JSON.stringify([], null, 2), 'utf8');
      return [];
    }
    const data = fs.readFileSync(USERS_FILE, 'utf8');
    return JSON.parse(data);
  } catch (err) {
    console.error('Error loading users:', err);
    return [];
  }
}

// Helper to save users
function saveUsers(users) {
  try {
    fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2), 'utf8');
  } catch (err) {
    console.error('Error saving users:', err);
  }
}

// REST API Endpoints
app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime(), timestamp: new Date() });
});

// GET /users
app.get('/users', (req, res) => {
  const users = loadUsers().map(({ password, ...safeUser }) => safeUser);
  res.json(users);
});

// POST /auth/register
app.post('/auth/register', (req, res) => {
  const { fullName, university, email, password } = req.body || {};
  if (!fullName || !email || !password) {
    return res.status(400).json({ error: 'Барлық өрістерді толтырыңыз' });
  }
  const users = loadUsers();
  const normalizedEmail = String(email).trim().toLowerCase();
  const existingIdx = users.findIndex(
    (u) => String(u.email).toLowerCase() === normalizedEmail
  );

  const userRecord = {
    id: existingIdx !== -1 ? users[existingIdx].id : String(Date.now()),
    fullName: String(fullName).trim(),
    university: String(university || '').trim(),
    email: String(email).trim(),
    password: String(password),
    createdAt: new Date().toISOString(),
  };

  if (existingIdx !== -1) {
    users[existingIdx] = userRecord;
  } else {
    users.push(userRecord);
  }
  saveUsers(users);

  const { password: _, ...safeUser } = userRecord;
  res.status(201).json({ user: safeUser });
});

// POST /auth/login
app.post('/auth/login', (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'Email және құпиясөз қажет' });
  }
  const users = loadUsers();
  const normalizedEmail = String(email).trim().toLowerCase();
  const found = users.find(
    (u) => String(u.email).toLowerCase() === normalizedEmail
  );

  if (!found || found.password !== String(password)) {
    return res.status(401).json({ error: 'Email немесе құпиясөз қате' });
  }

  const { password: _, ...safeUser } = found;
  res.json({ user: safeUser });
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

  const isCompletedVal =
    req.body.isCompleted !== undefined
      ? req.body.isCompleted === true || req.body.isCompleted === 'true'
      : req.body.is_completed !== undefined
      ? req.body.is_completed === true || req.body.is_completed === 1 || req.body.is_completed === 'true'
      : index !== -1
      ? tasks[index].isCompleted
      : false;

  const updatedTask = {
    ...(index !== -1 ? tasks[index] : {}),
    ...req.body,
    id: String(req.params.id),
    isCompleted: isCompletedVal,
    updatedAt: new Date().toISOString(),
  };

  if (index === -1) {
    tasks.push(updatedTask);
  } else {
    tasks[index] = updatedTask;
  }
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
