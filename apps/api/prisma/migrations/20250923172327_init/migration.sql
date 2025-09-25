/*
  Warnings:

  - You are about to alter the column `content` on the `chat_messages` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(2000)`.
  - You are about to drop the column `content` on the `safety_logs` table. All the data in the column will be lost.
  - You are about to drop the column `name` on the `sos_contacts` table. All the data in the column will be lost.
  - You are about to drop the column `phone` on the `sos_contacts` table. All the data in the column will be lost.
  - You are about to drop the column `consentFlags` on the `users` table. All the data in the column will be lost.
  - You are about to drop the column `country` on the `users` table. All the data in the column will be lost.
  - You are about to drop the column `nick` on the `users` table. All the data in the column will be lost.
  - You are about to drop the `profiles` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `riskCategory` to the `safety_logs` table without a default value. This is not possible if the table is not empty.
  - Added the required column `severityLevel` to the `safety_logs` table without a default value. This is not possible if the table is not empty.
  - Added the required column `officialId` to the `sos_contacts` table without a default value. This is not possible if the table is not empty.
  - Added the required column `serviceType` to the `sos_contacts` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "notification_devices" DROP CONSTRAINT "notification_devices_userId_fkey";

-- DropForeignKey
ALTER TABLE "profiles" DROP CONSTRAINT "profiles_userId_fkey";

-- AlterTable
ALTER TABLE "chat_messages" ADD COLUMN     "contentHash" TEXT,
ADD COLUMN     "deleteAfter" TIMESTAMP(3),
ALTER COLUMN "content" SET DATA TYPE VARCHAR(2000);

-- AlterTable
ALTER TABLE "safety_logs" DROP COLUMN "content",
ADD COLUMN     "contentHash" TEXT,
ADD COLUMN     "deleteAfter" TIMESTAMP(3),
ADD COLUMN     "riskCategory" TEXT NOT NULL,
ADD COLUMN     "severityLevel" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "sos_contacts" DROP COLUMN "name",
DROP COLUMN "phone",
ADD COLUMN     "isVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "officialId" TEXT NOT NULL,
ADD COLUMN     "phoneHash" TEXT,
ADD COLUMN     "serviceType" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "users" DROP COLUMN "consentFlags",
DROP COLUMN "country",
DROP COLUMN "nick",
ADD COLUMN     "birthYear" INTEGER,
ADD COLUMN     "consentVersion" INTEGER NOT NULL DEFAULT 1,
ADD COLUMN     "dataRetentionUntil" TIMESTAMP(3),
ADD COLUMN     "role" TEXT NOT NULL DEFAULT 'child',
ADD COLUMN     "tz" TEXT,
ALTER COLUMN "ageGroup" DROP NOT NULL,
ALTER COLUMN "locale" SET DEFAULT 'ru';

-- DropTable
DROP TABLE "profiles";

-- CreateTable
CREATE TABLE "guardian_links" (
    "id" BIGSERIAL NOT NULL,
    "guardianId" TEXT NOT NULL,
    "childId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "guardian_links_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "consents" (
    "id" BIGSERIAL NOT NULL,
    "userId" TEXT NOT NULL,
    "givenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "consentType" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "scope" TEXT,
    "meta" JSONB,

    CONSTRAINT "consents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "progress" (
    "id" BIGSERIAL NOT NULL,
    "userId" TEXT NOT NULL,
    "moduleId" TEXT NOT NULL,
    "stepKey" TEXT NOT NULL,
    "state" JSONB,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "progress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sessions" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" TIMESTAMP(3),
    "device" TEXT,
    "appVersion" TEXT,
    "meta" JSONB,

    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "feedback" (
    "id" BIGSERIAL NOT NULL,
    "userId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "rating" INTEGER,
    "category" TEXT,
    "comment" VARCHAR(2000),
    "deleteAfter" TIMESTAMP(3),

    CONSTRAINT "feedback_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "remote_config" (
    "key" TEXT NOT NULL,
    "value" JSONB NOT NULL,
    "description" TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "audience" JSONB,

    CONSTRAINT "remote_config_pkey" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "push_tokens" (
    "id" BIGSERIAL NOT NULL,
    "userId" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastSeenAt" TIMESTAMP(3),

    CONSTRAINT "push_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "data_processing_audit" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "sessionId" TEXT,
    "operation" TEXT NOT NULL,
    "dataType" TEXT NOT NULL,
    "legalBasis" TEXT NOT NULL,
    "purpose" TEXT NOT NULL,
    "processorId" TEXT,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "retentionDays" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "isDeleted" BOOLEAN NOT NULL DEFAULT false,
    "deletedAt" TIMESTAMP(3),
    "deletionReason" TEXT,

    CONSTRAINT "data_processing_audit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_data_requests" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "requestType" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "reason" TEXT,
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "processorId" TEXT,
    "response" TEXT,
    "exportUrl" TEXT,
    "expiresAt" TIMESTAMP(3),

    CONSTRAINT "user_data_requests_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "guardian_links_guardianId_childId_key" ON "guardian_links"("guardianId", "childId");

-- CreateIndex
CREATE UNIQUE INDEX "progress_userId_moduleId_stepKey_key" ON "progress"("userId", "moduleId", "stepKey");

-- CreateIndex
CREATE UNIQUE INDEX "push_tokens_userId_token_key" ON "push_tokens"("userId", "token");

-- CreateIndex
CREATE INDEX "data_processing_audit_userId_idx" ON "data_processing_audit"("userId");

-- CreateIndex
CREATE INDEX "data_processing_audit_operation_idx" ON "data_processing_audit"("operation");

-- CreateIndex
CREATE INDEX "data_processing_audit_createdAt_idx" ON "data_processing_audit"("createdAt");

-- CreateIndex
CREATE INDEX "data_processing_audit_isDeleted_idx" ON "data_processing_audit"("isDeleted");

-- CreateIndex
CREATE INDEX "user_data_requests_userId_idx" ON "user_data_requests"("userId");

-- CreateIndex
CREATE INDEX "user_data_requests_status_idx" ON "user_data_requests"("status");

-- CreateIndex
CREATE INDEX "user_data_requests_requestType_idx" ON "user_data_requests"("requestType");

-- CreateIndex
CREATE INDEX "safety_logs_riskCategory_idx" ON "safety_logs"("riskCategory");

-- CreateIndex
CREATE INDEX "sos_contacts_serviceType_idx" ON "sos_contacts"("serviceType");

-- AddForeignKey
ALTER TABLE "guardian_links" ADD CONSTRAINT "guardian_links_guardianId_fkey" FOREIGN KEY ("guardianId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guardian_links" ADD CONSTRAINT "guardian_links_childId_fkey" FOREIGN KEY ("childId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consents" ADD CONSTRAINT "consents_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "progress" ADD CONSTRAINT "progress_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "safety_logs" ADD CONSTRAINT "safety_logs_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "feedback" ADD CONSTRAINT "feedback_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "push_tokens" ADD CONSTRAINT "push_tokens_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "data_processing_audit" ADD CONSTRAINT "data_processing_audit_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_data_requests" ADD CONSTRAINT "user_data_requests_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
