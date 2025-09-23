import { Controller, Get, Res } from '@nestjs/common';
import { Response } from 'express';
import { readFileSync } from 'fs';
import { join } from 'path';

@Controller()
export class AppController {
  constructor() {}

  @Get()
  getDashboard(@Res() res: Response) {
    try {
      const htmlPath = join(__dirname, 'public', 'index.html');
      const htmlContent = readFileSync(htmlPath, 'utf8');

      res.setHeader('Content-Type', 'text/html');
      res.send(htmlContent);
    } catch (error) {
      // Fallback to JSON if HTML file not found
      res.json({
        name: 'AIc API',
        version: '1.0.0',
        description: 'AI companion for teens - Backend API',
        status: 'running',
        timestamp: new Date().toISOString(),
        endpoints: {
          swagger: '/api',
          websocket: '/chat (Socket.IO)',
          auth: '/auth/signup, /auth/guest',
          chat: '/chat/session',
          sos: '/sos/resources',
          test: '/test/websocket.html'
        },
        services: {
          database: 'PostgreSQL',
          redis: 'Redis',
          ai: 'LM Studio (localhost:1234)'
        }
      });
    }
  }

  @Get('api-info')
  getApiInfo() {
    return {
      name: 'AIc API',
      version: '1.0.0',
      description: 'AI companion for teens - Backend API',
      status: 'running',
      timestamp: new Date().toISOString(),
      endpoints: {
        swagger: '/api',
        websocket: '/chat (Socket.IO)',
        auth: '/auth/signup, /auth/guest',
        chat: '/chat/session',
        sos: '/sos/resources',
        test: '/test/websocket.html'
      },
      services: {
        database: 'PostgreSQL',
        redis: 'Redis',
        ai: 'LM Studio (localhost:1234)'
      }
    };
  }

  @Get('health')
  async getHealthCheck() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      services: {
        api: 'healthy',
        database: 'healthy', // TODO: Add DB health check
        redis: 'healthy' // TODO: Add Redis health check
      }
    };
  }
}