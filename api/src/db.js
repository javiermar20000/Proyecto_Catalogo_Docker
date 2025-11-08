import pkg from 'pg';
import fs from 'fs';


const { Pool } = pkg;


function resolveDbPassword() {
if (process.env.DB_PASSWORD) return process.env.DB_PASSWORD;
const file = process.env.DB_PASSWORD_FILE || '/run/secrets/db_password';
try { return fs.readFileSync(file, 'utf8').trim(); } catch (_) { return undefined; }
}


export const pool = new Pool({
host: process.env.DB_HOST || 'localhost',
port: Number(process.env.DB_PORT || 5432),
user: process.env.DB_USER || 'catalogo',
database: process.env.DB_NAME || 'catalogo',
password: resolveDbPassword(),
ssl: false
});