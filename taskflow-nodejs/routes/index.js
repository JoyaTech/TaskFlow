const express = require('express');
const {
  getAllTasks,
  createTask,
  updateTask,
  deleteTask,
  getTaskById
} = require('../database');

const router = express.Router();

// Input validation helper
const validateTaskName = (name) => {
  return name && typeof name === 'string' && name.trim().length > 0;
};

// GET / - Render main page with all tasks
router.get('/', async (req, res) => {
  try {
    const tasks = await getAllTasks();
    res.render('index', { 
      title: 'TaskFlow - Modern Task Management',
      tasks: tasks || []
    });
  } catch (error) {
    console.error('Error fetching tasks:', error);
    res.status(500).render('error', {
      message: 'Error loading tasks',
      error: process.env.NODE_ENV === 'development' ? error : {}
    });
  }
});

// POST /tasks - Create a new task
router.post('/tasks', async (req, res) => {
  try {
    const { name } = req.body;

    // Validate input
    if (!validateTaskName(name)) {
      return res.status(400).json({
        success: false,
        error: 'Task name is required and must be a non-empty string'
      });
    }

    const task = await createTask(name.trim());
    res.status(201).json({
      success: true,
      task: task
    });
  } catch (error) {
    console.error('Error creating task:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create task'
    });
  }
});

// PATCH /tasks/:id - Update task completion status
router.patch('/tasks/:id', async (req, res) => {
  try {
    const taskId = parseInt(req.params.id);
    const { completed } = req.body;

    // Validate input
    if (isNaN(taskId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid task ID'
      });
    }

    if (typeof completed !== 'boolean') {
      return res.status(400).json({
        success: false,
        error: 'Completed status must be a boolean'
      });
    }

    // Check if task exists
    const existingTask = await getTaskById(taskId);
    if (!existingTask) {
      return res.status(404).json({
        success: false,
        error: 'Task not found'
      });
    }

    const updatedTask = await updateTask(taskId, completed);
    res.json({
      success: true,
      task: updatedTask
    });
  } catch (error) {
    console.error('Error updating task:', error);
    if (error.message === 'Task not found') {
      res.status(404).json({
        success: false,
        error: 'Task not found'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Failed to update task'
      });
    }
  }
});

// DELETE /tasks/:id - Delete a task
router.delete('/tasks/:id', async (req, res) => {
  try {
    const taskId = parseInt(req.params.id);

    // Validate input
    if (isNaN(taskId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid task ID'
      });
    }

    // Check if task exists
    const existingTask = await getTaskById(taskId);
    if (!existingTask) {
      return res.status(404).json({
        success: false,
        error: 'Task not found'
      });
    }

    await deleteTask(taskId);
    res.json({
      success: true,
      message: 'Task deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting task:', error);
    if (error.message === 'Task not found') {
      res.status(404).json({
        success: false,
        error: 'Task not found'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Failed to delete task'
      });
    }
  }
});

// GET /api/tasks - Get all tasks as JSON (for API consumers)
router.get('/api/tasks', async (req, res) => {
  try {
    const tasks = await getAllTasks();
    res.json({
      success: true,
      tasks: tasks || []
    });
  } catch (error) {
    console.error('Error fetching tasks:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch tasks'
    });
  }
});

module.exports = router;
