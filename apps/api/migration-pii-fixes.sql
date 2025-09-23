-- PII Compliance and GDPR Fixes Migration
-- Generated from updated Prisma schema

-- Backup existing data before modifications
CREATE TABLE IF NOT EXISTS migration_backup_users AS
SELECT id, role, "createdAt", "updatedAt", tz, locale,
       EXTRACT(YEAR FROM birthdate) as birth_year,
       CASE
         WHEN EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM birthdate) <= 12 THEN 'child'
         WHEN EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM birthdate) <= 15 THEN 'teen'
         ELSE 'young_adult'
       END as age_group,
       "consentVersion"
FROM users WHERE birthdate IS NOT NULL;

-- Update User table for PII compliance
ALTER TABLE users
DROP COLUMN IF EXISTS birthdate CASCADE,
ADD COLUMN "birthYear" INTEGER,
ADD COLUMN "ageGroup" VARCHAR(20),
ADD COLUMN "dataRetentionUntil" TIMESTAMP;

-- Restore data with privacy-friendly fields
UPDATE users SET
  "birthYear" = backup.birth_year,
  "ageGroup" = backup.age_group
FROM migration_backup_users backup
WHERE users.id = backup.id;

-- Update ChatMessage for content limits and TTL
ALTER TABLE chat_messages
ALTER COLUMN content TYPE VARCHAR(2000),
ADD COLUMN "contentHash" VARCHAR(64),
ADD COLUMN "deleteAfter" TIMESTAMP;

-- Update SafetyLog for GDPR compliance
ALTER TABLE safety_logs
DROP COLUMN content,
ADD COLUMN "contentHash" VARCHAR(64),
ADD COLUMN "riskCategory" VARCHAR(50) NOT NULL DEFAULT 'unknown',
ADD COLUMN "severityLevel" VARCHAR(20) NOT NULL DEFAULT 'low',
ADD COLUMN "deleteAfter" TIMESTAMP;

-- Update SosContact to remove PII
ALTER TABLE sos_contacts
DROP COLUMN name,
DROP COLUMN phone,
ADD COLUMN "serviceType" VARCHAR(100) NOT NULL DEFAULT 'emergency',
ADD COLUMN "officialId" VARCHAR(100) NOT NULL DEFAULT 'pending',
ADD COLUMN "phoneHash" VARCHAR(64),
ADD COLUMN "isVerified" BOOLEAN DEFAULT FALSE;

-- Update Feedback for data retention
ALTER TABLE feedback
ALTER COLUMN comment TYPE VARCHAR(2000),
ADD COLUMN "deleteAfter" TIMESTAMP;

-- Create GDPR Audit Tables
CREATE TABLE data_processing_audit (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" VARCHAR(36),
    "sessionId" VARCHAR(36),
    operation VARCHAR(50) NOT NULL,
    "dataType" VARCHAR(50) NOT NULL,
    "legalBasis" VARCHAR(50) NOT NULL,
    purpose VARCHAR(100) NOT NULL,
    "processorId" VARCHAR(36),
    "ipAddress" VARCHAR(45),
    "userAgent" TEXT,
    "retentionDays" INTEGER,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "isDeleted" BOOLEAN DEFAULT FALSE,
    "deletedAt" TIMESTAMP,
    "deletionReason" VARCHAR(100),
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE user_data_requests (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" VARCHAR(36) NOT NULL,
    "requestType" VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    reason TEXT,
    "submittedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "processedAt" TIMESTAMP,
    "completedAt" TIMESTAMP,
    "processorId" VARCHAR(36),
    response TEXT,
    "exportUrl" TEXT,
    "expiresAt" TIMESTAMP,
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for GDPR tables
CREATE INDEX idx_audit_userId ON data_processing_audit("userId");
CREATE INDEX idx_audit_operation ON data_processing_audit(operation);
CREATE INDEX idx_audit_createdAt ON data_processing_audit("createdAt");
CREATE INDEX idx_audit_isDeleted ON data_processing_audit("isDeleted");

CREATE INDEX idx_requests_userId ON user_data_requests("userId");
CREATE INDEX idx_requests_status ON user_data_requests(status);
CREATE INDEX idx_requests_requestType ON user_data_requests("requestType");

-- Add new indexes for updated tables
CREATE INDEX idx_safety_logs_riskCategory ON safety_logs("riskCategory");
CREATE INDEX idx_sos_contacts_serviceType ON sos_contacts("serviceType");

-- Set TTL for existing data (90 days for chats, 30 days for safety logs)
UPDATE chat_messages SET "deleteAfter" = "createdAt" + INTERVAL '90 days';
UPDATE safety_logs SET "deleteAfter" = "createdAt" + INTERVAL '30 days';
UPDATE feedback SET "deleteAfter" = "createdAt" + INTERVAL '90 days';

-- Clean up backup table
DROP TABLE migration_backup_users;

-- Add trigger for automatic TTL management
CREATE OR REPLACE FUNCTION schedule_data_deletion() RETURNS TRIGGER AS $$
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