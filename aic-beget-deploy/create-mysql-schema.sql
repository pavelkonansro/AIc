-- AIc Application MySQL Database Schema
-- Privacy-by-design architecture for teen users (9-18 years)
-- COPPA & GDPR compliant with minimal PII storage

-- Set character set and collation
SET NAMES utf8mb4;
SET character_set_client = utf8mb4;

-- Create database (if needed)
-- CREATE DATABASE IF NOT EXISTS aic_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE aic_app;

-- ===== CORE USER TABLES =====

-- Main users table - minimal PII
CREATE TABLE users (
    id CHAR(36) PRIMARY KEY, -- UUID v4
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255), -- NULL for guest users
    is_guest BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_is_guest (is_guest),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- User profiles - age-sensitive data
CREATE TABLE profiles (
    id CHAR(36) PRIMARY KEY, -- UUID v4
    user_id CHAR(36) NOT NULL,
    age_group ENUM('9-12', '13-15', '16-18') NOT NULL,
    birth_date DATE NOT NULL, -- For age verification only
    country CHAR(2) NOT NULL DEFAULT 'CZ', -- ISO country code for GDPR
    preferred_language CHAR(5) DEFAULT 'cs-CZ', -- ISO locale
    settings JSON, -- User preferences, themes, etc.
    personality_data JSON, -- AI personality insights (anonymized)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_age_group (age_group),
    INDEX idx_country (country)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ===== CONSENT & GUARDIAN SYSTEM =====

-- Consent management for minors
CREATE TABLE consents (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    consent_type ENUM('parental', 'data_processing', 'marketing') NOT NULL,
    granted BOOLEAN NOT NULL DEFAULT FALSE,
    granted_at TIMESTAMP NULL,
    revoked_at TIMESTAMP NULL,
    ip_address VARCHAR(45), -- For audit trail
    user_agent TEXT, -- For audit trail
    expires_at TIMESTAMP NULL, -- TTL for consent
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_consent (user_id, consent_type),
    INDEX idx_user_consent (user_id, consent_type),
    INDEX idx_granted (granted),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Guardian-child relationships
CREATE TABLE guardian_links (
    id CHAR(36) PRIMARY KEY,
    guardian_email VARCHAR(255) NOT NULL,
    child_user_id CHAR(36) NOT NULL,
    verification_token VARCHAR(255),
    verified_at TIMESTAMP NULL,
    relationship_type ENUM('parent', 'legal_guardian', 'other') DEFAULT 'parent',
    permissions JSON, -- What guardian can access/control
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (child_user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_guardian_email (guardian_email),
    INDEX idx_child_user_id (child_user_id),
    INDEX idx_verified_at (verified_at)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ===== CHAT & AI INTERACTION =====

-- Chat sessions with AI companion
CREATE TABLE chat_sessions (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    title VARCHAR(255), -- User-generated or AI-suggested title
    mood_tag VARCHAR(50), -- happy, sad, anxious, etc.
    session_type ENUM('casual', 'support', 'crisis') DEFAULT 'casual',
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP NULL,
    message_count INT DEFAULT 0,
    safety_level ENUM('safe', 'monitored', 'flagged') DEFAULT 'safe',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_type (session_type),
    INDEX idx_safety_level (safety_level),
    INDEX idx_started_at (started_at)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Individual chat messages
CREATE TABLE chat_messages (
    id CHAR(36) PRIMARY KEY,
    session_id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    content TEXT NOT NULL, -- Message content (encrypted in production)
    message_type ENUM('user', 'ai', 'system') NOT NULL,
    safety_flags JSON, -- AI safety analysis results
    emotion_analysis JSON, -- AI emotional analysis
    response_time_ms INT, -- AI response time for analytics
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_session_id (session_id),
    INDEX idx_user_id (user_id),
    INDEX idx_message_type (message_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ===== SAFETY & MODERATION =====

-- Safety incident logging
CREATE TABLE safety_logs (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36),
    session_id CHAR(36),
    incident_type ENUM('inappropriate_content', 'crisis_detected', 'spam', 'other') NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
    content_hash VARCHAR(64), -- SHA256 hash for duplicate detection
    ai_confidence DECIMAL(3,2), -- 0.00-1.00 confidence in detection
    human_reviewed BOOLEAN DEFAULT FALSE,
    action_taken ENUM('none', 'warning', 'content_blocked', 'session_ended', 'account_suspended') DEFAULT 'none',
    review_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_incident_type (incident_type),
    INDEX idx_severity (severity),
    INDEX idx_created_at (created_at),
    INDEX idx_human_reviewed (human_reviewed)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ===== CONTENT & RESOURCES =====

-- Educational/support articles
CREATE TABLE articles (
    id CHAR(36) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    content LONGTEXT NOT NULL,
    excerpt TEXT,
    category ENUM('emotions', 'relationships', 'school', 'health', 'safety', 'other') NOT NULL,
    target_age_groups SET('9-12', '13-15', '16-18') NOT NULL,
    language CHAR(5) NOT NULL DEFAULT 'cs-CZ',
    published BOOLEAN DEFAULT FALSE,
    featured BOOLEAN DEFAULT FALSE,
    view_count INT DEFAULT 0,
    published_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_category (category),
    INDEX idx_language (language),
    INDEX idx_published (published),
    INDEX idx_published_at (published_at),
    INDEX idx_slug (slug)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crisis support contacts by country/region
CREATE TABLE sos_contacts (
    id CHAR(36) PRIMARY KEY,
    country CHAR(2) NOT NULL, -- ISO country code
    region VARCHAR(100), -- State/province if needed
    organization_name VARCHAR(255) NOT NULL,
    contact_type ENUM('phone', 'chat', 'email', 'website') NOT NULL,
    contact_value VARCHAR(255) NOT NULL, -- Phone/email/URL
    available_hours VARCHAR(100), -- "24/7", "Mon-Fri 9-17", etc.
    languages SET('cs', 'sk', 'en', 'de') NOT NULL,
    specialization SET('suicide', 'abuse', 'mental_health', 'general') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_country (country),
    INDEX idx_contact_type (contact_type),
    INDEX idx_is_active (is_active),
    INDEX idx_specialization (specialization)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ===== GAMIFICATION & ENGAGEMENT =====

-- User achievements and progress
CREATE TABLE user_achievements (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    achievement_type ENUM('first_chat', 'daily_streak', 'article_reader', 'emotion_tracker', 'helper') NOT NULL,
    achievement_data JSON, -- Streak count, articles read, etc.
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_achievement (user_id, achievement_type),
    INDEX idx_user_id (user_id),
    INDEX idx_achievement_type (achievement_type)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ===== SUBSCRIPTIONS & BILLING =====

-- User subscriptions (freemium model)
CREATE TABLE subscriptions (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    plan_type ENUM('free', 'premium') NOT NULL DEFAULT 'free',
    status ENUM('active', 'cancelled', 'expired', 'suspended') NOT NULL DEFAULT 'active',
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    payment_provider ENUM('revenuecat', 'stripe', 'paypal') NULL,
    external_subscription_id VARCHAR(255), -- Provider's subscription ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_expires_at (expires_at),
    INDEX idx_external_id (external_subscription_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ===== ANALYTICS & SYSTEM =====

-- Anonymous usage analytics
CREATE TABLE usage_analytics (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36), -- NULL for anonymous events
    event_type VARCHAR(100) NOT NULL, -- 'app_open', 'chat_start', 'article_view', etc.
    event_data JSON, -- Additional event parameters
    session_id VARCHAR(255), -- App session ID
    platform ENUM('ios', 'android', 'web') NOT NULL,
    app_version VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_event_type (event_type),
    INDEX idx_platform (platform),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ===== SAMPLE DATA FOR TESTING =====

-- Insert sample SOS contacts for Czech Republic
INSERT INTO sos_contacts (id, country, organization_name, contact_type, contact_value, available_hours, languages, specialization, is_active) VALUES
(UUID(), 'CZ', 'Linka bezpečí', 'phone', '+420116111', '24/7', 'cs', 'general,mental_health', TRUE),
(UUID(), 'CZ', 'Linka důvěry Ostrava', 'phone', '+420596618908', '24/7', 'cs', 'suicide,mental_health', TRUE),
(UUID(), 'CZ', 'Bílý kruh bezpečí', 'phone', '+420257317110', '24/7', 'cs', 'abuse', TRUE);

-- Insert sample articles
INSERT INTO articles (id, title, slug, content, excerpt, category, target_age_groups, language, published, published_at) VALUES
(UUID(), 'Jak zvládnout stres ve škole', 'jak-zvladnout-stres-ve-skole', 'Obsah článku o zvládání stresu...', 'Tipy pro lepší zvládání školního stresu', 'school', '13-15,16-18', 'cs-CZ', TRUE, NOW()),
(UUID(), 'Komunikace s rodiči', 'komunikace-s-rodici', 'Obsah článku o komunikaci...', 'Jak lépe komunikovat s rodiči', 'relationships', '13-15,16-18', 'cs-CZ', TRUE, NOW());

-- Create indexes for performance optimization
-- (Additional indexes can be added based on query patterns)

-- Show created tables
SELECT 
    TABLE_NAME as 'Table Name',
    TABLE_ROWS as 'Estimated Rows',
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) as 'Size (MB)'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME;

-- Success message
SELECT 
    '✅ AIc Database Schema Created Successfully!' as Status,
    COUNT(*) as 'Total Tables'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE();