#!/usr/bin/env node

/**
 * Simple MySQL connection test for Beget hosting
 * Upload this file to test database connectivity from inside Beget
 */

const mysql = require('mysql2/promise');

// Database configuration for Beget internal network
const dbConfig = {
  host: 'localhost',           // Inside Beget use localhost
  user: 'konans6z_aic',
  password: 'vbftyjkT1984$',
  database: 'konans6z_aic',
  charset: 'utf8mb4',
  connectTimeout: 10000,
  acquireTimeout: 10000
};

async function testConnection() {
  console.log('🔍 Testing MySQL connection on Beget hosting...');
  console.log('📊 Config:', {
    host: dbConfig.host,
    user: dbConfig.user,
    database: dbConfig.database
  });

  let connection;
  try {
    console.log('\n1️⃣ Connecting to MySQL...');
    connection = await mysql.createConnection(dbConfig);
    console.log('✅ Connected to MySQL successfully!');
    
    console.log('\n2️⃣ Testing basic query...');
    const [versionRows] = await connection.execute('SELECT VERSION() as version, DATABASE() as current_db, USER() as current_user');
    console.log('✅ MySQL Info:', versionRows[0]);
    
    console.log('\n3️⃣ Checking existing tables...');
    const [tables] = await connection.execute('SHOW TABLES');
    console.log(`📋 Found ${tables.length} existing tables:`);
    tables.forEach(table => console.log(`  - ${Object.values(table)[0]}`));
    
    console.log('\n4️⃣ Testing table creation (just a test table)...');
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS connection_test (
        id INT AUTO_INCREMENT PRIMARY KEY,
        test_message VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Test table created successfully');
    
    console.log('\n5️⃣ Testing data insertion...');
    const testMessage = `Connection test at ${new Date().toISOString()}`;
    await connection.execute('INSERT INTO connection_test (test_message) VALUES (?)', [testMessage]);
    console.log('✅ Test data inserted');
    
    console.log('\n6️⃣ Testing data retrieval...');
    const [testRows] = await connection.execute('SELECT * FROM connection_test ORDER BY created_at DESC LIMIT 3');
    console.log('✅ Retrieved test data:', testRows);
    
    console.log('\n🎉 ALL TESTS PASSED!');
    console.log('✅ Database is ready for AIc application schema creation');
    console.log('📝 Next step: Run create-mysql-schema.sql');
    
  } catch (error) {
    console.error('\n❌ Connection test failed:', error.message);
    console.error('📋 Error details:', {
      code: error.code,
      errno: error.errno,
      sqlMessage: error.sqlMessage
    });
    
    console.log('\n💡 Troubleshooting:');
    console.log('1. Verify database credentials in Beget control panel');
    console.log('2. Make sure database user has all privileges');
    console.log('3. Check if database exists: konans6z_aic');
    console.log('4. Try running this script from Beget hosting environment');
  } finally {
    if (connection) {
      await connection.end();
      console.log('🔌 MySQL connection closed');
    }
  }
}

// Run the test
testConnection().catch(console.error);