import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { SosService } from './sos.service';

@ApiTags('sos')
@Controller('sos')
export class SosController {
  constructor(private readonly sosService: SosService) {}

  @Get('resources')
  @ApiOperation({ summary: 'Получение контактов экстренной помощи' })
  @ApiQuery({ 
    name: 'country', 
    description: 'Код страны (CZ, DE, US)',
    example: 'CZ',
  })
  @ApiQuery({ 
    name: 'locale', 
    description: 'Локаль (cs-CZ, de-DE, en-US)',
    required: false,
    example: 'cs-CZ',
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Список контактов экстренной помощи',
    schema: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          country: { type: 'string' },
          locale: { type: 'string' },
          type: { type: 'string' },
          name: { type: 'string' },
          phone: { type: 'string', nullable: true },
          url: { type: 'string', nullable: true },
          hours: { type: 'string', nullable: true },
          priority: { type: 'number' },
        },
      },
    },
  })
  async getResources(
    @Query('country') country: string,
    @Query('locale') locale?: string,
  ) {
    return this.sosService.getContacts(country, locale);
  }

  @Get('crisis-check')
  @ApiOperation({ summary: 'Проверка текста на кризисный контент' })
  @ApiQuery({ 
    name: 'text', 
    description: 'Текст для проверки',
    example: 'Мне очень плохо',
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Результат проверки',
    schema: {
      type: 'object',
      properties: {
        isCrisis: { type: 'boolean' },
        confidence: { type: 'number' },
        keywords: { type: 'array', items: { type: 'string' } },
        recommendation: { type: 'string' },
      },
    },
  })
  async checkCrisisContent(@Query('text') text: string) {
    return this.sosService.checkCrisisContent(text);
  }
}


