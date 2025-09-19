import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async sendNotification(userId: string, title: string, body: string) {
    // TODO: Интеграция с Firebase/APNs
    console.log(`Notification to ${userId}: ${title} - ${body}`);
    return { status: 'sent' };
  }
}


