const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'taskflow.db');
const db = new sqlite3.Database(dbPath);

const initializeDatabase = () => {
  const createTableQuery = `
    CREATE TABLE IF NOT EXISTS tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      completed BOOLEAN DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `;

  db.run(createTableQuery, (err) => {
    if (err) {
      console.error('Error creating tasks table:', err.message);
    } else {
      console.log('Database initialized successfully');
    }
  });
};

const getAllTasks = () => {
  return new Promise((resolve, reject) => {
    const query = 'SELECT * FROM tasks ORDER BY created_at DESC';
    db.all(query, [], (err, rows) => {
      if (err) {
        reject(err);
      } else {
        resolve(rows);
      }
    });
  });
};

const createTask = (name) => {
  return new Promise((resolve, reject) => {
    const query = 'INSERT INTO tasks (name) VALUES (?)';
    db.run(query, [name], function (err) {
      if (err) {
        reject(err);
      } else {
        resolve({ id: this.lastID, name, completed: false });
      }
    });
  });
};

const updateTask = (id, completed) => {
  return new Promise((resolve, reject) => {
    const query = 'UPDATE tasks SET completed = ? WHERE id = ?';
    db.run(query, [completed, id], function (err) {
      if (err) {
        reject(err);
      } else if (this.changes === 0) {
        reject(new Error('Task not found'));
      } else {
        resolve({ id, completed });
      }
    });
  });
};

const deleteTask = (id) => {
  return new Promise((resolve, reject) => {
    const query = 'DELETE FROM tasks WHERE id = ?';
    db.run(query, [id], function (err) {
      if (err) {
        reject(err);
      } else if (this.changes === 0) {
        reject(new Error('Task not found'));
      } else {
        resolve({ id });
      }
    });
  });
};

const getTaskById = (id) => {
  return new Promise((resolve, reject) => {
    const query = 'SELECT * FROM tasks WHERE id = ?';
    db.get(query, [id], (err, row) => {
      if (err) {
        reject(err);
      } else {
        resolve(row);
      }
    });
  });
};

module.exports = {
  initializeDatabase,
  getAllTasks,
  createTask,
  updateTask,
  deleteTask,
  getTaskById
};
