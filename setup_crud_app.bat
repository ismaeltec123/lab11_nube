@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: 1. Instalar Node.js si no existe
where node >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
    echo Instalando Node.js...
    powershell -Command "Invoke-WebRequest -Uri https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi -OutFile nodejs.msi"
    msiexec /i nodejs.msi /quiet
    del nodejs.msi
) ELSE (
    echo Node.js ya está instalado.
)

:: 2. Crear carpeta del proyecto
set FOLDER=crud-app
mkdir %FOLDER%
cd %FOLDER%

:: 3. package.json
echo { > package.json
echo   "name": "crud-app", >> package.json
echo   "version": "1.0.0", >> package.json
echo   "main": "app.js", >> package.json
echo   "scripts": { "start": "node app.js" }, >> package.json
echo   "dependencies": { >> package.json
echo     "body-parser": "^1.20.2", >> package.json
echo     "ejs": "^3.1.9", >> package.json
echo     "express": "^4.18.2", >> package.json
echo     "method-override": "^3.0.0", >> package.json
echo     "sqlite3": "^5.1.6" >> package.json
echo   } >> package.json
echo } >> package.json

:: 4. Instalar dependencias
call npm install

:: 5. Estructura de carpetas
mkdir models
mkdir routes
mkdir views
mkdir public

:: 6. Crear app.js
> app.js (
echo const express = require('express');
echo const app = express();
echo const bodyParser = require('body-parser');
echo const methodOverride = require('method-override');
echo const os = require('os');
echo const db = require('./models/db');
echo const taskRoutes = require('./routes/tasks');
echo app.use(bodyParser.urlencoded({ extended: false }));
echo app.use(methodOverride('_method'));
echo app.use(express.static('public'));
echo app.set('view engine', 'ejs');
echo app.use('/', taskRoutes);
echo const PORT = 3000;
echo app.listen(PORT, '0.0.0.0', () => {
echo     console.log(`Servidor corriendo en http://0.0.0.0:\${PORT}`);
echo });
)

:: 7. models/db.js
> models\db.js (
echo const sqlite3 = require('sqlite3').verbose();
echo const db = new sqlite3.Database('./db.sqlite');
echo db.serialize(() => {
echo     db.run("CREATE TABLE IF NOT EXISTS tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT);");
echo });
echo module.exports = db;
)

:: 8. routes/tasks.js
> routes\tasks.js (
echo const express = require('express');
echo const router = express.Router();
echo const db = require('../models/db');
echo router.get('/', (req, res) => {
echo     db.all("SELECT * FROM tasks", [], (err, rows) => {
echo         res.render('index', { tasks: rows });
echo     });
echo });
echo router.get('/new', (req, res) => {
echo     res.render('form', { task: null });
echo });
echo router.post('/', (req, res) => {
echo     db.run("INSERT INTO tasks (title, description) VALUES (?, ?)", [req.body.title, req.body.description], () => {
echo         res.redirect('/');
echo     });
echo });
echo router.get('/:id/edit', (req, res) => {
echo     db.get("SELECT * FROM tasks WHERE id = ?", [req.params.id], (err, row) => {
echo         res.render('form', { task: row });
echo     });
echo });
echo router.put('/:id', (req, res) => {
echo     db.run("UPDATE tasks SET title = ?, description = ? WHERE id = ?", [req.body.title, req.body.description, req.params.id], () => {
echo         res.redirect('/');
echo     });
echo });
echo router.delete('/:id', (req, res) => {
echo     db.run("DELETE FROM tasks WHERE id = ?", [req.params.id], () => {
echo         res.redirect('/');
echo     });
echo });
echo module.exports = router;
)

:: 9. views/index.ejs
> views\index.ejs (
echo ^<!DOCTYPE html^>
echo ^<html lang="es"^>
echo ^<head^>^<title^>CRUD^</title^>^</head^>
echo ^<body^>
echo ^<h1^>Tareas^</h1^>
echo ^<a href="/new"^>Nueva tarea^</a^>
echo ^<ul^>
echo <% tasks.forEach(task => { %>
echo ^<li^>
echo ^<strong^><%%= task.title %>^</strong^> - <%%= task.description %>
echo ^<a href="/<%%= task.id %>/edit"^>Editar^</a^>
echo ^<form action="/<%%= task.id %>?_method=DELETE" method="POST" style="display:inline;"^>
echo ^<button type="submit"^>Eliminar^</button^>
echo ^</form^>
echo ^</li^>
echo <% }) %>
echo ^</ul^>
echo ^</body^>
echo ^</html^>
)

:: 10. views/form.ejs
> views\form.ejs (
echo ^<!DOCTYPE html^>
echo ^<html lang="es"^>
echo ^<head^>^<title^><%%= task ? 'Editar' : 'Nueva' %> tarea^</title^>^</head^>
echo ^<body^>
echo ^<h1^><%%= task ? 'Editar' : 'Nueva' %> tarea^</h1^>
echo ^<form action="/<%%= task ? task.id + '?_method=PUT' : '' %>" method="POST"^>
echo ^<input type="text" name="title" placeholder="Título" value="<%%= task ? task.title : '' %>" required /^>
echo ^<textarea name="description" placeholder="Descripción"^><%%= task ? task.description : '' %>^</textarea^>
echo ^<button type="submit"^>Guardar^</button^>
echo ^</form^>
echo ^</body^>
echo ^</html^>
)

:: 11. Configurar firewall de Windows para permitir puerto 3000
netsh advfirewall firewall add rule name="Node.js Port 3000" dir=in action=allow protocol=TCP localport=3000

:: 12. Lanzar la app
start "" http://localhost:3000
call npm start

ENDLOCAL
