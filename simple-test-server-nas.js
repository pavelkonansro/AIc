const express = require('express');
const { Pool } = require('pg');
const Redis = require('redis');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(cors({
  origin: true, // Разрешаем все origins для тестирования
  credentials: true
}));

// Подключение к PostgreSQL через переменные среды Docker
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Подключение к Redis
let redisClient;
try {
  redisClient = Redis.createClient({ url: process.env.REDIS_URL });
  redisClient.on('error', (err) => console.log('Redis Client Error:', err));
  redisClient.connect();
} catch (error) {
  console.warn('Redis не подключен:', error.message);
}

// Утилита для генерации UUID (простая версия для NAS)
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

// Обработка ошибок БД
async function safeQuery(query, params = []) {
  try {
    const result = await pool.query(query, params);
    return result;
  } catch (error) {
    console.error('Database error:', error.message);
    throw error;
  }
}

// === МАРШРУТЫ API ===

// Health check
app.get('/health', async (req, res) => {
  try {
    // Проверяем подключение к БД
    const dbResult = await safeQuery('SELECT 1 as status');
    
    // Проверяем Redis (если доступен)
    let redisStatus = 'disconnected';
    if (redisClient && redisClient.isOpen) {
      await redisClient.ping();
      redisStatus = 'connected';
    }
    
    res.json({
      status: 'OK',
      message: 'AIc NAS Test Server is running!',
      timestamp: new Date().toISOString(),
      environment: 'nas-development',
      services: {
        database: 'connected',
        redis: redisStatus,
        api: 'running'
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Создание guest пользователя
app.post('/auth/guest', async (req, res) => {
  try {
    const guestId = generateUUID();
    
    const query = `
      INSERT INTO users (id, role, "createdAt", "updatedAt") 
      VALUES ($1, $2, NOW(), NOW()) 
      RETURNING id, role, "createdAt"
    `;
    
    const result = await safeQuery(query, [guestId, 'guest']);
    const user = result.rows[0];
    
    // Кэшируем в Redis если доступен
    if (redisClient && redisClient.isOpen) {
      await redisClient.setEx(`user:${user.id}`, 3600, JSON.stringify(user));
    }
    
    res.json({
      userId: user.id,
      role: user.role,
      createdAt: user.createdAt,
      sessionToken: `guest_${Date.now()}_${user.id.slice(0, 8)}`,
      message: 'Guest user created successfully'
    });
    
  } catch (error) {
    console.error('Error creating guest user:', error);
    res.status(500).json({
      error: 'Failed to create guest user',
      details: error.message
    });
  }
});

// Регистрация пользователя
app.post('/auth/signup', async (req, res) => {
  try {
    const { birthYear, ageGroup = 'teen', locale = 'cs-CZ' } = req.body;
    
    if (!birthYear) {
      return res.status(400).json({ error: 'birthYear is required' });
    }
    
    const userId = generateUUID();
    
    const query = `
      INSERT INTO users (id, role, "birthYear", "ageGroup", locale, "createdAt", "updatedAt") 
      VALUES ($1, $2, $3, $4, $5, NOW(), NOW()) 
      RETURNING id, role, "birthYear", "ageGroup", locale, "createdAt"
    `;
    
    const result = await safeQuery(query, [userId, 'child', birthYear, ageGroup, locale]);
    const user = result.rows[0];
    
    res.json({
      userId: user.id,
      role: user.role,
      birthYear: user.birthYear,
      ageGroup: user.ageGroup,
      locale: user.locale,
      createdAt: user.createdAt,
      message: 'User registered successfully'
    });
    
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({
      error: 'Failed to register user',
      details: error.message
    });
  }
});

// Получение пользователя
app.get('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Сначала проверяем Redis кэш
    if (redisClient && redisClient.isOpen) {
      const cached = await redisClient.get(`user:${id}`);
      if (cached) {
        return res.json({
          ...JSON.parse(cached),
          source: 'cache'
        });
      }
    }
    
    const query = `
      SELECT id, role, "birthYear", "ageGroup", locale, "createdAt", "updatedAt"
      FROM users 
      WHERE id = $1
    `;
    
    const result = await safeQuery(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = result.rows[0];
    
    // Кэшируем результат
    if (redisClient && redisClient.isOpen) {
      await redisClient.setEx(`user:${id}`, 3600, JSON.stringify(user));
    }
    
    res.json({
      ...user,
      source: 'database'
    });
    
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({
      error: 'Failed to fetch user',
      details: error.message
    });
  }
});

// Создание чат сессии
app.post('/chat/session', async (req, res) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    
    const sessionId = generateUUID();
    
    const query = `
      INSERT INTO chat_sessions (id, "userId", status, "startedAt") 
      VALUES ($1, $2, $3, NOW()) 
      RETURNING id, "userId", status, "startedAt"
    `;
    
    const result = await safeQuery(query, [sessionId, userId, 'active']);
    const session = result.rows[0];
    
    res.json({
      sessionId: session.id,
      userId: session.userId,
      status: session.status,
      startedAt: session.startedAt,
      message: 'Chat session created successfully'
    });
    
  } catch (error) {
    console.error('Error creating chat session:', error);
    res.status(500).json({
      error: 'Failed to create chat session',
      details: error.message
    });
  }
});

// Информация о API
app.get('/api-info', (req, res) => {
  res.json({
    name: 'AIc NAS Test API',
    version: '1.0.0',
    environment: 'nas-development',
    description: 'Simplified API server running on Synology NAS for testing',
    endpoints: {
      health: 'GET /health',
      auth: {
        guest: 'POST /auth/guest',
        signup: 'POST /auth/signup'
      },
      users: 'GET /users/:id',
      chat: 'POST /chat/session'
    },
    services: {
      database: 'PostgreSQL 15',
      cache: redisClient && redisClient.isOpen ? 'Redis 7' : 'Not available',
      platform: 'Synology NAS DS218'
    }
  });
});

// Корневой маршрут
app.get('/', (req, res) => {
  res.redirect('/api-info');
});

// Обработка ошибок
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

// 404 для неизвестных маршрутов
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl
  });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Received SIGTERM, shutting down gracefully...');
  
  if (redisClient && redisClient.isOpen) {
    await redisClient.quit();
  }
  
  await pool.end();
  process.exit(0);
});

// Запуск сервера
app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 AIc NAS Test API server running on http://0.0.0.0:${port}`);
  console.log(`🏠 Running on Synology NAS DS218`);
  console.log(`📊 Database: ${process.env.DATABASE_URL?.replace(/:[^:@]*@/, ':****@')}`);
  console.log(`🔄 Redis: ${process.env.REDIS_URL || 'Not configured'}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
});