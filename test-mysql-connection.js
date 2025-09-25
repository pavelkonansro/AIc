#!/usr/bin/env node

/**
 * Test MySQL connection to Beget database
 * Tests connection to konans6z_aic database
 */

const mysql = require('mysql2/promise');

// Database configuration
const dbConfig = {
  host: 'konans6z.beget.tech',  // Try with your domain first
  user: 'konans6z_aic',
  password: 'vbftyjkT1984$',
  database: 'konans6z_aic',
  charset: 'utf8mb4'
};

async function testConnection() {
  console.log('🔍 Testing MySQL connection to Beget...');
  console.log('📊 Config:', {
    host: dbConfig.host,
    user: dbConfig.user,
    database: dbConfig.database,
    password: '***hidden***'
  });

  let connection;
  try {
    // Test 1: Try with domain name
    console.log('\n1️⃣ Trying connection with domain name...');
    connection = await mysql.createConnection(dbConfig);
    
    console.log('✅ Connected to MySQL!');
    
    // Test basic query
    console.log('\n2️⃣ Testing basic query...');
    const [rows] = await connection.execute('SELECT VERSION() as version, DATABASE() as current_db, USER() as current_user');
    console.log('✅ Query successful:', rows[0]);
    
    // Test show tables
    console.log('\n3️⃣ Checking existing tables...');
    const [tables] = await connection.execute('SHOW TABLES');
    console.log(`✅ Found ${tables.length} tables:`, tables.map(t => Object.values(t)[0]));
    
    console.log('\n🎉 Connection test SUCCESSFUL!');
    console.log('📝 You can now run the schema creation script.');
    
  } catch (error) {
    console.log('❌ Connection failed with domain, trying localhost...');
    
    try {
      // Test 2: Try with localhost
      const localConfig = { ...dbConfig, host: 'localhost' };
      connection = await mysql.createConnection(localConfig);
      
      console.log('✅ Connected with localhost!');
      const [rows] = await connection.execute('SELECT VERSION() as version, DATABASE() as current_db');
      console.log('✅ Query successful:', rows[0]);
      
    } catch (localError) {
      console.error('❌ Both connection attempts failed:');
      console.error('Domain error:', error.message);
      console.error('Localhost error:', localError.message);
      console.log('\n💡 Possible solutions:');
      console.log('- Check if MySQL user has correct permissions');
      console.log('- Verify database name is exactly: konans6z_aic');
      console.log('- Check if remote connections are allowed');
      console.log('- Try connecting from Beget hosting environment');
    }
  } finally {
    if (connection) {
      await connection.end();
      console.log('🔌 Connection closed.');
    }
  }
}

// Install mysql2 if not installed
try {
  require('mysql2/promise');
  testConnection();
} catch (requireError) {
  console.log('📦 Installing mysql2 dependency...');
  const { execSync } = require('child_process');
  try {
    execSync('npm install mysql2', { stdio: 'inherit' });
    console.log('✅ mysql2 installed, retrying connection...');
    testConnection();
  } catch (installError) {
    console.error('❌ Failed to install mysql2:', installError.message);
    console.log('💡 Please run: npm install mysql2');
  }
}