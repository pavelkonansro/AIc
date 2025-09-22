import { Logger, Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { NotificationsService } from './notifications.service';
// import { NotificationsProcessor } from './notifications.processor'; // Временно отключен
import { NotificationsController } from './notifications.controller';
import { FirebasePushProvider } from './providers/firebase-push.provider';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  imports: [
    ConfigModule,
    BullModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const logger = new Logger('NotificationsModule');
        const redisUrl = configService.get<string>('REDIS_URL');

        if (redisUrl) {
          try {
            const url = new URL(redisUrl);
            const portFromUrl = Number.parseInt(url.port, 10);
            const dbFromUrl = Number.parseInt(url.pathname.replace('/', '') || '0', 10);

            return {
              connection: {
                host: url.hostname,
                port: Number.isNaN(portFromUrl) ? 6379 : portFromUrl,
                password: url.password || undefined,
                db: Number.isNaN(dbFromUrl) ? 0 : dbFromUrl,
              },
            };
          } catch (error) {
            logger.warn(
              `Invalid REDIS_URL provided, falling back to discrete Redis settings: ${(error as Error).message}`,
            );
          }
        }

        const portValue = configService.get<string>('REDIS_PORT', '6379');
        const dbValue = configService.get<string>('REDIS_DB', '0');
        const port = Number.parseInt(portValue, 10);
        const db = Number.parseInt(dbValue, 10);

        return {
          connection: {
            host: configService.get<string>('REDIS_HOST', 'localhost'),
            port: Number.isNaN(port) ? 6379 : port,
            password: configService.get<string>('REDIS_PASSWORD') ?? undefined,
            db: Number.isNaN(db) ? 0 : db,
          },
        };
      },
    }),
    BullModule.registerQueue({
      name: 'notifications',
    }),
  ],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    // NotificationsProcessor, // Временно отключен
    FirebasePushProvider,
    PrismaService,
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
