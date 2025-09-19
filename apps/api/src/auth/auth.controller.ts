import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { CreateUserDto } from './dto/create-user.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  @ApiOperation({ summary: 'Регистрация нового пользователя' })
  @ApiResponse({ 
    status: 201, 
    description: 'Пользователь успешно создан',
    schema: {
      type: 'object',
      properties: {
        user: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            nick: { type: 'string' },
            ageGroup: { type: 'string' },
            locale: { type: 'string' },
            country: { type: 'string' },
            createdAt: { type: 'string', format: 'date-time' },
          },
        },
        token: { type: 'string' },
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Неверные данные' })
  async signup(@Body() createUserDto: CreateUserDto) {
    return this.authService.createUser(createUserDto);
  }

  @Post('guest')
  @ApiOperation({ summary: 'Создание гостевого аккаунта' })
  @ApiResponse({ status: 201, description: 'Гостевой аккаунт создан' })
  async createGuest() {
    return this.authService.createGuestUser();
  }
}


