-- CreateEnum
CREATE TYPE "Status" AS ENUM ('draft', 'published', 'archived');

-- CreateEnum
CREATE TYPE "ChannelType" AS ENUM ('whatsapp', 'simulator');

-- CreateEnum
CREATE TYPE "MessageDirection" AS ENUM ('in', 'out');

-- CreateEnum
CREATE TYPE "OutboxStatus" AS ENUM ('pending', 'sending', 'sent', 'failed');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "flows" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "flows_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "flow_versions" (
    "id" UUID NOT NULL,
    "flow_id" UUID NOT NULL,
    "number" INTEGER NOT NULL,
    "status" "Status" NOT NULL DEFAULT 'draft',
    "definition" JSONB NOT NULL,
    "published_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "flow_versions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "channels" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" "ChannelType" NOT NULL,
    "external_id" TEXT,

    CONSTRAINT "channels_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "contacts" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "channel_type" "ChannelType" NOT NULL,
    "external_id" TEXT NOT NULL,
    "display_name" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "contacts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "conversations" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "contact_id" UUID NOT NULL,
    "flow_version_id" UUID NOT NULL,
    "current_block_id" TEXT,
    "variables" JSONB NOT NULL,
    "started_at" TIMESTAMPTZ(3) NOT NULL,
    "last_customer_message_at" TIMESTAMPTZ(3) NOT NULL,
    "finished_at" TIMESTAMPTZ(3),

    CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "messages" (
    "id" UUID NOT NULL,
    "conversation_id" UUID NOT NULL,
    "direction" "MessageDirection" NOT NULL,
    "content" TEXT NOT NULL,
    "external_id" TEXT,
    "block_id" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "outbox" (
    "id" UUID NOT NULL,
    "message_id" UUID NOT NULL,
    "status" "OutboxStatus" NOT NULL DEFAULT 'pending',
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "next_attempt_at" TIMESTAMPTZ(3) NOT NULL,
    "locked_until" TIMESTAMPTZ(3),
    "last_error" TEXT,

    CONSTRAINT "outbox_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "flows_user_id_key" ON "flows"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "one_published_version" ON "flow_versions"("flow_id") WHERE "status" = 'published';

-- CreateIndex
CREATE UNIQUE INDEX "flow_versions_flow_id_number_key" ON "flow_versions"("flow_id", "number");

-- CreateIndex
CREATE UNIQUE INDEX "channels_type_external_id_key" ON "channels"("type", "external_id");

-- CreateIndex
CREATE UNIQUE INDEX "contacts_user_id_channel_type_external_id_key" ON "contacts"("user_id", "channel_type", "external_id");

-- CreateIndex
CREATE UNIQUE INDEX "contacts_id_user_id_key" ON "contacts"("id", "user_id");

-- CreateIndex
CREATE INDEX "conversations_user_id_last_customer_message_at_idx" ON "conversations"("user_id", "last_customer_message_at");

-- CreateIndex
CREATE INDEX "conversations_contact_id_started_at_idx" ON "conversations"("contact_id", "started_at");

-- CreateIndex
CREATE INDEX "messages_conversation_id_created_at_idx" ON "messages"("conversation_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "dedup_incoming" ON "messages"("external_id") WHERE "external_id" IS NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "outbox_message_id_key" ON "outbox"("message_id");

-- CreateIndex
CREATE INDEX "outbox_status_next_attempt_at_idx" ON "outbox"("status", "next_attempt_at");

-- AddForeignKey
ALTER TABLE "flows" ADD CONSTRAINT "flows_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "flow_versions" ADD CONSTRAINT "flow_versions_flow_id_fkey" FOREIGN KEY ("flow_id") REFERENCES "flows"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "channels" ADD CONSTRAINT "channels_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contacts" ADD CONSTRAINT "contacts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_flow_version_id_fkey" FOREIGN KEY ("flow_version_id") REFERENCES "flow_versions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_contact_id_user_id_fkey" FOREIGN KEY ("contact_id", "user_id") REFERENCES "contacts"("id", "user_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "outbox" ADD CONSTRAINT "outbox_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
