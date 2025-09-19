import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { randomBytes } from 'crypto';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

  async createUser(createUserDto: CreateUserDto) {
    const { nick, ageGroup, locale, country, consentFlags } = createUserDto;

    // Валидация возрастной группы
    const validAgeGroups = ['9-12', '13-15', '16-18'];
    if (!validAgeGroups.includes(ageGroup)) {
      throw new BadRequestException('Неверная возрастная группа');
    }

    // Создание пользователя
    const user = await this.prisma.user.create({
      data: {
        nick: nick.trim(),
        ageGroup,
        locale,
        country: country.toUpperCase(),
        consentFlags,
        profile: {
          create: {
            interests: [],
            issues: [],
            settings: {},
          },
        },
      },
      include: {
        profile: true,
      },
    });

    // Генерация простого токена (в продакшене использовать JWT)
    const token = this.generateSimpleToken(user.id);

    return {
      user: {
        id: user.id,
        nick: user.nick,
        ageGroup: user.ageGroup,
        locale: user.locale,
        country: user.country,
        createdAt: user.createdAt,
      },
      token,
    };
  }

  async createGuestUser() {
    const guestNick = `Гость${Math.floor(Math.random() * 10000)}`;
    
    const user = await this.prisma.user.create({
      data: {
        nick: guestNick,
        ageGroup: '13-15', // дефолтная группа для гостей
        locale: 'en-US',
        country: 'US',
        profile: {
          create: {
            interests: [],
            issues: [],
            settings: { isGuest: true },
          },
        },
      },
      include: {
        profile: true,
      },
    });

    const token = this.generateSimpleToken(user.id);

    return {
      user: {
        id: user.id,
        nick: user.nick,
        ageGroup: user.ageGroup,
        locale: user.locale,
        country: user.country,
        createdAt: user.createdAt,
        isGuest: true,
      },
      token,
    };
  }

  private generateSimpleToken(userId: string): string {
    // Простая генерация токена (в продакшене использовать JWT с proper signing)
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
    } catch {
      return null;
    }
  }
}

