// Простой Express сервер для тестирования новой БД
const express = require('express');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);
const app = express();
app.use(express.json());

// Функция для выполнения SQL через docker exec
async function execSQL(query, params = []) {
  return new Promise((resolve, reject) => {
    // Экранируем параметры для безопасности
    let formattedQuery = query;
    params.forEach((param, index) => {
      const placeholder = `$${index + 1}`;
      const safeParam = param === null ? 'NULL' : `'${String(param).replace(/'/g, "''")}'`;
      formattedQuery = formattedQuery.replace(placeholder, safeParam);
    });

    const dockerCommand = `docker exec infra-postgres-1 psql -U postgres -d aic -t -c "${formattedQuery.replace(/"/g, '\\"')}"`;
    
    exec(dockerCommand, (error, stdout, stderr) => {
      if (error) {
        console.error('SQL Error:', error);
        reject(new Error(stderr || error.message));
        return;
      }
      
      // Парсим результат
      const lines = stdout.trim().split('\n').filter(line => line.trim());
      const rows = lines.map(line => {
        // Простой парсер для результатов PostgreSQL 
        const parts = line.split('|').map(s => s.trim());
        return parts;
      });
      
      resolve({ rows });
    });
  });
}

// CORS для мобильного приложения
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Privacy-by-design API server is running!',
    timestamp: new Date().toISOString()
  });
});

// Создание гостевого пользователя
app.post('/auth/guest', async (req, res) => {
  try {
    console.log('Creating guest user...');
    
    const userId = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
    
    const result = await execSQL(
      `INSERT INTO users (id, role, created_at, updated_at) 
       VALUES ($1, $2, NOW(), NOW()) 
       RETURNING id, role, created_at`,
      [userId, 'guest']
    );
    
    console.log('Guest user created:', result.rows);
    res.json({
      success: true,
      user: {
        id: userId,
        role: 'guest',
        created_at: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Error creating guest user:', error);
    res.status(500).json({ 
      error: 'Failed to create guest user',
      details: error.message 
    });
  }
});

// Регистрация нового пользователя
app.post('/auth/register', async (req, res) => {
  try {
    const { email, birth_date, country_code = 'CZ', locale = 'cs-CZ' } = req.body;
    
    if (!email || !birth_date) {
      return res.status(400).json({ error: 'Email and birth_date required' });
    }
    
    const userId = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
    
    const profileId = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
    
    // Создаем пользователя
    await execSQL(
      `INSERT INTO users (id, email, role, birth_date, country_code, created_at, updated_at) 
       VALUES ($1, $2, $3, $4, $5, NOW(), NOW())`,
      [userId, email, 'user', birth_date, country_code]
    );
    
    // Создаем профиль
    await execSQL(
      `INSERT INTO profiles (id, user_id, locale, created_at, updated_at) 
       VALUES ($1, $2, $3, NOW(), NOW())`,
      [profileId, userId, locale]
    );
    
    res.json({
      success: true,
      user: {
        id: userId,
        email,
        role: 'user',
        birth_date,
        country_code,
        profile: {
          id: profileId,
          locale
        }
      }
    });
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({ 
      error: 'Failed to register user',
      details: error.message 
    });
  }
});

// Получить всех пользователей
app.get('/users', async (req, res) => {
  try {
    const result = await execSQL('SELECT id, email, role, birth_date, country_code, created_at FROM users ORDER BY created_at DESC LIMIT 10');
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Создать чат сессию  
app.post('/chat/session', async (req, res) => {
  try {
    const { user_id } = req.body;
    
    if (!user_id) {
      return res.status(400).json({ error: 'user_id required' });
    }
    
    const sessionId = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
    
    await execSQL(
      `INSERT INTO chat_sessions (id, user_id, created_at, updated_at) 
       VALUES ($1, $2, NOW(), NOW())`,
      [sessionId, user_id]
    );
    
    res.json({
      success: true,
      session: {
        id: sessionId,
        user_id,
        created_at: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Error creating chat session:', error);
    res.status(500).json({ 
      error: 'Failed to create chat session',
      details: error.message 
    });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Privacy-by-design API server is running!' });
});

// Создание гостевого пользователя
app.post('/auth/guest', async (req, res) => {
  try {
    console.log('Creating guest user...');
    
    // Создаем пользователя
    const userResult = await pool.query(`
      INSERT INTO users (role, locale, birthdate, consent_version) 
      VALUES ($1, $2, $3, $4) 
      RETURNING *
    `, ['child', 'en-US', new Date('2010-01-01'), 1]);
    
    const user = userResult.rows[0];
    console.log('User created:', user);
    
    // Создаем согласие
    await pool.query(`
      INSERT INTO consents (user_id, consent_type, version, scope) 
      VALUES ($1, $2, $3, $4)
    `, [user.id, 'tos', 1, 'guest']);
    
    // Генерируем простой токен
    const token = `${user.id}.${Date.now().toString(36)}.guest`;
    
    res.json({
      success: true,
      user: {
        id: user.id,
        role: user.role,
        locale: user.locale,
        birthdate: user.birthdate,
        createdAt: user.created_at,
        isGuest: true,
      },
      token,
    });
  } catch (error) {
    console.error('Error creating guest user:', error);
    res.status(500).json({ error: error.message });
  }
});

// Создание пользователя
app.post('/auth/register', async (req, res) => {
  try {
    const { nick, ageGroup, locale, country } = req.body;
    
    // Конвертируем ageGroup в birthdate
    let birthdate;
    const currentYear = new Date().getFullYear();
    switch (ageGroup) {
      case '9-12':
        birthdate = new Date(currentYear - 11, 0, 1);
        break;
      case '13-15':
        birthdate = new Date(currentYear - 14, 0, 1);
        break;
      case '16-18':
        birthdate = new Date(currentYear - 17, 0, 1);
        break;
      default:
        return res.status(400).json({ error: 'Invalid age group' });
    }
    
    // Создаем пользователя
    const userResult = await pool.query(`
      INSERT INTO users (role, locale, birthdate, consent_version) 
      VALUES ($1, $2, $3, $4) 
      RETURNING *
    `, ['child', locale, birthdate, 1]);
    
    const user = userResult.rows[0];
    
    // Создаем согласие
    await pool.query(`
      INSERT INTO consents (user_id, consent_type, version, scope) 
      VALUES ($1, $2, $3, $4)
    `, [user.id, 'tos', 1, 'basic']);
    
    const token = `${user.id}.${Date.now().toString(36)}.user`;
    
    res.json({
      success: true,
      user: {
        id: user.id,
        role: user.role,
        locale: user.locale,
        birthdate: user.birthdate,
        createdAt: user.created_at,
      },
      token,
    });
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: error.message });
  }
});

// Получить всех пользователей (для тестирования)
app.get('/users', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT u.*, 
             COUNT(c.id) as consents_count
      FROM users u 
      LEFT JOIN consents c ON u.id = c.user_id 
      GROUP BY u.id 
      ORDER BY u.created_at DESC 
      LIMIT 10
    `);
    
    res.json({
      success: true,
      users: result.rows,
    });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: error.message });
  }
});

// Создание чат-сессии
app.post('/chat/session', async (req, res) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    
    const result = await pool.query(`
      INSERT INTO chat_sessions (user_id) 
      VALUES ($1) 
      RETURNING *
    `, [userId]);
    
    res.json({
      success: true,
      session: result.rows[0],
    });
  } catch (error) {
    console.error('Error creating chat session:', error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Privacy-by-design API server running on http://0.0.0.0:${PORT}`);
  console.log(`📊 Database: PostgreSQL with new schema`);
  console.log(`🔒 Features: UUID primary keys, GDPR compliance, minimal PII`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Shutting down server...');
  await pool.end();
  process.exit(0);
});