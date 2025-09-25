#!/usr/bin/env node

/**
 * AIc API Server for Beget Hosting
 * Production-ready Express server with MySQL support
 * Privacy-by-design architecture for teen users
 */

const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(cors({
  origin: ['http://localhost:3000', 'https://konans6z.beget.tech'], // Updated with your actual domain
  credentials: true
}));

// MySQL Connection Pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'aic_app',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  charset: 'utf8mb4'
});

// Database helper functions
async function executeQuery(query, params = []) {
  try {
    const [rows] = await pool.execute(query, params);
    return rows;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
}

// Calculate age group
function calculateAgeGroup(birthDate) {
  const today = new Date();
  const birth = new Date(birthDate);
  const age = today.getFullYear() - birth.getFullYear();
  
  if (age < 13) return '9-12';
  if (age < 16) return '13-15';
  return '16-18';
}

// Routes

// Health check
app.get('/health', async (req, res) => {
  try {
    // Test database connection
    await executeQuery('SELECT 1');
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: 'connected',
      server: 'beget-production'
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Create guest user (for testing)
app.post('/auth/guest', async (req, res) => {
  try {
    const guestId = uuidv4();
    const now = new Date();
    
    // Create guest user
    await executeQuery(`
      INSERT INTO users (id, email, username, is_guest, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `, [guestId, `guest-${guestId}@temp.com`, `Guest-${guestId.slice(0, 8)}`, true, now, now]);

    res.json({
      success: true,
      user: {
        id: guestId,
        username: `Guest-${guestId.slice(0, 8)}`,
        isGuest: true
      },
      message: 'Guest user created successfully'
    });
  } catch (error) {
    console.error('Guest creation error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create guest user',
      details: error.message
    });
  }
});

// Register new user
app.post('/auth/register', async (req, res) => {
  try {
    const { email, username, password, birthDate, country = 'CZ' } = req.body;
    
    if (!email || !username || !password || !birthDate) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: email, username, password, birthDate'
      });
    }

    // Check if user already exists
    const existingUser = await executeQuery(
      'SELECT id FROM users WHERE email = ? OR username = ?',
      [email, username]
    );
    
    if (existingUser.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'User with this email or username already exists'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = uuidv4();
    const now = new Date();
    const ageGroup = calculateAgeGroup(birthDate);
    
    // Create user
    await executeQuery(`
      INSERT INTO users (id, email, username, password_hash, is_guest, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [userId, email, username, hashedPassword, false, now, now]);
    
    // Create profile
    await executeQuery(`
      INSERT INTO profiles (id, user_id, age_group, birth_date, country, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [uuidv4(), userId, ageGroup, birthDate, country, now, now]);

    res.json({
      success: true,
      user: {
        id: userId,
        email,
        username,
        ageGroup
      },
      message: 'User registered successfully'
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to register user',
      details: error.message
    });
  }
});

// Get user info
app.get('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const users = await executeQuery(`
      SELECT u.id, u.email, u.username, u.is_guest, u.created_at,
             p.age_group, p.country
      FROM users u
      LEFT JOIN profiles p ON u.id = p.user_id
      WHERE u.id = ?
    `, [id]);
    
    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }
    
    const user = users[0];
    res.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        isGuest: user.is_guest,
        ageGroup: user.age_group,
        country: user.country,
        createdAt: user.created_at
      }
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get user info',
      details: error.message
    });
  }
});

// Get database tables (for debugging)
app.get('/debug/tables', async (req, res) => {
  try {
    const tables = await executeQuery(`
      SELECT TABLE_NAME, TABLE_ROWS, CREATE_TIME
      FROM information_schema.TABLES 
      WHERE TABLE_SCHEMA = DATABASE()
      ORDER BY TABLE_NAME
    `);
    
    res.json({
      success: true,
      database: process.env.DB_NAME || 'aic_app',
      tables: tables.map(table => ({
        name: table.TABLE_NAME,
        rows: table.TABLE_ROWS,
        created: table.CREATE_TIME
      }))
    });
  } catch (error) {
    console.error('Tables debug error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get tables info',
      details: error.message
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    details: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    path: req.originalUrl,
    method: req.method
  });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing server gracefully...');
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, closing server gracefully...');
  await pool.end();
  process.exit(0);
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 AIc API Server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🎯 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🗄️ Database: ${process.env.DB_NAME || 'aic_app'}`);
});

module.exports = app;