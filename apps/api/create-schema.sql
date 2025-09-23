-- Privacy-by-design schema для AIc
-- Создание таблиц напрямую без миграций Prisma

-- ===== CORE USER SYSTEM =====

CREATE TABLE users (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    role TEXT DEFAULT 'child',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    tz TEXT,
    locale TEXT DEFAULT 'ru',
    birthdate TIMESTAMP WITH TIME ZONE,
    consent_version INTEGER DEFAULT 1
);

-- Родитель ↔ ребёнок (многие-ко-многим)
CREATE TABLE guardian_links (
    id BIGSERIAL PRIMARY KEY,
    guardian_id TEXT NOT NULL,
    child_id TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    FOREIGN KEY (guardian_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (child_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(guardian_id, child_id)
);

-- Согласия (минимизируем PII)
CREATE TABLE consents (
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    given_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    consent_type TEXT NOT NULL, -- tos, privacy, parental
    version INTEGER NOT NULL,
    scope TEXT,
    meta JSONB,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ===== PROGRESS & SESSIONS =====

-- Профиль прогресса (без чувствительных текстов)
CREATE TABLE progress (
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    module_id TEXT NOT NULL,
    step_key TEXT NOT NULL,
    state JSONB,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, module_id, step_key)
);

-- Сессии взаимодействия (агрегация для аналитики без PII)
CREATE TABLE sessions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    ended_at TIMESTAMP WITH TIME ZONE,
    device TEXT,
    app_version TEXT,
    meta JSONB,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ===== CHAT SYSTEM =====

CREATE TABLE chat_sessions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    ended_at TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'active', -- active, ended, paused
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE chat_messages (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    session_id TEXT NOT NULL,
    role TEXT NOT NULL, -- user/assistant/system
    content TEXT NOT NULL,
    safety_flag TEXT,   -- safe/warning/blocked
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
);

-- ===== SAFETY & FEEDBACK =====

CREATE TABLE safety_logs (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT,
    session_id TEXT,
    content TEXT NOT NULL,
    flag TEXT NOT NULL, -- safe/warning/blocked
    reason TEXT,
    action TEXT,        -- none/warning/block/escalate
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_safety_logs_flag ON safety_logs(flag);
CREATE INDEX idx_safety_logs_created_at ON safety_logs(created_at);

-- Обратная связь (контролируемый словарь)
CREATE TABLE feedback (
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    category TEXT,      -- ux, content, bug, other
    comment TEXT,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ===== CONTENT & CONFIG =====

-- Remote config / feature flags
CREATE TABLE remote_config (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    audience JSONB
);

CREATE TABLE articles (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    locale TEXT NOT NULL,
    topic TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    version INTEGER DEFAULT 1,
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_articles_locale_topic ON articles(locale, topic);
CREATE INDEX idx_articles_is_published ON articles(is_published);

CREATE TABLE sos_contacts (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    country TEXT NOT NULL,
    locale TEXT NOT NULL,
    ctype TEXT NOT NULL,   -- emergency, mental-health, abuse, etc.
    name TEXT NOT NULL,
    phone TEXT,
    url TEXT,
    hours TEXT,
    priority INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_sos_contacts_country_locale ON sos_contacts(country, locale);
CREATE INDEX idx_sos_contacts_is_active ON sos_contacts(is_active);

-- ===== NOTIFICATIONS & DEVICES =====

-- Push-токены устройств
CREATE TABLE push_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    platform TEXT NOT NULL, -- ios, android
    token TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    last_seen_at TIMESTAMP WITH TIME ZONE,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, token)
);

CREATE TABLE notifications (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT,       -- null for broadcast notifications
    type TEXT NOT NULL, -- reminder, update, emergency, etc.
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    is_sent BOOLEAN DEFAULT false,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_notifications_user_id_is_sent ON notifications(user_id, is_sent);
CREATE INDEX idx_notifications_type ON notifications(type);

CREATE TABLE notification_devices (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT,
    platform TEXT NOT NULL,    -- ios/android/web
    device_token TEXT UNIQUE NOT NULL,
    app_version TEXT,
    locale TEXT,
    metadata JSONB,
    is_active BOOLEAN DEFAULT true,
    disabled_at TIMESTAMP WITH TIME ZONE,
    last_seen_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_notification_devices_user_id_is_active ON notification_devices(user_id, is_active);

CREATE TABLE notification_deliveries (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    notification_id TEXT NOT NULL,
    device_id TEXT NOT NULL,
    status TEXT DEFAULT 'pending', -- pending/sent/failed
    error TEXT,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
    FOREIGN KEY (device_id) REFERENCES notification_devices(id) ON DELETE CASCADE
);

CREATE INDEX idx_notification_deliveries_notification_id ON notification_deliveries(notification_id);
CREATE INDEX idx_notification_deliveries_device_id ON notification_deliveries(device_id);

-- ===== PURCHASES =====

CREATE TABLE purchases (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    platform TEXT NOT NULL,    -- ios/android/web
    product_id TEXT NOT NULL,
    transaction_id TEXT UNIQUE,
    status TEXT NOT NULL,       -- active/canceled/expired/pending
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
    expiry_date TIMESTAMP WITH TIME ZONE,
    renewed_at TIMESTAMP WITH TIME ZONE,
    revenuecat_id TEXT,
    original_json JSONB,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_purchases_user_id_status ON purchases(user_id, status);

-- ===== TRIGGERS FOR UPDATED_AT =====

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON articles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sos_contacts_updated_at BEFORE UPDATE ON sos_contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notification_devices_updated_at BEFORE UPDATE ON notification_devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();