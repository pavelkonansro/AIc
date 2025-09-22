import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { App, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging, Messaging, Message } from 'firebase-admin/messaging';

@Injectable()
export class FirebasePushProvider {
  private readonly logger = new Logger(FirebasePushProvider.name);
  private messaging: Messaging | null = null;
  private app: App | null = null;

  constructor(private readonly configService: ConfigService) {
    this.initialize();
  }

  private initialize() {
    const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');
    const privateKey = this.configService
      .get<string>('FIREBASE_PRIVATE_KEY')
      ?.replace(/\\n/g, '\n');

    if (!projectId || !clientEmail || !privateKey) {
      this.logger.warn(
        'Firebase credentials are not fully configured. Push notifications are disabled.',
      );
      return;
    }

    try {
      const existingApp = getApps().find(app => app.name === 'notifications');

      if (existingApp) {
        this.app = existingApp;
      } else {
        this.app = initializeApp(
          {
            credential: cert({
              projectId,
              clientEmail,
              privateKey,
            }),
          },
          'notifications',
        );
      }

      this.messaging = getMessaging(this.app);
      this.logger.log('Firebase messaging client initialised for push notifications');
    } catch (error) {
      this.logger.error('Failed to initialise Firebase messaging client', error as Error);
    }
  }

  isEnabled(): boolean {
    return this.messaging !== null;
  }

  async send(
    deviceToken: string,
    payload: {
      title: string;
      body: string;
      data?: Record<string, string>;
      priority?: 'normal' | 'high';
    },
  ) {
    if (!this.messaging) {
      throw new Error('Firebase messaging is not configured');
    }

    const message: Message = {
      token: deviceToken,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data,
      android: {
        priority: payload.priority === 'high' ? 'high' : 'normal',
      },
      apns: {
        headers:
          payload.priority === 'high'
            ? {
                'apns-priority': '10',
              }
            : undefined,
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    return this.messaging.send(message);
  }
}

