const express = require('express');
const path = require('path');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
const cookieParser = require('cookie-parser');

const app = express();
app.use(express.json());
app.use(cookieParser());

const {
  USERNAME = 'admin',
  PASSWORD = 'changeme',
  DB_NAME = 'appdb',
  DB_USER = 'app',
  PGDATA = '/var/lib/postgresql/data'
} = process.env;

const JWT_SECRET = PASSWORD;

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  user: DB_USER,
  password: PASSWORD,
  database: DB_NAME
});

function authMiddleware(req, res, next) {
  const token = req.cookies.token || (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload.sub;
    return next();
  } catch {
    return res.status(401).json({ error: 'Unauthorized' });
  }
}

app.post('/api/login', (req, res) => {
  const { username, password } = req.body || {};
  if (username === USERNAME && password === PASSWORD) {
    const token = jwt.sign({ sub: username }, JWT_SECRET, { expiresIn: '12h' });
    res.cookie('token', token, { httpOnly: true, sameSite: 'lax', maxAge: 12*60*60*1000 });
    return res.json({ ok: true, token });
  }
  return res.status(401).json({ error: 'Invalid credentials' });
});

app.get('/api/projects', authMiddleware, async (_req, res) => {
  const { rows } = await pool.query('SELECT id, name, created_at FROM projects ORDER BY id');
  res.json(rows);
});

app.post('/api/projects', authMiddleware, async (req, res) => {
  const { name } = req.body || {};
  if (!name) return res.status(400).json({ error: 'name required' });
  const { rows } = await pool.query(
    'INSERT INTO projects (name) VALUES ($1) RETURNING id, name, created_at',
    [name]
  );
  res.status(201).json(rows[0]);
});

app.get('/api/overview/tables', authMiddleware, async (_req, res) => {
  const tables = ['projects', 'tasks'];
  const data = {};
  for (const t of tables) {
    const { rows } = await pool.query(`SELECT * FROM ${t} ORDER BY 1`);
    data[t] = rows;
  }
  res.json(data);
});

app.use(express.static(path.join(__dirname, 'client_dist')));
app.get('*', (_req, res) => {
  res.sendFile(path.join(__dirname, 'client_dist', 'index.html'));
});

app.listen(3000, () => {
  console.log('Listening on port 3000');
});
