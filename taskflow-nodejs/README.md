# TaskFlow - Modern Task Management Application

A secure, robust, and maintainable task management application built with modern Node.js and Express following current best practices.

## Features

- **Modern Node.js/Express**: Built with the latest stable versions
- **RESTful API**: Proper HTTP methods and status codes
- **SQLite Database**: Persistent file-based storage
- **Responsive UI**: Clean interface with real-time updates
- **Input Validation**: Comprehensive server-side validation
- **Error Handling**: Proper error responses and user feedback
- **Development Tools**: ESLint, Prettier, and Nodemon configured

## API Endpoints

- `GET /` - Main page with task list
- `POST /tasks` - Create a new task
- `PATCH /tasks/:id` - Update task completion status
- `DELETE /tasks/:id` - Delete a task
- `GET /api/tasks` - Get all tasks as JSON

## Prerequisites

- Node.js v16 or newer
- npm (comes with Node.js)

## Installation & Setup

1. Navigate to the project directory:
   ```bash
   cd taskflow-nodejs
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

4. Open your browser and visit: `http://localhost:3000`

## Development Scripts

- `npm start` - Start the production server
- `npm run dev` - Start the development server with nodemon
- `npm run lint` - Run ESLint for code quality checks
- `npm run lint:fix` - Fix ESLint issues automatically
- `npm run format` - Format code with Prettier
- `npm run format:check` - Check if code formatting is correct

## Project Structure

```
taskflow-nodejs/
├── app.js              # Main server setup
├── database.js         # SQLite database operations
├── routes/
│   └── index.js        # RESTful API routes
├── views/
│   ├── index.hbs       # Main page template
│   └── error.hbs       # Error page template
├── package.json        # Dependencies and scripts
├── .eslintrc.js        # ESLint configuration
├── .prettierrc         # Prettier configuration
└── README.md           # This file
```

## Database Schema

The SQLite database (`taskflow.db`) contains a single `tasks` table:

```sql
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  completed BOOLEAN DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## Key Improvements from Legacy Version

- **Modern Dependencies**: Updated to Express 4.x with latest security patches
- **Persistent Storage**: SQLite database replaces in-memory arrays
- **RESTful Design**: Proper HTTP methods instead of POST-only operations
- **Unique IDs**: Auto-incrementing IDs replace string-based task identification
- **Input Validation**: Server-side validation with proper error responses
- **Modern JavaScript**: ES6+ features, const/let instead of var
- **Development Workflow**: ESLint, Prettier, and Nodemon for better DX
- **Dynamic UI**: Client-side updates without page reloads
- **Error Handling**: Comprehensive error handling with user-friendly messages

## License

MIT License - see LICENSE file for details
