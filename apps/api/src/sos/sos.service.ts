import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SosService {
  constructor(private readonly prisma: PrismaService) {}

  async getContacts(country: string, locale?: string) {
    const contacts = await this.prisma.sosContact.findMany({
      where: {
        country: country.toUpperCase(),
        ...(locale && { locale }),
        isActive: true,
      },
      orderBy: [
        { priority: 'desc' },
        { name: 'asc' },
      ],
    });

    return contacts.map(contact => ({
      id: contact.id,
      country: contact.country,
      locale: contact.locale,
      type: contact.ctype,
      name: contact.name,
      phone: contact.phone,
      url: contact.url,
      hours: contact.hours,
      priority: contact.priority,
    }));
  }

  async checkCrisisContent(text: string) {
    const lowerText = text.toLowerCase();
    
    // Ключевые слова для определения кризисного контента
    const crisisKeywords = {
      suicide: ['суицид', 'самоубийство', 'покончить с собой', 'умереть', 'убить себя'],
      selfHarm: ['порезать себя', 'причинить боль', 'навредить себе', 'резать'],
      depression: ['депрессия', 'безнадежность', 'бессмысленно', 'никого не волнует'],
      emergency: ['помощь', 'экстренно', 'срочно', 'опасность'],
    };

    const foundKeywords: string[] = [];
    let crisisType = '';
    let confidence = 0;

    // Проверяем наличие кризисных слов
    Object.entries(crisisKeywords).forEach(([type, keywords]) => {
      const matches = keywords.filter(keyword => lowerText.includes(keyword));
      if (matches.length > 0) {
        foundKeywords.push(...matches);
        crisisType = type;
        confidence = Math.min(confidence + matches.length * 0.3, 1);
      }
    });

    const isCrisis = confidence > 0.3;

    let recommendation = '';
    if (isCrisis) {
      switch (crisisType) {
        case 'suicide':
          recommendation = 'Немедленно обратитесь за помощью к взрослому или по телефону экстренных служб';
          break;
        case 'selfHarm':
          recommendation = 'Важно поговорить с кем-то, кому вы доверяете, или обратиться к специалисту';
          break;
        case 'depression':
          recommendation = 'Рассмотрите возможность обратиться к психологу или в службу поддержки';
          break;
        default:
          recommendation = 'Если вы чувствуете себя в опасности, обратитесь за помощью';
      }
    }

    // Логируем проверку безопасности
    if (isCrisis) {
      await this.logSafetyCheck(text, foundKeywords, confidence);
    }

    return {
      isCrisis,
      confidence: Math.round(confidence * 100) / 100,
      keywords: foundKeywords,
      recommendation,
    };
  }

  private async logSafetyCheck(text: string, keywords: string[], confidence: number) {
    try {
      await this.prisma.safetyLog.create({
        data: {
          content: text,
          flag: 'crisis_detected',
          reason: `Keywords detected: ${keywords.join(', ')}`,
          action: confidence > 0.7 ? 'escalate' : 'warning',
        },
      });
    } catch (error) {
      console.error('Ошибка записи лога безопасности:', error);
    }
  }

  // Метод для администраторов - добавление новых SOS контактов
  async createContact(data: {
    country: string;
    locale: string;
    type: string;
    name: string;
    phone?: string;
    url?: string;
    hours?: string;
    priority?: number;
  }) {
    return this.prisma.sosContact.create({
      data: {
        country: data.country.toUpperCase(),
        locale: data.locale,
        ctype: data.type,
        name: data.name,
        phone: data.phone,
        url: data.url,
        hours: data.hours,
        priority: data.priority || 0,
      },
    });
  }
}


