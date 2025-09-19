import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService) {}

  async createSession(userId: string) {
    const session = await this.prisma.chatSession.create({
      data: {
        userId,
        status: 'active',
      },
    });

    return {
      sessionId: session.id,
      startedAt: session.startedAt,
      status: session.status,
    };
  }

  async getSession(sessionId: string) {
    const session = await this.prisma.chatSession.findUnique({
      where: { id: sessionId },
      include: {
        user: {
          select: {
            id: true,
            nick: true,
            ageGroup: true,
          },
        },
      },
    });

    if (!session) {
      throw new NotFoundException('Сессия не найдена');
    }

    return {
      id: session.id,
      userId: session.userId,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      status: session.status,
      user: session.user,
    };
  }

  async getMessages(sessionId: string, limit = 50) {
    const messages = await this.prisma.chatMessage.findMany({
      where: { sessionId },
      orderBy: { createdAt: 'asc' },
      take: limit,
    });

    return messages.map(message => ({
      id: message.id,
      role: message.role,
      content: message.content,
      safetyFlag: message.safetyFlag,
      createdAt: message.createdAt,
    }));
  }

  async addMessage(
    sessionId: string,
    role: 'user' | 'assistant' | 'system',
    content: string,
    safetyFlag?: string,
  ) {
    const message = await this.prisma.chatMessage.create({
      data: {
        sessionId,
        role,
        content,
        safetyFlag,
      },
    });

    // Логируем для анализа безопасности
    if (safetyFlag && safetyFlag !== 'safe') {
      await this.logSafetyEvent(sessionId, content, safetyFlag);
    }

    return message;
  }

  async endSession(sessionId: string) {
    const session = await this.prisma.chatSession.update({
      where: { id: sessionId },
      data: {
        status: 'ended',
        endedAt: new Date(),
      },
    });

    return {
      sessionId: session.id,
      endedAt: session.endedAt,
      status: session.status,
    };
  }

  async getUserSessions(userId: string, limit = 10) {
    const sessions = await this.prisma.chatSession.findMany({
      where: { userId },
      orderBy: { startedAt: 'desc' },
      take: limit,
      include: {
        _count: {
          select: { messages: true },
        },
      },
    });

    return sessions.map(session => ({
      id: session.id,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      status: session.status,
      messageCount: session._count.messages,
    }));
  }

  private async logSafetyEvent(
    sessionId: string,
    content: string,
    flag: string,
  ) {
    try {
      await this.prisma.safetyLog.create({
        data: {
          sessionId,
          content,
          flag,
          reason: `Automated detection: ${flag}`,
          action: flag === 'crisis_detected' ? 'warning' : 'none',
        },
      });
    } catch (error) {
      console.error('Ошибка записи лога безопасности:', error);
    }
  }
}


