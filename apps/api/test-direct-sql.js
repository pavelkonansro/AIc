// Тест нового DatabaseService
const { Pool } = require('pg');

async function testDirectSQL() {
  // Используем IP контейнера вместо localhost
  const pool = new Pool({
    connectionString: 'postgresql://postgres:postgres@172.20.0.3:5432/aic'
  });

  try {
    console.log('Тестирую прямое подключение к PostgreSQL...');
    
    // Тест подключения
    const client = await pool.connect();
    console.log('✅ Подключение установлено');
    
    // Тест создания пользователя
    const result = await client.query(`
      INSERT INTO users (role, locale, birthdate, consent_version) 
      VALUES ($1, $2, $3, $4) 
      RETURNING *
    `, ['child', 'ru', new Date('2010-01-01'), 1]);
    
    console.log('✅ Пользователь создан через прямой SQL:', result.rows[0]);
    
    // Тест чтения пользователей
    const users = await client.query('SELECT * FROM users ORDER BY created_at DESC LIMIT 3');
    console.log('✅ Последние пользователи:', users.rows);
    
    client.release();
  } catch (error) {
    console.error('❌ Ошибка:', error.message);
  } finally {
    await pool.end();
  }
}

testDirectSQL();