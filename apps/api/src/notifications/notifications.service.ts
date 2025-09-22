import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { NotificationDevice, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface QueueNotificationInput {
  userId?: string | null;
  deviceIds?: string[];
  type: string;
  title: string;
  body: string;
  data?: Record<string, any> | null;
  priority?: 'normal' | 'high';
  skipWhenNoDevices?: boolean;
}

export interface QueueNotificationResult {
  notificationId?: string;
  deliveries: number;
  skipped?: boolean;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    @InjectQueue('notifications')
    private readonly notificationsQueue: Queue,
  ) {}

  async registerDevice(
    userId: string | null,
    payload: {
      platform: string;
      deviceToken: string;
      appVersion?: string;
      locale?: string;
      metadata?: Record<string, any> | null;
    },
  ) {
    const { platform, deviceToken, appVersion, locale, metadata } = payload;

    return this.prisma.notificationDevice.upsert({
      where: { deviceToken },
      update: {
        userId,
        platform,
        appVersion,
        locale,
        metadata: this.toJsonValue(metadata),
        isActive: true,
        disabledAt: null,
        lastSeenAt: new Date(),
      },
      create: {
        userId: userId ?? undefined,
        platform,
        deviceToken,
        appVersion,
        locale,
        metadata: this.toJsonValue(metadata),
        lastSeenAt: new Date(),
      },
    });
  }

  async markDeviceInactive(deviceToken: string, reason?: string) {
    const device = await this.prisma.notificationDevice.findUnique({
      where: { deviceToken },
    });

    if (!device) {
      return null;
    }

    return this.prisma.notificationDevice.update({
      where: { id: device.id },
      data: {
        isActive: false,
        disabledAt: new Date(),
        metadata: reason
          ? this.toJsonValue({
              ...this.jsonToRecord(device.metadata),
              disabledReason: reason,
            })
          : (device.metadata as Prisma.InputJsonValue | undefined),
      },
    });
  }

  async touchDevice(deviceId: string) {
    return this.prisma.notificationDevice.update({
      where: { id: deviceId },
      data: { lastSeenAt: new Date(), isActive: true },
    });
  }

  async queueNotification(input: QueueNotificationInput): Promise<QueueNotificationResult> {
    const {
      userId,
      deviceIds,
      type,
      title,
      body,
      data,
      priority = 'normal',
      skipWhenNoDevices = false,
    } = input;

    const devices = await this.resolveTargetDevices({ userId, deviceIds });

    if (devices.length === 0) {
      if (skipWhenNoDevices) {
        this.logger.debug(
          `Notification ${type} skipped: no active devices for user ${userId ?? 'n/a'}`,
        );
        return { deliveries: 0, skipped: true };
      }

      throw new BadRequestException('No active devices found for notification');
    }

    const notification = await this.prisma.notification.create({
      data: {
        userId: userId ?? undefined,
        type,
        title,
        body,
        data: this.toJsonValue(data),
      },
    });

    const deliveries = await this.prisma.$transaction(
      devices.map(device =>
        this.prisma.notificationDelivery.create({
          data: {
            notificationId: notification.id,
            deviceId: device.id,
          },
        }),
      ),
    );

    await Promise.all(
      deliveries.map(delivery =>
        this.notificationsQueue.add(
          'send-notification',
          {
            deliveryId: delivery.id,
            priority,
          },
          {
            attempts: 3,
            backoff: {
              type: 'exponential',
              delay: 5000,
            },
            removeOnComplete: 100,
            removeOnFail: 250,
          },
        ),
      ),
    );

    this.logger.log(
      `Queued notification ${notification.id} for ${deliveries.length} device(s)`,
    );

    return {
      notificationId: notification.id,
      deliveries: deliveries.length,
    };
  }

  private async resolveTargetDevices(params: {
    userId?: string | null;
    deviceIds?: string[];
  }): Promise<NotificationDevice[]> {
    const { userId, deviceIds } = params;

    const whereClauses: Prisma.NotificationDeviceWhereInput[] = [
      { isActive: true },
    ];

    if (deviceIds?.length) {
      whereClauses.push({ id: { in: deviceIds } });
    }

    if (userId) {
      whereClauses.push({ userId });
    }

    if (whereClauses.length === 1) {
      throw new BadRequestException('Either userId or deviceIds must be provided');
    }

    const devices = await this.prisma.notificationDevice.findMany({
      where: { AND: whereClauses },
    });

    return devices;
  }

  async listDevicesForUser(userId: string) {
    return this.prisma.notificationDevice.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
    });
  }

  private toJsonValue(
    value?: Record<string, any> | null,
  ): Prisma.InputJsonValue | undefined {
    if (value === undefined || value === null) {
      return undefined;
    }

    return value as Prisma.InputJsonValue;
  }

  private jsonToRecord(value: Prisma.JsonValue | null): Record<string, any> {
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
      return {};
    }

    return value as Record<string, any>;
  }
}
