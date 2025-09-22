import { Module } from '@nestjs/common';
import { TestController } from './test.controller';
import { PrismaService } from '../prisma/prisma.service';
import { ChatModule } from '../chat/chat.module';

@Module({
  imports: [ChatModule],
  controllers: [TestController],
  providers: [PrismaService],
})
export class TestModule {}
