// Типы возрастных групп
export type AgeGroup = '9-12' | '13-15' | '16-18';

// Типы локалей
export type Locale = 'en-US' | 'cs-CZ' | 'de-DE';

// Типы стран
export type Country = 'US' | 'CZ' | 'DE';

// Интерфейс SOS ресурса
export interface SosResource {
  id: string;
  country: Country;
  locale: Locale;
  name: string;
  phone?: string;
  url?: string;
  hours?: string;
  type: string;
  priority: number;
}

// События для real-time коммуникации
export const Events = {
  // Chat events
  CHAT_START: 'chat:start',
  CHAT_MESSAGE: 'chat:message',
  CHAT_JOIN_SESSION: 'join_session',
  CHAT_LEAVE_SESSION: 'leave_session',
  
  // User events
  USER_ONLINE: 'user:online',
  USER_OFFLINE: 'user:offline',
  
  // Safety events
  SAFETY_ALERT: 'safety:alert',
  CRISIS_DETECTED: 'crisis:detected',
  
  // Notification events
  NOTIFICATION_SENT: 'notification:sent',
  REMINDER_DUE: 'reminder:due',
} as const;

// Интерфейс пользователя
export interface User {
  id: string;
  nick: string;
  ageGroup: AgeGroup;
  locale: Locale;
  country: Country;
  createdAt: Date;
  isGuest?: boolean;
}

// Интерфейс сообщения чата
export interface ChatMessage {
  id: string;
  sessionId: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  safetyFlag?: string;
  createdAt: Date;
}

// Интерфейс сессии чата
export interface ChatSession {
  id: string;
  userId: string;
  startedAt: Date;
  endedAt?: Date;
  status: 'active' | 'ended' | 'paused';
}

// Статусы безопасности
export enum SafetyFlag {
  SAFE = 'safe',
  WARNING = 'warning',
  CRISIS = 'crisis_detected',
  BLOCKED = 'blocked',
}

// Типы подписок
export enum SubscriptionType {
  FREE = 'free',
  PREMIUM_WEEKLY = 'premium_weekly',
  PREMIUM_MONTHLY = 'premium_monthly',
  PREMIUM_YEARLY = 'premium_yearly',
}

// Утилитарные функции
export const Utils = {
  // Валидация возрастной группы
  isValidAgeGroup: (ageGroup: string): ageGroup is AgeGroup => {
    return ['9-12', '13-15', '16-18'].includes(ageGroup);
  },

  // Валидация локали
  isValidLocale: (locale: string): locale is Locale => {
    return ['en-US', 'cs-CZ', 'de-DE'].includes(locale);
  },

  // Валидация кода страны
  isValidCountry: (country: string): country is Country => {
    return ['US', 'CZ', 'DE'].includes(country);
  },

  // Генерация случайного ID
  generateId: (): string => {
    return Math.random().toString(36).substring(2) + Date.now().toString(36);
  },

  // Форматирование даты для отображения
  formatDate: (date: Date, locale: Locale = 'en-US'): string => {
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  },

  // Определение является ли пользователь в кризисе по флагу безопасности
  isCrisisFlag: (safetyFlag?: string): boolean => {
    return safetyFlag === SafetyFlag.CRISIS || safetyFlag === SafetyFlag.BLOCKED;
  },
};
