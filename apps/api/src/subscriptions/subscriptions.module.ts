import { Module } from '@nestjs/common';
import { RevenuecatController } from './revenuecat.controller';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  controllers: [RevenuecatController],
  providers: [PrismaService],
})
export class SubscriptionsModule {}


