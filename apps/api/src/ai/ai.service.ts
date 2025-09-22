import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface ChatResponse {
  message: string;
  model?: string;
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
  provider?: string;
}

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly aiProvider: string;

  // LM Studio configuration
  private readonly lmStudioBaseUrl: string;
  private readonly lmStudioApiKey: string;
  private readonly lmStudioModel: string;

  // OpenRouter configuration
  private readonly openRouterBaseUrl: string;
  private readonly openRouterApiKey: string;
  private readonly openRouterModel: string;

  constructor(private configService: ConfigService) {
    this.aiProvider = this.configService.get<string>('AI_PROVIDER', 'lm_studio');

    // LM Studio settings
    this.lmStudioBaseUrl = this.configService.get<string>('LM_STUDIO_BASE_URL', 'http://localhost:1234/v1');
    this.lmStudioApiKey = this.configService.get<string>('LM_STUDIO_API_KEY', 'lm-studio');
    this.lmStudioModel = this.configService.get<string>('LM_STUDIO_MODEL', 'local-model');

    // OpenRouter settings
    this.openRouterBaseUrl = this.configService.get<string>('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1');
    this.openRouterApiKey = this.configService.get<string>('OPENROUTER_API_KEY', '');
    this.openRouterModel = this.configService.get<string>('OPENROUTER_MODEL', 'x-ai/grok-4-fast:free');

    this.logger.log(`AI Provider: ${this.aiProvider}`);
    if (this.aiProvider === 'openrouter') {
      this.logger.log(`OpenRouter Model: ${this.openRouterModel}`);
    }
  }

  /**
   * Отправляет сообщение в выбранный AI провайдер и получает ответ
   */
  async chatWithLMStudio(
    messages: ChatMessage[],
    systemPolicy: string,
    ageGroup: 'child' | 'teen' | 'young_adult' = 'teen'
  ): Promise<ChatResponse> {
    if (this.aiProvider === 'openrouter') {
      return this.chatWithOpenRouter(messages, systemPolicy, ageGroup);
    } else {
      return this.chatWithLMStudioDirect(messages, systemPolicy, ageGroup);
    }
  }

  /**
   * Отправляет сообщение в LM Studio и получает ответ
   */
  private async chatWithLMStudioDirect(
    messages: ChatMessage[],
    systemPolicy: string,
    ageGroup: 'child' | 'teen' | 'young_adult' = 'teen'
  ): Promise<ChatResponse> {
    try {
      // Добавляем системную политику к сообщениям
      const systemMessage: ChatMessage = {
        role: 'system',
        content: systemPolicy
      };

      const fullMessages = [systemMessage, ...messages];

      this.logger.log(`Отправка запроса в LM Studio для возрастной группы: ${ageGroup}`);
      this.logger.debug(`Сообщения: ${JSON.stringify(fullMessages, null, 2)}`);

      const response = await axios.post(
        `${this.lmStudioBaseUrl}/chat/completions`,
        {
          model: this.lmStudioModel,
          messages: fullMessages,
          temperature: 0.7,
          max_tokens: 2000,
          stream: false
        },
        {
          headers: {
            'Authorization': `Bearer ${this.lmStudioApiKey}`,
            'Content-Type': 'application/json'
          },
          timeout: 30000
        }
      );

      const choice = response.data.choices?.[0];
      if (!choice) {
        throw new Error('LM Studio не вернул ответ');
      }

      const message = choice.message?.content || 'Извините, я не могу ответить сейчас.';
      const usage = response.data.usage;

      this.logger.log(`Получен ответ от LM Studio: ${message.substring(0, 100)}...`);

      return {
        message,
        model: this.lmStudioModel,
        usage,
        provider: 'lm_studio'
      };

    } catch (error) {
      this.logger.error(`Ошибка при обращении к LM Studio: ${error.message}`);

      return {
        message: 'Извините, я временно недоступен. Попробуйте позже или обратитесь к взрослому, которому доверяете.',
        model: this.lmStudioModel,
        provider: 'lm_studio'
      };
    }
  }

  /**
   * Отправляет сообщение в OpenRouter и получает ответ
   */
  private async chatWithOpenRouter(
    messages: ChatMessage[],
    systemPolicy: string,
    ageGroup: 'child' | 'teen' | 'young_adult' = 'teen'
  ): Promise<ChatResponse> {
    try {
      // Добавляем системную политику к сообщениям
      const systemMessage: ChatMessage = {
        role: 'system',
        content: systemPolicy
      };

      const fullMessages = [systemMessage, ...messages];

      this.logger.log(`Отправка запроса в OpenRouter (${this.openRouterModel}) для возрастной группы: ${ageGroup}`);
      this.logger.debug(`Сообщения: ${JSON.stringify(fullMessages, null, 2)}`);

      const response = await axios.post(
        `${this.openRouterBaseUrl}/chat/completions`,
        {
          model: this.openRouterModel,
          messages: fullMessages,
          temperature: 0.7,
          max_tokens: 2000,
          stream: false
        },
        {
          headers: {
            'Authorization': `Bearer ${this.openRouterApiKey}`,
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://aic-app.com',
            'X-Title': 'AIc - AI Companion for Teens'
          },
          timeout: 30000
        }
      );

      const choice = response.data.choices?.[0];
      if (!choice) {
        throw new Error('OpenRouter не вернул ответ');
      }

      const message = choice.message?.content || 'Извините, я не могу ответить сейчас.';
      const usage = response.data.usage;

      this.logger.log(`Получен ответ от OpenRouter: ${message.substring(0, 100)}...`);

      return {
        message,
        model: this.openRouterModel,
        usage,
        provider: 'openrouter'
      };

    } catch (error) {
      this.logger.error(`Ошибка при обращении к OpenRouter: ${error.message}`);

      return {
        message: 'Извините, я временно недоступен. Попробуйте позже или обратитесь к взрослому, которому доверяете.',
        model: this.openRouterModel,
        provider: 'openrouter'
      };
    }
  }

  /**
   * Проверяет доступность текущего AI провайдера
   */
  async checkLMStudioHealth(): Promise<{
    isHealthy: boolean;
    error?: string;
    models?: string[];
    baseUrl: string;
    provider: string;
  }> {
    if (this.aiProvider === 'openrouter') {
      return this.checkOpenRouterHealth();
    } else {
      return this.checkLMStudioHealthDirect();
    }
  }

  /**
   * Проверяет доступность LM Studio
   */
  private async checkLMStudioHealthDirect(): Promise<{
    isHealthy: boolean;
    error?: string;
    models?: string[];
    baseUrl: string;
    provider: string;
  }> {
    try {
      const response = await axios.get(`${this.lmStudioBaseUrl}/models`, {
        headers: {
          'Authorization': `Bearer ${this.lmStudioApiKey}`
        },
        timeout: 5000
      });

      const models = response.data.data?.map((model: any) => model.id) || [];
      this.logger.log(`LM Studio доступен. Модели: ${models.length}`);

      return {
        isHealthy: true,
        models,
        baseUrl: this.lmStudioBaseUrl,
        provider: 'lm_studio'
      };
    } catch (error) {
      const errorMessage = error.code === 'ECONNREFUSED'
        ? 'LM Studio не запущен или недоступен на порту 1234'
        : error.message;

      this.logger.warn(`LM Studio недоступен: ${errorMessage}`);

      return {
        isHealthy: false,
        error: errorMessage,
        baseUrl: this.lmStudioBaseUrl,
        provider: 'lm_studio'
      };
    }
  }

  /**
   * Проверяет доступность OpenRouter
   */
  private async checkOpenRouterHealth(): Promise<{
    isHealthy: boolean;
    error?: string;
    models?: string[];
    baseUrl: string;
    provider: string;
  }> {
    try {
      const response = await axios.get(`${this.openRouterBaseUrl}/models`, {
        headers: {
          'Authorization': `Bearer ${this.openRouterApiKey}`
        },
        timeout: 5000
      });

      const models = response.data.data?.map((model: any) => model.id) || [];
      this.logger.log(`OpenRouter доступен. Модели: ${models.length}`);

      return {
        isHealthy: true,
        models,
        baseUrl: this.openRouterBaseUrl,
        provider: 'openrouter'
      };
    } catch (error) {
      const errorMessage = error.response?.status === 401
        ? 'Неверный API ключ OpenRouter'
        : error.message;

      this.logger.warn(`OpenRouter недоступен: ${errorMessage}`);

      return {
        isHealthy: false,
        error: errorMessage,
        baseUrl: this.openRouterBaseUrl,
        provider: 'openrouter'
      };
    }
  }

  /**
   * Получает список доступных моделей в LM Studio
   */
  async getAvailableModels(): Promise<string[]> {
    try {
      const response = await axios.get(`${this.lmStudioBaseUrl}/models`, {
        headers: {
          'Authorization': `Bearer ${this.lmStudioApiKey}`
        },
        timeout: 5000
      });

      return response.data.data?.map((model: any) => model.id) || [];
    } catch (error) {
      this.logger.error(`Ошибка получения моделей: ${error.message}`);
      return [];
    }
  }
}
