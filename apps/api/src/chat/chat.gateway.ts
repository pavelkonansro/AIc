import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { ChatService } from './chat.service';

@WebSocketGateway({ 
  cors: { origin: /localhost/ },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  constructor(private readonly chatService: ChatService) {}

  async handleConnection(client: Socket) {
    console.log(`Клиент подключен: ${client.id}`);
  }

  async handleDisconnect(client: Socket) {
    console.log(`Клиент отключен: ${client.id}`);
  }

  @SubscribeMessage('join_session')
  async handleJoinSession(
    @MessageBody() data: { sessionId: string },
    @ConnectedSocket() client: Socket,
  ) {
    client.join(data.sessionId);
    console.log(`Клиент ${client.id} присоединился к сессии ${data.sessionId}`);
    
    return { event: 'joined_session', data: { sessionId: data.sessionId } };
  }

  @SubscribeMessage('chat:message')
  async handleMessage(
    @MessageBody() data: { sessionId: string; text: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { sessionId, text } = data;
    
    try {
      // Сохраняем сообщение пользователя
      const userMessage = await this.chatService.addMessage(
        sessionId,
        'user',
        text,
      );

      // Эмитим сообщение пользователя всем участникам сессии
      client.to(sessionId).emit('message', {
        id: userMessage.id,
        role: 'user',
        content: text,
        createdAt: userMessage.createdAt,
      });

      // Генерируем ответ ИИ (пока заглушка)
      const aiResponse = await this.generateAIResponse(text, sessionId);
      
      // Сохраняем ответ ИИ
      const aiMessage = await this.chatService.addMessage(
        sessionId,
        'assistant',
        aiResponse.content,
        aiResponse.safetyFlag,
      );

      // Эмитим ответ ИИ
      client.to(sessionId).emit('message', {
        id: aiMessage.id,
        role: 'assistant',
        content: aiResponse.content,
        createdAt: aiMessage.createdAt,
        safetyFlag: aiResponse.safetyFlag,
      });

      return {
        event: 'message_sent',
        data: {
          userMessage: {
            id: userMessage.id,
            role: 'user',
            content: text,
            createdAt: userMessage.createdAt,
          },
          aiMessage: {
            id: aiMessage.id,
            role: 'assistant',
            content: aiResponse.content,
            createdAt: aiMessage.createdAt,
            safetyFlag: aiResponse.safetyFlag,
          },
        },
      };
    } catch (error) {
      console.error('Ошибка обработки сообщения:', error);
      return {
        event: 'error',
        data: { message: 'Ошибка при отправке сообщения' },
      };
    }
  }

  private async generateAIResponse(userMessage: string, sessionId: string) {
    // TODO: Интегрировать с реальным AI API (OpenAI, Azure AI, etc.)
    // TODO: Применить safety policy и фильтры
    
    // Простые эвристики для демо
    const lowerMessage = userMessage.toLowerCase();
    
    // Проверка на кризисные слова
    const crisisKeywords = ['умереть', 'смерть', 'убить', 'суицид', 'покончить'];
    const hasCrisisContent = crisisKeywords.some(keyword => 
      lowerMessage.includes(keyword)
    );

    if (hasCrisisContent) {
      return {
        content: `Мне очень жаль, что тебе так тяжело. Ты не одинок в своих переживаниях. 
Пожалуйста, обратись за помощью к взрослому, которому доверяешь, или к специалисту. 
Всегда есть люди, готовые помочь. Можешь найти контакты экстренной помощи в разделе SOS.`,
        safetyFlag: 'crisis_detected',
      };
    }

    // Обычные ответы
    const responses = [
      'Понимаю тебя. Расскажи мне больше об этом.',
      'Это звучит важно для тебя. Как ты себя чувствуешь?',
      'Спасибо, что поделился со мной. Что ты думаешь об этом?',
      'Я здесь, чтобы тебя выслушать. Продолжай, пожалуйста.',
      'Интересно! А как бы ты хотел, чтобы это изменилось?',
    ];

    const randomResponse = responses[Math.floor(Math.random() * responses.length)];
    
    return {
      content: randomResponse,
      safetyFlag: 'safe',
    };
  }
}


