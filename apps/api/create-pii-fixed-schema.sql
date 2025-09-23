-- GDPR-Compliant Database Schema for AIc
-- Generated from updated Prisma schema with PII fixes

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===== CORE USER SYSTEM =====

CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    role VARCHAR(20) DEFAULT 'child',
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tz VARCHAR(50),
    locale VARCHAR(10) DEFAULT 'ru',
    "birthYear" INTEGER, -- GDPR-friendly: только год для возрастных групп
    "ageGroup" VARCHAR(20), -- computed: child, teen, young_adult
    "consentVersion" INTEGER DEFAULT 1,
    "dataRetentionUntil" TIMESTAMP -- автоудаление неактивных аккаунтов через N дней
);

-- Guardian ↔ Child relationships (many-to-many)
CREATE TABLE guardian_links (
    id BIGSERIAL PRIMARY KEY,
    "guardianId" VARCHAR(36) NOT NULL,
    "childId" VARCHAR(36) NOT NULL,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE("guardianId", "childId"),
    FOREIGN KEY ("guardianId") REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY ("childId") REFERENCES users(id) ON DELETE CASCADE
);

-- User consents and privacy preferences
CREATE TABLE consents (
    id BIGSERIAL PRIMARY KEY,
    "userId" VARCHAR(36) NOT NULL,
    type VARCHAR(50) NOT NULL,
    "isGranted" BOOLEAN NOT NULL,
    "grantedAt" TIMESTAMP,
    "revokedAt" TIMESTAMP,
    version INTEGER DEFAULT 1,
    "ipAddress" VARCHAR(45),
    "userAgent" TEXT,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE
);

-- User progress tracking
CREATE TABLE progress (
    id BIGSERIAL PRIMARY KEY,
    "userId" VARCHAR(36) NOT NULL,
    category VARCHAR(50) NOT NULL,
    metric VARCHAR(50) NOT NULL,
    value DECIMAL NOT NULL,
    "recordedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE
);

-- User sessions for analytics
CREATE TABLE sessions (
    id BIGSERIAL PRIMARY KEY,
    "userId" VARCHAR(36),
    "sessionId" VARCHAR(255) NOT NULL,
    "startedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "endedAt" TIMESTAMP,
    "deviceInfo" JSONB,
    "ipAddress" VARCHAR(45),
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE SET NULL
);

-- ===== CHAT SYSTEM =====

CREATE TABLE chat_sessions (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    "userId" VARCHAR(36) NOT NULL,
    "startedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "endedAt" TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE chat_messages (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    "sessionId" VARCHAR(36) NOT NULL,
    role VARCHAR(20) NOT NULL,
    content VARCHAR(2000) NOT NULL, -- limited for privacy
    "contentHash" VARCHAR(64), -- hash for deduplication
    "safetyFlag" VARCHAR(20),
    metadata JSONB,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "deleteAfter" TIMESTAMP, -- GDPR compliance: TTL for automatic deletion
    FOREIGN KEY ("sessionId") REFERENCES chat_sessions(id) ON DELETE CASCADE
);

-- ===== SAFETY & FEEDBACK =====

CREATE TABLE safety_logs (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    "userId" VARCHAR(36),
    "sessionId" VARCHAR(36),
    "contentHash" VARCHAR(64), -- hash instead of full content
    "riskCategory" VARCHAR(50) NOT NULL, -- crisis, harassment, inappropriate, etc.
    "severityLevel" VARCHAR(20) NOT NULL, -- low, medium, high, critical
    flag VARCHAR(20) NOT NULL,
    reason TEXT,
    action VARCHAR(20),
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "deleteAfter" TIMESTAMP, -- TTL for automatic deletion after 30 days
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE feedback (
    id BIGSERIAL PRIMARY KEY,
    "userId" VARCHAR(36),
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    category VARCHAR(20),
    comment VARCHAR(2000), -- max 2000 chars for privacy
    "deleteAfter" TIMESTAMP, -- TTL for automatic deletion after 90 days
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE SET NULL
);

-- ===== CONTENT & CONFIG =====

CREATE TABLE remote_config (
    id BIGSERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    "isActive" BOOLEAN DEFAULT TRUE,
    "ageGroup" VARCHAR(20), -- null = all ages
    locale VARCHAR(10), -- null = all locales
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE articles (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    excerpt TEXT,
    content TEXT NOT NULL,
    "imageUrl" TEXT,
    category VARCHAR(50),
    "ageGroup" VARCHAR(20),
    locale VARCHAR(10) DEFAULT 'ru',
    tags TEXT[],
    "readTime" INTEGER,
    "isPublished" BOOLEAN DEFAULT FALSE,
    "publishedAt" TIMESTAMP,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== SOS CONTACTS (GDPR-COMPLIANT) =====

CREATE TABLE sos_contacts (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    country VARCHAR(10) NOT NULL,
    locale VARCHAR(10) NOT NULL,
    ctype VARCHAR(50) NOT NULL,
    "serviceType" VARCHAR(100) NOT NULL, -- official service type identifier
    "officialId" VARCHAR(100) NOT NULL, -- government/NGO official identifier
    "phoneHash" VARCHAR(64), -- encrypted/hashed phone for verification
    url TEXT,
    hours VARCHAR(100),
    priority INTEGER DEFAULT 0,
    "isActive" BOOLEAN DEFAULT TRUE,
    "isVerified" BOOLEAN DEFAULT FALSE, -- verified official source
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== NOTIFICATIONS & DEVICES =====

CREATE TABLE push_tokens (
    id BIGSERIAL PRIMARY KEY,
    "userId" VARCHAR(36) NOT NULL,
    platform VARCHAR(20) NOT NULL,
    token TEXT NOT NULL UNIQUE,
    "isActive" BOOLEAN DEFAULT TRUE,
    "lastUsed" TIMESTAMP,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE notifications (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200),
    body TEXT NOT NULL,
    data JSONB,
    "scheduledFor" TIMESTAMP,
    "expiresAt" TIMESTAMP,
    "isActive" BOOLEAN DEFAULT TRUE,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notification_devices (
    id BIGSERIAL PRIMARY KEY,
    "userId" VARCHAR(36) NOT NULL,
    "deviceId" VARCHAR(255) NOT NULL,
    platform VARCHAR(20) NOT NULL,
    "pushToken" TEXT,
    settings JSONB,
    "isActive" BOOLEAN DEFAULT TRUE,
    "lastSeen" TIMESTAMP,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE notification_deliveries (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    "notificationId" VARCHAR(36) NOT NULL,
    "userId" VARCHAR(36),
    "deviceId" BIGINT,
    status VARCHAR(20) DEFAULT 'pending',
    "deliveredAt" TIMESTAMP,
    "readAt" TIMESTAMP,
    "failureReason" TEXT,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("notificationId") REFERENCES notifications(id) ON DELETE CASCADE,
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY ("deviceId") REFERENCES notification_devices(id) ON DELETE SET NULL
);

-- ===== MONETIZATION =====

CREATE TABLE purchases (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    "userId" VARCHAR(36) NOT NULL,
    "productId" VARCHAR(100) NOT NULL,
    "transactionId" VARCHAR(255) UNIQUE,
    platform VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    amount DECIMAL(10,2),
    currency VARCHAR(10) DEFAULT 'USD',
    "purchasedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "expiryDate" TIMESTAMP,
    "renewedAt" TIMESTAMP,
    "revenuecatId" VARCHAR(255),
    "originalJson" JSONB,
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE
);

-- ===== GDPR COMPLIANCE & AUDIT =====

-- Audit table for GDPR compliance - "right to be forgotten" and PII access tracking
CREATE TABLE data_processing_audit (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    "userId" VARCHAR(36),
    "sessionId" VARCHAR(36),
    operation VARCHAR(50) NOT NULL, -- access, modify, delete, anonymize, export
    "dataType" VARCHAR(50) NOT NULL, -- user_profile, chat_data, safety_logs, etc.
    "legalBasis" VARCHAR(50) NOT NULL, -- consent, legitimate_interest, vital_interest
    purpose VARCHAR(100) NOT NULL, -- service_provision, safety_monitoring, etc.
    "processorId" VARCHAR(36), -- who processed the data
    "ipAddress" VARCHAR(45),
    "userAgent" TEXT,
    "retentionDays" INTEGER, -- planned retention period
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- For right to be forgotten
    "isDeleted" BOOLEAN DEFAULT FALSE,
    "deletedAt" TIMESTAMP,
    "deletionReason" VARCHAR(100), -- user_request, retention_expired, etc.
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE SET NULL
);

-- User data requests (GDPR Article 15-22)
CREATE TABLE user_data_requests (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    "userId" VARCHAR(36) NOT NULL,
    "requestType" VARCHAR(50) NOT NULL, -- access, rectification, erasure, portability, restriction
    status VARCHAR(20) NOT NULL, -- pending, processing, completed, rejected
    reason TEXT,
    "submittedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "processedAt" TIMESTAMP,
    "completedAt" TIMESTAMP,
    "processorId" VARCHAR(36), -- admin who processed the request
    response TEXT, -- response details or rejection reason
    -- For data export
    "exportUrl" TEXT, -- temporary signed URL for data export
    "expiresAt" TIMESTAMP, -- when export link expires
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE
);

-- ===== INDEXES =====

-- Core indexes
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_ageGroup ON users("ageGroup");
CREATE INDEX idx_users_dataRetention ON users("dataRetentionUntil");

-- Chat indexes
CREATE INDEX idx_chat_sessions_userId ON chat_sessions("userId");
CREATE INDEX idx_chat_messages_sessionId ON chat_messages("sessionId");
CREATE INDEX idx_chat_messages_deleteAfter ON chat_messages("deleteAfter");

-- Safety indexes
CREATE INDEX idx_safety_logs_flag ON safety_logs(flag);
CREATE INDEX idx_safety_logs_createdAt ON safety_logs("createdAt");
CREATE INDEX idx_safety_logs_riskCategory ON safety_logs("riskCategory");
CREATE INDEX idx_safety_logs_deleteAfter ON safety_logs("deleteAfter");

-- Content indexes
CREATE INDEX idx_articles_isPublished ON articles("isPublished");
CREATE INDEX idx_articles_category ON articles(category);
CREATE INDEX idx_articles_ageGroup ON articles("ageGroup");

-- SOS indexes
CREATE INDEX idx_sos_contacts_country_locale ON sos_contacts(country, locale);
CREATE INDEX idx_sos_contacts_isActive ON sos_contacts("isActive");
CREATE INDEX idx_sos_contacts_serviceType ON sos_contacts("serviceType");

-- Notification indexes
CREATE INDEX idx_push_tokens_userId ON push_tokens("userId");
CREATE INDEX idx_notifications_scheduledFor ON notifications("scheduledFor");
CREATE INDEX idx_notification_devices_userId_isActive ON notification_devices("userId", "isActive");

-- Purchase indexes
CREATE INDEX idx_purchases_userId_status ON purchases("userId", status);

-- GDPR audit indexes
CREATE INDEX idx_audit_userId ON data_processing_audit("userId");
CREATE INDEX idx_audit_operation ON data_processing_audit(operation);
CREATE INDEX idx_audit_createdAt ON data_processing_audit("createdAt");
CREATE INDEX idx_audit_isDeleted ON data_processing_audit("isDeleted");

CREATE INDEX idx_requests_userId ON user_data_requests("userId");
CREATE INDEX idx_requests_status ON user_data_requests(status);
CREATE INDEX idx_requests_requestType ON user_data_requests("requestType");

-- ===== TRIGGERS & FUNCTIONS =====

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sos_contacts_updated_at BEFORE UPDATE ON sos_contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON articles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_push_tokens_updated_at BEFORE UPDATE ON push_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notification_devices_updated_at BEFORE UPDATE ON notification_devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_remote_config_updated_at BEFORE UPDATE ON remote_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- TTL trigger function for automatic data deletion scheduling
CREATE OR REPLACE FUNCTION schedule_data_deletion()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'chat_messages' THEN
        NEW."deleteAfter" = NEW."createdAt" + INTERVAL '90 days';
    ELSIF TG_TABLE_NAME = 'safety_logs' THEN
        NEW."deleteAfter" = NEW."createdAt" + INTERVAL '30 days';
    ELSIF TG_TABLE_NAME = 'feedback' THEN
        NEW."deleteAfter" = NEW."createdAt" + INTERVAL '90 days';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply TTL triggers
CREATE TRIGGER trigger_chat_messages_ttl
    BEFORE INSERT ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION schedule_data_deletion();

CREATE TRIGGER trigger_safety_logs_ttl
    BEFORE INSERT ON safety_logs
    FOR EACH ROW EXECUTE FUNCTION schedule_data_deletion();

CREATE TRIGGER trigger_feedback_ttl
    BEFORE INSERT ON feedback
    FOR EACH ROW EXECUTE FUNCTION schedule_data_deletion();

COMMIT;