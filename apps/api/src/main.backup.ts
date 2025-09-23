import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import helmet from 'helmet';
import * as cookieParser from 'cookie-parser';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  
  // Security
  // app.use(helmet()); // Временно отключено для Flutter веб
  app.use(cookieParser());
  
  // CORS - разрешаем все origins для разработки
  app.enableCors({ 
    origin: true, // Разрешаем все origins для разработки
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  });
  
  // Validation
  app.useGlobalPipes(new ValidationPipe({
    transform: true,
    whitelist: true,
    forbidNonWhitelisted: true,
  }));
  
  // Static files
  app.useStaticAssets(join(__dirname, '..', 'public'));

  // Swagger documentation
  const config = new DocumentBuilder()
    .setTitle('AIc API')
    .setDescription('AI companion for teens - API documentation')
    .setVersion('1.0')
    .addTag('auth', 'Authentication endpoints')
    .addTag('users', 'User management')
    .addTag('chat', 'Chat and messaging')
    .addTag('content', 'Content management')
    .addTag('sos', 'Emergency contacts and SOS')
    .addTag('subscriptions', 'Premium subscriptions')
    .build();
  
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);
  
  const port = process.env.PORT ?? 3000;
  await app.listen(port, '0.0.0.0'); // Слушаем на всех интерфейсах
  
  console.log(`🚀 AIc API запущен на http://0.0.0.0:${port}`);
  console.log(`🌐 Доступен по IP: http://192.168.68.65:${port}`);
  console.log(`📚 Swagger UI доступен на http://192.168.68.65:${port}/api`);
}

bootstrap();


