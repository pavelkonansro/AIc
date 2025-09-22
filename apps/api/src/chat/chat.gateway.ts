import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
  WebSocketServer,
} from '@nestjs/websockets';
import { Socket, Server } from 'socket.io';
import { ChatService } from './chat.service';

@WebSocketGateway({ 
  cors: { origin: /localhost/ },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly sessionClients = new Map<string, Set<string>>();
  private readonly clientSessions = new Map<string, string>();

  constructor(private readonly chatService: ChatService) {}

  async handleConnection(client: Socket) {
    console.log(`Клиент подключен: ${client.id}`);
  }

  async handleDisconnect(client: Socket) {
    console.log(`Клиент отключен: ${client.id}`);
    this.unregisterClientSession(client);
  }

  @SubscribeMessage('join_session')
  async handleJoinSession(
    @MessageBody() data: { sessionId: string },
    @ConnectedSocket() client: Socket,
  ) {
    // Покидаем все комнаты (альтернативный способ)
    const rooms = Array.from(client.rooms);
    rooms.forEach(room => {
      if (room !== client.id) { // Не покидаем собственную комнату
        client.leave(room);
      }
    });

    this.unregisterClientSession(client);

    // Затем присоединяемся к новой сессии
    client.join(data.sessionId);
    this.registerClientSession(client, data.sessionId);
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
      console.log(`💬 Получено сообщение от ${client.id} в сессии ${sessionId}: "${text}"`);

      // Проверяем сколько клиентов в комнате
      const roomClients = await this.server.in(sessionId).fetchSockets();
      console.log(`👥 Клиентов в комнате ${sessionId}: ${roomClients.length}`);

      // Эмитим сообщение пользователя только другим участникам сессии (исключая отправителя)
      client.to(sessionId).emit('message', {
        role: 'user',
        content: text,
        timestamp: new Date().toISOString(),
      });

      // Показываем индикатор печати
      this.server.in(sessionId).emit('typing', {
        isTyping: true,
        timestamp: new Date().toISOString(),
      });

      // Обрабатываем сообщение через AI сервис
      const shouldSendPush = this.shouldQueuePush(sessionId);
      const aiResponse = await this.chatService.processUserMessage(sessionId, text, {
        deliverPush: shouldSendPush,
        data: {
          transport: 'socket',
        },
      });

      // Скрываем индикатор печати
      this.server.in(sessionId).emit('typing', {
        isTyping: false,
        timestamp: new Date().toISOString(),
      });

      // Эмитим ответ AI всем участникам сессии (включая отправителя)
      this.server.in(sessionId).emit('message', {
        role: 'assistant',
        content: aiResponse.message,
        timestamp: new Date().toISOString(),
        model: aiResponse.model,
        provider: aiResponse.provider,
        usage: aiResponse.usage
      });

      return {
        event: 'message_sent',
        data: {
          userMessage: {
            role: 'user',
            content: text,
            timestamp: new Date().toISOString(),
          },
          aiMessage: {
            role: 'assistant',
            content: aiResponse.message,
            timestamp: new Date().toISOString(),
            model: aiResponse.model,
            provider: aiResponse.provider,
            usage: aiResponse.usage
          },
        },
      };
    } catch (error) {
      console.error('Ошибка обработки сообщения:', error);

      // Скрываем индикатор печати при ошибке
      this.server.in(sessionId).emit('typing', {
        isTyping: false,
        timestamp: new Date().toISOString(),
      });

      this.server.in(sessionId).emit('error', {
        message: 'Ошибка при отправке сообщения',
        timestamp: new Date().toISOString(),
      });
      return {
        event: 'error',
        data: { message: 'Ошибка при отправке сообщения' },
      };
    }
  }

  private registerClientSession(client: Socket, sessionId: string) {
    client.data.sessionId = sessionId;

    const previousSessionId = this.clientSessions.get(client.id);
    if (previousSessionId && previousSessionId !== sessionId) {
      const previousClients = this.sessionClients.get(previousSessionId);
      previousClients?.delete(client.id);
      if (previousClients && previousClients.size === 0) {
        this.sessionClients.delete(previousSessionId);
      }
    }

    let clients = this.sessionClients.get(sessionId);
    if (!clients) {
      clients = new Set<string>();
      this.sessionClients.set(sessionId, clients);
    }

    clients.add(client.id);
    this.clientSessions.set(client.id, sessionId);
  }

  private unregisterClientSession(client: Socket) {
    const sessionId = this.clientSessions.get(client.id) || client.data?.sessionId;
    if (!sessionId) {
      return;
    }

    client.data.sessionId = undefined;
    this.clientSessions.delete(client.id);

    const clients = this.sessionClients.get(sessionId);
    if (!clients) {
      return;
    }

    clients.delete(client.id);
    if (clients.size === 0) {
      this.sessionClients.delete(sessionId);
    }
  }

  private shouldQueuePush(sessionId: string): boolean {
    const clients = this.sessionClients.get(sessionId);
    return !clients || clients.size === 0;
  }
}
