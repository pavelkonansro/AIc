import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AiService, ChatMessage, ChatResponse } from '../ai/ai.service';
import { NotificationsService } from '../notifications/notifications.service';
// Временно используем локальные импорты
// import { SYSTEM_POLICY, CRISIS_RESPONSE_TEMPLATES, SafetyChecker } from '@aic/safety';

// Временные константы для тестирования
const SYSTEM_POLICY = `
Ты AIc, дружелюбный AI-компаньон в виде сенбернара для подростков 9-18 лет.

ОСНОВНЫЕ ПРИНЦИПЫ:
- Будь эмпатичным, понимающим и поддерживающим
- Никогда не давай медицинских диагнозов или советов по лечению
- Используй методы активного слушания и техники эмоциональной поддержки
- Поощряй здоровые способы совладания со стрессом

КРИЗИСНЫЕ СИТУАЦИИ:
- При упоминании самоповреждения, суицидальных мыслей или намерений:
  * Проявляй глубокую эмпатию
  * Подчеркивай важность обращения к взрослому или специалисту
  * Предоставляй контакты местных служб помощи
`;

const CRISIS_RESPONSE_TEMPLATES = {
  suicide: {
    immediate: `Мне очень жаль, что тебе сейчас так тяжело. Твои чувства важны, и ты не одинок в этом.
Пожалуйста, немедленно обратись к взрослому, которому доверяешь, или свяжись со службой экстренной помощи.
В разделе SOS ты найдешь контакты служб, которые могут помочь прямо сейчас.`,
    followUp: `Помни: каждая проблема имеет решение, даже если сейчас это кажется невозможным.
Есть люди, которые хотят и могут тебе помочь. Твоя жизнь ценна и важна.`,
  },
  selfHarm: {
    immediate: `Я понимаю, что тебе больно, и ты ищешь способ справиться с этой болью.
Самоповреждение не решает проблемы, но усугубляет их. Давай найдем более здоровые способы выразить твои чувства.`,
    alternatives: `Вместо этого попробуй:
- Интенсивные физические упражнения
- Рисование или письмо о своих чувствах
- Холодный душ или лед на кожу
- Поговорить с кем-то, кому доверяешь`,
  },
  abuse: {
    immediate: `То, что с тобой происходит, неправильно, и это не твоя вина.
Ты заслуживаешь безопасности и заботы. Очень важно рассказать об этом взрослому, которому ты доверяешь.`,
    support: `Если трудно говорить лично, можешь:
- Написать письмо учителю или школьному психологу
- Обратиться в службу поддержки детей
- Поговорить с родственником, которому доверяешь`,
  },
};

class SafetyChecker {
  static detectCrisis(text: string): {
    isCrisis: boolean;
    type?: string;
    confidence: number;
    keywords: string[];
  } {
    const lowerText = text.toLowerCase();
    const crisisKeywords = {
      suicide: ['хочу умереть', 'покончить с собой', 'суицид', 'самоубийство', 'не хочу жить'],
      selfHarm: ['порезать себя', 'резать руки', 'причинить боль себе', 'самоповреждение'],
      abuse: ['бьет меня', 'причиняет боль', 'трогает меня', 'насилие']
    };

    for (const [type, keywords] of Object.entries(crisisKeywords)) {
      const foundKeywords = keywords.filter(keyword => lowerText.includes(keyword));
      if (foundKeywords.length > 0) {
        return {
          isCrisis: true,
          type,
          confidence: Math.min(foundKeywords.length * 0.3, 1),
          keywords: foundKeywords,
        };
      }
    }

    return {
      isCrisis: false,
      confidence: 0,
      keywords: [],
    };
  }
}

interface ProcessUserMessageOptions {
  deliverPush?: boolean;
  pushTitle?: string;
  priority?: 'normal' | 'high';
  data?: Record<string, any>;
}

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly aiService: AiService,
    private readonly notificationsService: NotificationsService,
  ) {}

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

  async createSessionWithUser(providedUserId?: string) {
    let userId = providedUserId;

    // Если userId не предоставлен или пользователь не существует, создаем нового
    if (!userId) {
      const newUser = await this.prisma.user.create({
        data: {
          role: 'child',
          locale: 'ru',
          birthYear: new Date().getFullYear() - 15, // 15 лет по умолчанию
          ageGroup: 'teen',
        },
      });
      userId = newUser.id;
      this.logger.log(`Создан новый пользователь: ${userId}`);
    } else {
      // Проверяем существует ли пользователь
      const existingUser = await this.prisma.user.findUnique({
        where: { id: userId },
      });

      if (!existingUser) {
        const newUser = await this.prisma.user.create({
          data: {
            id: userId, // Используем предоставленный ID если он не занят
            role: 'child',
            locale: 'ru',
            birthYear: new Date().getFullYear() - 15,
            ageGroup: 'teen',
          },
        });
        this.logger.log(`Создан пользователь с ID: ${userId}`);
      }
    }

    return this.createSession(userId);
  }

  async getSession(sessionId: string) {
    const session = await this.prisma.chatSession.findUnique({
      where: { id: sessionId },
      include: {
        user: true,
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
    metadata?: any,
  ) {
    const message = await this.prisma.chatMessage.create({
      data: {
        sessionId,
        role,
        content,
        safetyFlag,
        metadata,
      },
    });

    // Логируем для анализа безопасности
    if (safetyFlag && safetyFlag !== 'safe') {
      await this.logSafetyEvent(sessionId, content, safetyFlag);
    }

    return message;
  }

  /**
   * Обрабатывает пользовательское сообщение и генерирует ответ AI
   */
  async processUserMessage(
    sessionId: string,
    userMessage: string,
    options: ProcessUserMessageOptions = {},
  ): Promise<ChatResponse> {
    let session: Awaited<ReturnType<ChatService['getSession']>>;
    const shouldSendPush = options.deliverPush ?? false;
    const pushTitle = options.pushTitle ?? 'AIc ответил';
    const pushPriority = options.priority ?? 'high';
    const additionalData = options.data ?? {};

    try {
      // Получаем сессию с информацией о пользователе
      session = await this.getSession(sessionId);

      // Получаем возрастную группу из профиля или вычисляем на основе года рождения
      const ageGroup = (session.user as any).ageGroup || this.calculateAgeGroupFromYear((session.user as any).birthYear) as 'child' | 'teen' | 'young_adult';

      // Проверяем безопасность сообщения
      const safetyCheck = SafetyChecker.detectCrisis(userMessage);
      
      if (safetyCheck.isCrisis) {
        this.logger.warn(`Обнаружена кризисная ситуация: ${safetyCheck.type}`, {
          sessionId,
          confidence: safetyCheck.confidence,
          keywords: safetyCheck.keywords
        });

        // Сохраняем пользовательское сообщение
        await this.addMessage(sessionId, 'user', userMessage, safetyCheck.type);

        // Возвращаем кризисный ответ
        const crisisResponse = this.getCrisisResponse(safetyCheck.type);
        await this.addMessage(sessionId, 'assistant', crisisResponse, 'crisis_response');

        await this.queueAssistantNotification({
          shouldSend: shouldSendPush,
          userId: session.userId,
          sessionId,
          body: crisisResponse,
          title: pushTitle,
          priority: pushPriority,
          data: {
            ...additionalData,
            sessionId,
            crisisType: safetyCheck.type ?? 'unknown',
          },
        });
        
        return {
          message: crisisResponse,
          model: 'crisis-response',
          provider: 'safety-system'
        };
      }

      // Сохраняем пользовательское сообщение
      await this.addMessage(sessionId, 'user', userMessage, 'safe');

      // Получаем историю сообщений для контекста
      const messageHistory = await this.getMessages(sessionId, 10);
      
      // Преобразуем в формат для AI
      const chatMessages: ChatMessage[] = messageHistory.map(msg => ({
        role: msg.role as 'user' | 'assistant' | 'system',
        content: msg.content
      }));

      // Генерируем ответ через LM Studio
      const aiResponse = await this.aiService.chatWithLMStudio(
        chatMessages,
        SYSTEM_POLICY,
        ageGroup
      );

      // Сохраняем ответ AI
      await this.addMessage(sessionId, 'assistant', aiResponse.message, 'safe', {
        model: aiResponse.model,
        provider: aiResponse.provider,
        usage: aiResponse.usage
      });

      await this.queueAssistantNotification({
        shouldSend: shouldSendPush,
        userId: session.userId,
        sessionId,
        body: aiResponse.message,
        title: pushTitle,
        priority: pushPriority,
        data: {
          ...additionalData,
          sessionId,
          model: aiResponse.model,
          provider: aiResponse.provider,
        },
      });

      this.logger.log(`Сгенерирован ответ AI для сессии ${sessionId}`, {
        userAgeGroup: ageGroup,
        messageLength: aiResponse.message.length,
        model: aiResponse.model,
        provider: aiResponse.provider,
        tokens: aiResponse.usage?.total_tokens,
        sessionTokens: await this.getSessionTokenCount(sessionId)
      });

      return aiResponse;

    } catch (error) {
      this.logger.error(`Ошибка обработки сообщения: ${error.message}`, {
        sessionId,
        userMessage: userMessage.substring(0, 100)
      });

      // Возвращаем безопасный ответ при ошибке
      const fallbackResponse = 'Извините, произошла ошибка. Попробуйте еще раз или обратитесь к взрослому, которому доверяете.';
      await this.addMessage(sessionId, 'assistant', fallbackResponse, 'error');

      if (session) {
        await this.queueAssistantNotification({
          shouldSend: shouldSendPush,
          userId: session.userId,
          sessionId,
          body: fallbackResponse,
          title: pushTitle,
          priority: pushPriority,
          data: {
            ...additionalData,
            sessionId,
            error: 'chat-fallback',
          },
        });
      }
      
      return {
        message: fallbackResponse,
        model: 'error-fallback',
        provider: 'safety-system'
      };
    }
  }

  /**
   * Планирует отправку пуш-уведомления с ответом ассистента
   */
  private async queueAssistantNotification(params: {
    shouldSend: boolean;
    userId: string;
    sessionId: string;
    body: string;
    title?: string;
    priority?: 'normal' | 'high';
    data?: Record<string, any>;
  }) {
    const { shouldSend, userId, sessionId, body, title, priority = 'high', data } = params;

    if (!shouldSend) {
      return;
    }

    if (!userId) {
      this.logger.debug(
        `Skipping push for session ${sessionId}: userId is missing`,
      );
      return;
    }

    try {
      const preview = this.truncateMessage(body);
      const notificationData = {
        sessionId,
        preview,
        ...(data ?? {}),
      };

      const result = await this.notificationsService.queueNotification({
        userId,
        type: 'chat.assistant_message',
        title: title ?? 'AIc ответил',
        body: preview,
        data: notificationData,
        priority,
        skipWhenNoDevices: true,
      });

      if (result.skipped) {
        this.logger.debug(
          `Push notification skipped for user ${userId}: no active devices`,
        );
      }
    } catch (error) {
      this.logger.warn(
        `Failed to queue push notification for user ${userId}: ${(error as Error).message}`,
      );
    }
  }

  private truncateMessage(message: string, limit = 140): string {
    const normalized = (message || '').replace(/\s+/g, ' ').trim();

    if (!normalized) {
      return 'Новое сообщение от AIc';
    }

    if (normalized.length <= limit) {
      return normalized;
    }

    return `${normalized.slice(0, Math.max(0, limit - 3))}...`;
  }

  /**
   * Получает общее количество токенов в сессии
   */
  private async getSessionTokenCount(sessionId: string): Promise<number> {
    const messages = await this.prisma.chatMessage.findMany({
      where: { sessionId },
      select: { metadata: true }
    });

    let totalTokens = 0;
    for (const message of messages) {
      if (message.metadata && typeof message.metadata === 'object') {
        const metadata = message.metadata as any;
        if (metadata.usage?.total_tokens) {
          totalTokens += metadata.usage.total_tokens;
        }
      }
    }

    return totalTokens;
  }

  /**
   * Возвращает кризисный ответ в зависимости от типа ситуации
   */
  private getCrisisResponse(crisisType: string): string {
    switch (crisisType) {
      case 'suicide':
        return CRISIS_RESPONSE_TEMPLATES.suicide.immediate + '\n\n' + CRISIS_RESPONSE_TEMPLATES.suicide.followUp;
      case 'selfHarm':
        return CRISIS_RESPONSE_TEMPLATES.selfHarm.immediate + '\n\n' + CRISIS_RESPONSE_TEMPLATES.selfHarm.alternatives;
      case 'abuse':
        return CRISIS_RESPONSE_TEMPLATES.abuse.immediate + '\n\n' + CRISIS_RESPONSE_TEMPLATES.abuse.support;
      default:
        return CRISIS_RESPONSE_TEMPLATES.suicide.immediate;
    }
  }

  /**
   * Отправляет сообщение пользователя и возвращает ответ AI
   */
  async sendMessage(sessionId: string, content: string) {
    try {
      // Сначала добавляем сообщение пользователя в базу
      const userMessage = await this.addMessage(sessionId, 'user', content);

      // Обрабатываем сообщение через AI и получаем ответ
      const aiResponse = await this.processUserMessage(sessionId, content);

      this.logger.log(`✅ Сообщение обработано, получен ответ AI для сессии: ${sessionId}`);

      // Возвращаем ответ в формате, который ожидает клиент
      // aiResponse содержит ChatResponse с полем message
      return {
        id: 'msg-' + Date.now(),
        content: aiResponse.message || 'Извините, не могу ответить прямо сейчас.',
        role: 'assistant',
        sessionId: sessionId,
        createdAt: new Date().toISOString(),
      };
    } catch (error) {
      this.logger.error(`❌ Ошибка обработки сообщения: ${error}`);
      throw error;
    }
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
          contentHash: Buffer.from(content).toString('base64').substring(0, 64),
          riskCategory: flag === 'crisis_detected' ? 'crisis' : 'inappropriate',
          severityLevel: flag === 'crisis_detected' ? 'high' : 'low',
          flag,
          reason: `Automated detection: ${flag}`,
          action: flag === 'crisis_detected' ? 'warning' : 'none',
        },
      });
    } catch (error) {
      console.error('Ошибка записи лога безопасности:', error);
    }
  }

  private calculateAgeGroupFromYear(birthYear: number | null): 'child' | 'teen' | 'young_adult' {
    if (!birthYear) return 'teen'; // default

    const currentYear = new Date().getFullYear();
    const age = currentYear - birthYear;

    if (age <= 12) return 'child';
    if (age <= 15) return 'teen';
    return 'young_adult';
  }
}
