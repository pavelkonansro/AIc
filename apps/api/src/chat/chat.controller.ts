import { Controller, Post, Body, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { ChatService } from './chat.service';

@ApiTags('chat')
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('session')
  @ApiOperation({ summary: 'Создание новой сессии чата' })
  @ApiResponse({ 
    status: 201, 
    description: 'Сессия чата создана',
    schema: {
      type: 'object',
      properties: {
        sessionId: { type: 'string' },
        startedAt: { type: 'string', format: 'date-time' },
        status: { type: 'string' },
      },
    },
  })
  async startSession(@Body() body: { userId: string }) {
    return this.chatService.createSession(body.userId);
  }

  @Get('session/:sessionId')
  @ApiOperation({ summary: 'Получение информации о сессии чата' })
  @ApiResponse({ 
    status: 200, 
    description: 'Информация о сессии получена',
  })
  async getSession(@Param('sessionId') sessionId: string) {
    return this.chatService.getSession(sessionId);
  }

  @Get('session/:sessionId/messages')
  @ApiOperation({ summary: 'Получение сообщений сессии' })
  @ApiResponse({ 
    status: 200, 
    description: 'Сообщения получены',
  })
  async getMessages(@Param('sessionId') sessionId: string) {
    return this.chatService.getMessages(sessionId);
  }

  @Post('session/:sessionId/end')
  @ApiOperation({ summary: 'Завершение сессии чата' })
  @ApiResponse({ 
    status: 200, 
    description: 'Сессия завершена',
  })
  async endSession(@Param('sessionId') sessionId: string) {
    return this.chatService.endSession(sessionId);
  }
}


