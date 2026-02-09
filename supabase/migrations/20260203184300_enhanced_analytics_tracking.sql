-- Enhanced Analytics Tracking Migration
-- Tables: user_engagement_events, feature_adoption_metrics, subscription_conversions, retention_metrics
-- Privacy-compliant analytics for tracking user behavior, feature usage, conversions, and retention

-- 1. Types
DROP TYPE IF EXISTS public.event_type CASCADE;
CREATE TYPE public.event_type AS ENUM (
    'app_open',
    'app_close',
    'screen_view',
    'button_click',
    'feature_used',
    'session_start',
    'session_end',
    'error_occurred'
);

DROP TYPE IF EXISTS public.feature_category CASCADE;
CREATE TYPE public.feature_category AS ENUM (
    'mental_load_tracking',
    'recovery_guidance',
    'analytics_view',
    'settings',
    'subscription'
);

DROP TYPE IF EXISTS public.conversion_stage CASCADE;
CREATE TYPE public.conversion_stage AS ENUM (
    'trial_started',
    'viewed_pricing',
    'initiated_checkout',
    'payment_completed',
    'subscription_active',
    'subscription_cancelled',
    'subscription_renewed'
);

DROP TYPE IF EXISTS public.retention_period CASCADE;
CREATE TYPE public.retention_period AS ENUM (
    'day_1',
    'day_3',
    'day_7',
    'day_14',
    'day_30',
    'day_60',
    'day_90'
);

-- 2. User Engagement Events Table
CREATE TABLE IF NOT EXISTS public.user_engagement_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    event_type public.event_type NOT NULL,
    event_name TEXT NOT NULL,
    screen_name TEXT,
    event_properties JSONB,
    session_id UUID,
    event_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Feature Adoption Metrics Table
CREATE TABLE IF NOT EXISTS public.feature_adoption_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    feature_category public.feature_category NOT NULL,
    feature_name TEXT NOT NULL,
    first_used_at TIMESTAMPTZ NOT NULL,
    last_used_at TIMESTAMPTZ NOT NULL,
    usage_count INTEGER DEFAULT 1,
    total_time_spent_seconds INTEGER DEFAULT 0,
    is_active_user BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, feature_category, feature_name)
);

-- 4. Subscription Conversions Table
CREATE TABLE IF NOT EXISTS public.subscription_conversions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    conversion_stage public.conversion_stage NOT NULL,
    stage_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    days_since_signup INTEGER,
    trial_days_used INTEGER,
    conversion_source TEXT,
    pricing_plan TEXT,
    encrypted_conversion_data JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Retention Metrics Table
CREATE TABLE IF NOT EXISTS public.retention_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    retention_period public.retention_period NOT NULL,
    is_retained BOOLEAN NOT NULL,
    last_active_date DATE NOT NULL,
    sessions_count INTEGER DEFAULT 0,
    total_engagement_minutes INTEGER DEFAULT 0,
    features_used_count INTEGER DEFAULT 0,
    mental_load_checks INTEGER DEFAULT 0,
    recovery_sessions_completed INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, retention_period)
);

-- 6. Indexes
CREATE INDEX IF NOT EXISTS idx_engagement_events_user_id ON public.user_engagement_events(user_id);
CREATE INDEX IF NOT EXISTS idx_engagement_events_type ON public.user_engagement_events(event_type);
CREATE INDEX IF NOT EXISTS idx_engagement_events_timestamp ON public.user_engagement_events(event_timestamp);
CREATE INDEX IF NOT EXISTS idx_engagement_events_session ON public.user_engagement_events(session_id);

CREATE INDEX IF NOT EXISTS idx_feature_adoption_user_id ON public.feature_adoption_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_adoption_category ON public.feature_adoption_metrics(feature_category);
CREATE INDEX IF NOT EXISTS idx_feature_adoption_active ON public.feature_adoption_metrics(is_active_user);

CREATE INDEX IF NOT EXISTS idx_subscription_conversions_user_id ON public.subscription_conversions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_conversions_stage ON public.subscription_conversions(conversion_stage);
CREATE INDEX IF NOT EXISTS idx_subscription_conversions_timestamp ON public.subscription_conversions(stage_timestamp);

CREATE INDEX IF NOT EXISTS idx_retention_metrics_user_id ON public.retention_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_retention_metrics_period ON public.retention_metrics(retention_period);
CREATE INDEX IF NOT EXISTS idx_retention_metrics_retained ON public.retention_metrics(is_retained);

-- 7. Enable RLS
ALTER TABLE public.user_engagement_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_adoption_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_conversions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retention_metrics ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies
DROP POLICY IF EXISTS "users_manage_own_engagement_events" ON public.user_engagement_events;
CREATE POLICY "users_manage_own_engagement_events"
ON public.user_engagement_events
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_view_own_feature_adoption" ON public.feature_adoption_metrics;
CREATE POLICY "users_view_own_feature_adoption"
ON public.feature_adoption_metrics
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_view_own_conversions" ON public.subscription_conversions;
CREATE POLICY "users_view_own_conversions"
ON public.subscription_conversions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_view_own_retention" ON public.retention_metrics;
CREATE POLICY "users_view_own_retention"
ON public.retention_metrics
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- 9. Helper Functions
CREATE OR REPLACE FUNCTION public.calculate_days_since_signup(user_uuid UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT EXTRACT(DAY FROM (CURRENT_TIMESTAMP - up.created_at))::INTEGER
    FROM public.user_profiles up
    WHERE up.id = user_uuid
    LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.update_feature_adoption_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_feature_adoption_timestamp_trigger ON public.feature_adoption_metrics;
CREATE TRIGGER update_feature_adoption_timestamp_trigger
BEFORE UPDATE ON public.feature_adoption_metrics
FOR EACH ROW
EXECUTE FUNCTION public.update_feature_adoption_timestamp();

-- 10. Mock Data
DO $$
DECLARE
    demo_user_uuid UUID;
    session_uuid UUID := gen_random_uuid();
    today_date DATE := CURRENT_DATE;
BEGIN
    -- Get demo user ID
    SELECT id INTO demo_user_uuid FROM auth.users WHERE email = 'demo@quietcheck.app' LIMIT 1;
    
    IF demo_user_uuid IS NOT NULL THEN
        -- Insert sample engagement events
        INSERT INTO public.user_engagement_events (user_id, event_type, event_name, screen_name, session_id, event_timestamp)
        VALUES
            (demo_user_uuid, 'app_open'::public.event_type, 'App Launched', 'splash_screen', session_uuid, CURRENT_TIMESTAMP - INTERVAL '2 hours'),
            (demo_user_uuid, 'screen_view'::public.event_type, 'Dashboard Viewed', 'dashboard', session_uuid, CURRENT_TIMESTAMP - INTERVAL '2 hours'),
            (demo_user_uuid, 'feature_used'::public.event_type, 'Mental Load Check', 'dashboard', session_uuid, CURRENT_TIMESTAMP - INTERVAL '1 hour 45 minutes'),
            (demo_user_uuid, 'screen_view'::public.event_type, 'Analytics Viewed', 'analytics_view', session_uuid, CURRENT_TIMESTAMP - INTERVAL '1 hour 30 minutes'),
            (demo_user_uuid, 'feature_used'::public.event_type, 'Recovery Session Started', 'recovery_guidance', session_uuid, CURRENT_TIMESTAMP - INTERVAL '1 hour'),
            (demo_user_uuid, 'button_click'::public.event_type, 'Subscription Viewed', 'subscription_management', session_uuid, CURRENT_TIMESTAMP - INTERVAL '30 minutes')
        ON CONFLICT (id) DO NOTHING;

        -- Insert feature adoption metrics
        INSERT INTO public.feature_adoption_metrics (user_id, feature_category, feature_name, first_used_at, last_used_at, usage_count, total_time_spent_seconds)
        VALUES
            (demo_user_uuid, 'mental_load_tracking'::public.feature_category, 'Mental Load Gauge', CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '1 hour', 42, 3600),
            (demo_user_uuid, 'recovery_guidance'::public.feature_category, 'Breathing Exercises', CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '1 hour', 15, 2700),
            (demo_user_uuid, 'analytics_view'::public.feature_category, 'Trend Charts', CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '1 hour 30 minutes', 28, 1800),
            (demo_user_uuid, 'settings'::public.feature_category, 'Notification Preferences', CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '2 days', 5, 600)
        ON CONFLICT (user_id, feature_category, feature_name) DO NOTHING;

        -- Insert subscription conversion stages
        INSERT INTO public.subscription_conversions (user_id, conversion_stage, stage_timestamp, days_since_signup, trial_days_used, conversion_source, pricing_plan)
        VALUES
            (demo_user_uuid, 'trial_started'::public.conversion_stage, CURRENT_TIMESTAMP - INTERVAL '7 days', 0, 0, 'onboarding', 'trial'),
            (demo_user_uuid, 'viewed_pricing'::public.conversion_stage, CURRENT_TIMESTAMP - INTERVAL '2 days', 5, 5, 'dashboard_banner', 'premium_monthly')
        ON CONFLICT (id) DO NOTHING;

        -- Insert retention metrics
        INSERT INTO public.retention_metrics (user_id, retention_period, is_retained, last_active_date, sessions_count, total_engagement_minutes, features_used_count, mental_load_checks, recovery_sessions_completed)
        VALUES
            (demo_user_uuid, 'day_1'::public.retention_period, true, today_date, 3, 45, 4, 8, 2),
            (demo_user_uuid, 'day_3'::public.retention_period, true, today_date, 8, 120, 6, 18, 5),
            (demo_user_uuid, 'day_7'::public.retention_period, true, today_date, 15, 240, 8, 42, 15)
        ON CONFLICT (user_id, retention_period) DO NOTHING;
    ELSE
        RAISE NOTICE 'Demo user not found. Run mental health data migration first.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;