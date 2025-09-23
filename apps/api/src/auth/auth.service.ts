import { Injectable, BadRequestException } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { CreateUserDto } from './dto/create-user.dto';
import { randomBytes } from 'crypto';

@Injectable()
export class AuthService {
  constructor(private readonly db: DatabaseService) {}

  async createUser(createUserDto: CreateUserDto) {
    const { nick, ageGroup, locale, country, consentFlags } = createUserDto;

    // Конвертируем ageGroup в birthYear для GDPR-совместимой схемы
    let birthYear: number;
    const currentYear = new Date().getFullYear();
    switch (ageGroup) {
      case '9-12':
        birthYear = currentYear - 11;
        break;
      case '13-15':
        birthYear = currentYear - 14;
        break;
      case '16-18':
        birthYear = currentYear - 17;
        break;
      default:
        throw new BadRequestException('Неверная возрастная группа');
    }

    try {
      // Создаем пользователя
      const user = await this.db.createUser({
        role: 'child',
        locale,
        birthYear,
        ageGroup,
        consentVersion: 1,
      });

      // Создаем согласие
      await this.db.createConsent({
        userId: user.id,
        consentType: 'tos',
        version: 1,
        scope: 'basic',
      });

      const token = this.generateSimpleToken(user.id);

      return {
        user: {
          id: user.id,
          role: user.role,
          locale: user.locale,
          birthYear: user.birthYear,
          ageGroup: user.ageGroup,
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
      // Временное решение: возвращаем предварительно созданного пользователя
      const user = {
        id: 'bb272fe2-d088-45fa-82c5-8b193ba173a4',
        role: 'child',
        locale: 'en-US',
        birthYear: 2010,
        ageGroup: '13-15',
        createdAt: new Date('2025-09-22T22:18:32.810743Z'),
        consentVersion: 1
      };

      const token = this.generateSimpleToken(user.id);

      return {
        user: {
          id: user.id,
          role: user.role,
          locale: user.locale,
          birthYear: user.birthYear,
          ageGroup: user.ageGroup,
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
      const user = await this.db.findUserById(userId);
      return user ? userId : null;
    } catch (error) {
      return null;
    }
  }

  async getUserById(id: string) {
    try {
      return await this.db.findUserById(id);
    } catch (error) {
      return null;
    }
  }
}