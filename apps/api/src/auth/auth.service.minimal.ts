import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { randomBytes } from 'crypto';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

  async createUser(createUserDto: CreateUserDto) {
    // Временная реализация - используем только базовые поля из старой схемы
    const { nick, ageGroup, locale, country, consentFlags } = createUserDto;

    // Валидация возрастной группы
    const validAgeGroups = ['9-12', '13-15', '16-18'];
    if (!validAgeGroups.includes(ageGroup)) {
      throw new BadRequestException('Неверная возрастная группа');
    }

    // Пока используем старые поля, которые еще есть в Prisma клиенте
    try {
      const user = await this.prisma.user.create({
        data: {
          // Используем только поля, которые точно есть в базе
          locale,
        },
      });

      const token = this.generateSimpleToken(user.id);

      return {
        user: {
          id: user.id,
          locale: user.locale,
          createdAt: user.createdAt,
        },
        token,
      };
    } catch (error) {
      throw new BadRequestException('Ошибка создания пользователя: ' + error.message);
    }
  }

  async createGuestUser() {
    try {
      const user = await this.prisma.user.create({
        data: {
          locale: 'en-US',
        },
      });

      const token = this.generateSimpleToken(user.id);

      return {
        user: {
          id: user.id,
          locale: user.locale,
          createdAt: user.createdAt,
          isGuest: true,
        },
        token,
      };
    } catch (error) {
      throw new BadRequestException('Ошибка создания гостевого пользователя: ' + error.message);
    }
  }

  private generateSimpleToken(userId: string): string {
    const timestamp = Date.now().toString(36);
    const random = randomBytes(8).toString('hex');
    return `${userId}.${timestamp}.${random}`;
  }

  async validateToken(token: string): Promise<string | null> {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;
      
      const userId = parts[0];
      
      // Проверяем, что пользователь существует
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
      });

      return user ? userId : null;
    } catch (error) {
      return null;
    }
  }

  async getUserById(id: string) {
    try {
      return await this.prisma.user.findUnique({
        where: { id },
      });
    } catch (error) {
      return null;
    }
  }
}