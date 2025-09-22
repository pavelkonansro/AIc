import { BadRequestException, Body, Controller, Delete, Get, Param, Post } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { RegisterDeviceDto } from './dto/register-device.dto';
import { SendNotificationDto } from './dto/send-notification.dto';
import { SendTestNotificationDto } from './dto/send-test-notification.dto';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post('device')
  async registerDevice(@Body() dto: RegisterDeviceDto) {
    const device = await this.notificationsService.registerDevice(dto.userId ?? null, {
      platform: dto.platform,
      deviceToken: dto.deviceToken,
      appVersion: dto.appVersion,
      locale: dto.locale,
      metadata: dto.metadata,
    });

    return {
      id: device.id,
      platform: device.platform,
      isActive: device.isActive,
      lastSeenAt: device.lastSeenAt,
    };
  }

  @Delete('device/:token')
  async deactivateDevice(@Param('token') token: string) {
    await this.notificationsService.markDeviceInactive(token, 'manual_unsubscribe');
    return { status: 'ok' };
  }

  @Post('send')
  async sendNotification(@Body() dto: SendNotificationDto) {
    this.ensureHasTarget(dto.userId, dto.deviceIds);

    return this.notificationsService.queueNotification({
      userId: dto.userId,
      deviceIds: dto.deviceIds,
      type: dto.type,
      title: dto.title,
      body: dto.body,
      data: dto.data,
      priority: dto.priority,
    });
  }

  @Post('send-test')
  async sendTestNotification(@Body() dto: SendTestNotificationDto) {
    this.ensureHasTarget(dto.userId, dto.deviceIds);

    const title = dto.title ?? 'Test notification';
    const body = dto.body ?? 'This is a test push from the AIc backend.';

    return this.notificationsService.queueNotification({
      userId: dto.userId,
      deviceIds: dto.deviceIds,
      type: 'test',
      title,
      body,
      priority: 'high',
      skipWhenNoDevices: true,
    });
  }

  @Get('device/user/:userId')
  async getUserDevices(@Param('userId') userId: string) {
    const devices = await this.notificationsService.listDevicesForUser(userId);

    return devices.map(device => {
      const { deviceToken, ...rest } = device;
      return rest;
    });
  }

  private ensureHasTarget(userId?: string, deviceIds?: string[]) {
    if (!userId && (!deviceIds || deviceIds.length === 0)) {
      throw new BadRequestException('Either userId or deviceIds must be provided');
    }
  }
}
