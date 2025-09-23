import { Controller, Get, Post, Body, Res } from '@nestjs/common';
import { Response } from 'express';
import { readFileSync } from 'fs';
import { join } from 'path';
import { PrismaService } from '../prisma/prisma.service';
import { ChatService } from '../chat/chat.service';

@Controller('test')
export class TestController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly chatService: ChatService,
  ) {}

  @Get('websocket.html')
  getWebSocketTest(@Res() res: Response) {
    try {
      const htmlPath = join(__dirname, '..', 'public', 'test-websocket.html');
      const htmlContent = readFileSync(htmlPath, 'utf8');

      res.setHeader('Content-Type', 'text/html');
      res.send(htmlContent);
    } catch (error) {
      res.status(404).json({ message: 'Test file not found' });
    }
  }

  @Post('create-user')
  async createTestUser() {
    try {
      const user = await this.prisma.user.create({
        data: {
          role: 'child',
          locale: 'cs-CZ',
          birthYear: 2010, // возраст 13-15 лет
          ageGroup: 'teen',
          consentVersion: 1,
        },
      });

      return {
        userId: user.id,
        role: user.role,
        birthYear: user.birthYear,
        ageGroup: user.ageGroup,
      };
    } catch (error) {
      console.error('Ошибка создания тестового пользователя:', error);
      throw new Error('Failed to create test user');
    }
  }

  @Post('create-session')
  async createTestSession(@Body() body: { userId: string }) {
    try {
      const { userId } = body;

      if (!userId) {
        throw new Error('userId is required');
      }

      const sessionData = await this.chatService.createSession(userId);

      return {
        sessionId: sessionData.sessionId,
        startedAt: sessionData.startedAt,
        status: sessionData.status,
      };
    } catch (error) {
      console.error('Ошибка создания тестовой сессии:', error);
      throw new Error('Failed to create test session');
    }
  }

  @Get('cleanup')
  async cleanupTestData() {
    try {
      // Удаляем тестовых пользователей (старше 1 часа)
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

      const deletedUsers = await this.prisma.user.deleteMany({
        where: {
          role: 'child',
          createdAt: {
            lt: oneHourAgo,
          },
        },
      });

      return {
        message: 'Test data cleaned up',
        deletedUsers: deletedUsers.count,
      };
    } catch (error) {
      console.error('Ошибка очистки тестовых данных:', error);
      throw new Error('Failed to cleanup test data');
    }
  }
}
