import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('content')
@Controller('content')
export class ContentController {
  @Get('articles')
  async getArticles(
    @Query('topic') topic?: string,
    @Query('locale') locale?: string,
  ) {
    return { message: 'Articles endpoint (заглушка)' };
  }
}


