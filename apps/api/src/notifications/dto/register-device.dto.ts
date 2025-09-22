import { IsOptional, IsString, IsIn, IsObject } from 'class-validator';

const SUPPORTED_PLATFORMS = ['ios', 'android', 'web'] as const;

export type NotificationPlatform = (typeof SUPPORTED_PLATFORMS)[number];

export class RegisterDeviceDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsString()
  @IsIn(SUPPORTED_PLATFORMS, {
    message: `platform must be one of: ${SUPPORTED_PLATFORMS.join(', ')}`,
  })
  platform!: NotificationPlatform;

  @IsString()
  deviceToken!: string;

  @IsOptional()
  @IsString()
  appVersion?: string;

  @IsOptional()
  @IsString()
  locale?: string;

  @IsOptional()
  @IsObject()
  metadata?: Record<string, any>;
}

