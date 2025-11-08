import express from 'express';
import { pool } from './db.js';
import { v4 as randomUUID } from 'uuid';


const app = express();
app.use(express.json());


// X-Request-Id middleware (para ver balanceo en proxy)
app.use((req, res, next) => {
const reqId = req.header('X-Request-Id') || randomUUID();
res.setHeader('X-Request-Id', reqId);
req.requestId = reqId;
next();
});


app.get('/health', (_req, res) => {
res.json({ status: 'ok', hostname: process.env.HOSTNAME || 'unknown' });
});


app.get('/items', async (req, res) => {
try {
const { rows } = await pool.query('SELECT id, name, price FROM items ORDER BY id ASC');
res.json({ hostname: process.env.HOSTNAME, requestId: req.requestId, data: rows });
} catch (err) {
res.status(500).json({ error: err.message });
}
});


// Opcional: insertar (para probar persistencia rápido)
app.post('/items', async (req, res) => {
const { name, price } = req.body || {};
if (!name || price == null) return res.status(400).json({ error: 'name, price requeridos' });
try {
const { rows } = await pool.query(
'INSERT INTO items(name, price) VALUES($1, $2) RETURNING id, name, price',
[name, price]
);
res.status(201).json(rows[0]);
} catch (err) {
res.status(500).json({ error: err.message });
}
});


const port = Number(process.env.PORT || 3000);
app.listen(port, () => console.log(`API listening on ${port}`));
