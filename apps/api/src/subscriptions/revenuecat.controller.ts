import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('subscriptions')
@Controller('subscriptions')
export class RevenuecatController {
  @Post('revenuecat/webhook')
  async handleWebhook(@Body() body: any) {
    console.log('RevenueCat webhook:', body);
    return { status: 'ok' };
  }
}


