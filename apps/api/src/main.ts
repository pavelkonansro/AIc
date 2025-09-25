import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.minimal.module'; // Используем минимальный модуль
import helmet from 'helmet';
import * as cookieParser from 'cookie-parser';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  
  // Security
  // app.use(helmet()); // Временно отключено для Flutter веб
  app.use(cookieParser());
  
  // CORS - настройка для dev режимов
  app.enableCors({ 
    origin: [
      'http://127.0.0.1:3000',     // Симулятор localhost
      'http://localhost:3000',      // Симулятор localhost
      'http://192.168.68.65:3000',  // iPhone → Mac IP
      /^https:\/\/.*\.ngrok-free\.dev$/, // ngrok туннели
      /^https:\/\/.*\.ngrok\.app$/,      // ngrok статичные домены
    ],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'ngrok-skip-browser-warning'],
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
  const host = process.env.HOST ?? '0.0.0.0'; // КРИТИЧНО: для iPhone доступа
  await app.listen(port, host);

  console.log(`🚀 AIc API запущен на http://${host}:${port}`);
  console.log(`📱 Доступен для iPhone: http://192.168.68.65:${port}`);
  console.log(`🌐 Swagger UI доступен на http://localhost:${port}/api`);
  console.log(`🔍 Тестируйте: curl -X GET http://localhost:${port}/health`);
}

bootstrap();


