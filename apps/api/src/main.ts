import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import helmet from 'helmet';
import * as cookieParser from 'cookie-parser';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Security
  app.use(helmet());
  app.use(cookieParser());
  
  // CORS
  app.enableCors({ 
    origin: [/localhost/, /127\.0\.0\.1/], 
    credentials: true 
  });
  
  // Validation
  app.useGlobalPipes(new ValidationPipe({
    transform: true,
    whitelist: true,
    forbidNonWhitelisted: true,
  }));
  
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
  await app.listen(port);
  
  console.log(`🚀 AIc API запущен на http://localhost:${port}`);
  console.log(`📚 Swagger UI доступен на http://localhost:${port}/api`);
}

bootstrap();


