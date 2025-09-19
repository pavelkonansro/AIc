// Временные типы (позже перенесем в common)
type Country = 'CZ' | 'DE' | 'AT' | 'SK' | 'PL' | 'HU' | 'US' | 'UK' | 'CA' | 'AU';
type Locale = 'cs-CZ' | 'de-DE' | 'en-US' | 'sk-SK' | 'pl-PL' | 'hu-HU';
type SosResource = {
  id: string;
  name: string;
  phone: string;
  description: string;
  available24h: boolean;
  country: Country;
  locale: Locale;
  type: 'emergency' | 'crisis' | 'support';
  priority: number;
  url?: string;
  hours?: string;
};

// Предзаполненные SOS контакты для разных стран
export const DEFAULT_SOS_CONTACTS: SosResource[] = [
  // Чехия
  {
    id: 'cz-emergency',
    country: 'CZ',
    locale: 'cs-CZ',
    name: 'Экстренная служба',
    phone: '112',
    description: 'Экстренные службы (полиция, скорая, пожарная)',
    available24h: true,
    type: 'emergency',
    priority: 1,
    hours: '24/7',
  },
  {
    id: 'cz-crisis-line',
    country: 'CZ',
    locale: 'cs-CZ',
    name: 'Linka bezpečí (Линия безопасности)',
    phone: '116 111',
    description: 'Кризисная линия для детей и подростков',
    available24h: true,
    url: 'https://www.linkabezpeci.cz',
    type: 'crisis',
    priority: 2,
    hours: '24/7',
  },

  // Германия
  {
    id: 'de-emergency',
    country: 'DE',
    locale: 'de-DE',
    name: 'Notruf (Экстренная служба)',
    phone: '112',
    description: 'Экстренные службы (полиция, скорая, пожарная)',
    available24h: true,
    type: 'emergency',
    priority: 1,
    hours: '24/7',
  },
  {
    id: 'de-crisis-line',
    country: 'DE',
    locale: 'de-DE',
    name: 'Nummer gegen Kummer (Номер против печали)',
    phone: '116 111',
    description: 'Линия помощи для детей и подростков',
    available24h: false,
    url: 'https://www.nummergegenkummer.de',
    type: 'crisis',
    priority: 2,
    hours: 'Mo-Sa 14:00-20:00',
  },

  // США
  {
    id: 'us-emergency',
    country: 'US',
    locale: 'en-US',
    name: 'Emergency Services',
    phone: '911',
    description: 'Emergency services (police, medical, fire)',
    available24h: true,
    type: 'emergency',
    priority: 1,
    hours: '24/7',
  },
  {
    id: 'us-crisis-line',
    country: 'US',
    locale: 'en-US',
    name: 'National Suicide Prevention Lifeline',
    phone: '988',
    description: 'National suicide prevention and crisis support',
    available24h: true,
    url: 'https://suicidepreventionlifeline.org',
    type: 'crisis',
    priority: 2,
    hours: '24/7',
  },
];

// Функция для получения SOS контактов по стране
export function getSosContactsByCountry(country: Country): SosResource[] {
  return DEFAULT_SOS_CONTACTS.filter(contact => contact.country === country);
}

// Функция для получения SOS контактов по типу
export function getSosContactsByType(type: SosResource['type']): SosResource[] {
  return DEFAULT_SOS_CONTACTS.filter(contact => contact.type === type);
}

// Функция для получения приоритетных контактов
export function getPrioritySosContacts(country: Country, limit: number = 3): SosResource[] {
  return DEFAULT_SOS_CONTACTS
    .filter(contact => contact.country === country)
    .sort((a, b) => a.priority - b.priority)
    .slice(0, limit);
}