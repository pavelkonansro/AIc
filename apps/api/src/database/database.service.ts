import { Injectable } from '@nestjs/common';
import { Pool } from 'pg';

@Injectable()
export class DatabaseService {
  private pool: Pool;

  constructor() {
    this.pool = new Pool({
      connectionString: process.env.DATABASE_URL,
    });
  }

  async query(text: string, params?: any[]) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(text, params);
      return result;
    } finally {
      client.release();
    }
  }

  // User operations
  async createUser(data: {
    role?: string;
    locale?: string;
    birthYear?: number;
    ageGroup?: string;
    consentVersion?: number;
  }) {
    const {
      role = 'child',
      locale = 'ru',
      birthYear = null,
      ageGroup = null,
      consentVersion = 1
    } = data;

    console.log('Creating user with data:', { role, locale, birthYear, ageGroup, consentVersion });

    try {
      const result = await this.query(
        `INSERT INTO users (role, locale, "birthYear", "ageGroup", "consentVersion")
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [role, locale, birthYear, ageGroup, consentVersion]
      );

      console.log('User created successfully:', result.rows[0]);
      return result.rows[0];
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  }

  async findUserById(id: string) {
    const result = await this.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
    return result.rows[0];
  }

  async getAllUsers() {
    const result = await this.query('SELECT * FROM users LIMIT 10');
    return result.rows;
  }

  async findUsers() {
    const result = await this.query('SELECT * FROM users');
    return result.rows;
  }

  // Consent operations
  async createConsent(data: {
    userId: string;
    consentType: string;
    version: number;
    scope?: string;
  }) {
    const result = await this.query(
      `INSERT INTO consents (user_id, consent_type, version, scope) 
       VALUES ($1, $2, $3, $4) 
       RETURNING *`,
      [data.userId, data.consentType, data.version, data.scope]
    );
    return result.rows[0];
  }

  // Chat operations
  async createChatSession(userId: string) {
    const result = await this.query(
      `INSERT INTO chat_sessions (user_id) 
       VALUES ($1) 
       RETURNING *`,
      [userId]
    );
    return result.rows[0];
  }

  async createChatMessage(data: {
    sessionId: string;
    role: string;
    content: string;
    safetyFlag?: string;
    metadata?: any;
  }) {
    const result = await this.query(
      `INSERT INTO chat_messages (session_id, role, content, safety_flag, metadata) 
       VALUES ($1, $2, $3, $4, $5) 
       RETURNING *`,
      [data.sessionId, data.role, data.content, data.safetyFlag, JSON.stringify(data.metadata)]
    );
    return result.rows[0];
  }

  async findChatSessionsByUserId(userId: string) {
    const result = await this.query(
      `SELECT cs.*, 
              (SELECT COUNT(*) FROM chat_messages cm WHERE cm.session_id = cs.id) as message_count
       FROM chat_sessions cs 
       WHERE cs.user_id = $1 
       ORDER BY cs.started_at DESC`,
      [userId]
    );
    return result.rows;
  }

  async findChatMessagesBySessionId(sessionId: string, limit = 50) {
    const result = await this.query(
      `SELECT * FROM chat_messages 
       WHERE session_id = $1 
       ORDER BY created_at ASC 
       LIMIT $2`,
      [sessionId, limit]
    );
    return result.rows;
  }

  async close() {
    await this.pool.end();
  }
}