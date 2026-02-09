-- Notification Delivery Logs Schema Migration
-- Tables: notification_delivery_logs

-- 1. Types
DROP TYPE IF EXISTS public.notification_delivery_status CASCADE;
CREATE TYPE public.notification_delivery_status AS ENUM ('pending', 'delivered', 'failed', 'deferred');

DROP TYPE IF EXISTS public.notification_severity CASCADE;
CREATE TYPE public.notification_severity AS ENUM ('high', 'medium', 'low');

-- 2. Notification Delivery Logs Table
CREATE TABLE IF NOT EXISTS public.notification_delivery_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL,
    severity public.notification_severity NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    scheduled_time TIMESTAMPTZ NOT NULL,
    delivery_status public.notification_delivery_status DEFAULT 'pending'::public.notification_delivery_status,
    retry_count INTEGER DEFAULT 0,
    last_retry_time TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    failed_reason TEXT,
    deferred_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id ON public.notification_delivery_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_status ON public.notification_delivery_logs(delivery_status);
CREATE INDEX IF NOT EXISTS idx_notification_logs_scheduled_time ON public.notification_delivery_logs(scheduled_time);
CREATE INDEX IF NOT EXISTS idx_notification_logs_created_at ON public.notification_delivery_logs(created_at);

-- 4. Enable RLS
ALTER TABLE public.notification_delivery_logs ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
DROP POLICY IF EXISTS "users_manage_own_notification_logs" ON public.notification_delivery_logs;
CREATE POLICY "users_manage_own_notification_logs"
ON public.notification_delivery_logs
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
