import { Module } from '@nestjs/common';
import { ContentController } from './content.controller';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  controllers: [ContentController],
  providers: [PrismaService],
})
export class ContentModule {}


