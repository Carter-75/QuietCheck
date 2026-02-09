-- Crash Tracking and Performance Monitoring Migration
-- Tables: crash_reports, performance_metrics, session_analytics
-- Replaces Firebase Analytics/Crashlytics with Supabase-based tracking

-- 1. Types
DROP TYPE IF EXISTS public.crash_severity CASCADE;
CREATE TYPE public.crash_severity AS ENUM (
    'fatal',
    'error',
    'warning',
    'info'
);

DROP TYPE IF EXISTS public.performance_metric_type CASCADE;
CREATE TYPE public.performance_metric_type AS ENUM (
    'app_startup',
    'screen_load',
    'api_call',
    'database_query',
    'mental_load_calculation',
    'ai_analysis',
    'background_task'
);

DROP TYPE IF EXISTS public.session_status CASCADE;
CREATE TYPE public.session_status AS ENUM (
    'active',
    'ended',
    'crashed'
);

-- 2. Crash Reports Table
CREATE TABLE IF NOT EXISTS public.crash_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    crash_severity public.crash_severity NOT NULL,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    error_type TEXT,
    screen_name TEXT,
    app_version TEXT,
    device_info JSONB,
    os_version TEXT,
    memory_usage_mb INTEGER,
    battery_level INTEGER,
    network_status TEXT,
    user_actions_before_crash JSONB,
    crash_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_resolved BOOLEAN DEFAULT false,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Performance Metrics Table
CREATE TABLE IF NOT EXISTS public.performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    metric_type public.performance_metric_type NOT NULL,
    metric_name TEXT NOT NULL,
    duration_ms INTEGER NOT NULL,
    screen_name TEXT,
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    metadata JSONB,
    device_info JSONB,
    network_type TEXT,
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Session Analytics Table
CREATE TABLE IF NOT EXISTS public.session_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    session_id UUID NOT NULL,
    session_status public.session_status NOT NULL DEFAULT 'active',
    session_start TIMESTAMPTZ NOT NULL,
    session_end TIMESTAMPTZ,
    duration_seconds INTEGER,
    screens_visited TEXT[],
    features_used TEXT[],
    events_count INTEGER DEFAULT 0,
    mental_load_checks INTEGER DEFAULT 0,
    recovery_sessions INTEGER DEFAULT 0,
    app_version TEXT,
    device_info JSONB,
    crash_occurred BOOLEAN DEFAULT false,
    crash_report_id UUID REFERENCES public.crash_reports(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Indexes
CREATE INDEX IF NOT EXISTS idx_crash_reports_user_id ON public.crash_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_crash_reports_severity ON public.crash_reports(crash_severity);
CREATE INDEX IF NOT EXISTS idx_crash_reports_timestamp ON public.crash_reports(crash_timestamp);
CREATE INDEX IF NOT EXISTS idx_crash_reports_resolved ON public.crash_reports(is_resolved);
CREATE INDEX IF NOT EXISTS idx_crash_reports_screen ON public.crash_reports(screen_name);

CREATE INDEX IF NOT EXISTS idx_performance_metrics_user_id ON public.performance_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_type ON public.performance_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_recorded ON public.performance_metrics(recorded_at);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_screen ON public.performance_metrics(screen_name);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_success ON public.performance_metrics(success);

CREATE INDEX IF NOT EXISTS idx_session_analytics_user_id ON public.session_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_session_analytics_session_id ON public.session_analytics(session_id);
CREATE INDEX IF NOT EXISTS idx_session_analytics_status ON public.session_analytics(session_status);
CREATE INDEX IF NOT EXISTS idx_session_analytics_start ON public.session_analytics(session_start);
CREATE INDEX IF NOT EXISTS idx_session_analytics_crash ON public.session_analytics(crash_occurred);

-- 6. Enable RLS
ALTER TABLE public.crash_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_analytics ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies
DROP POLICY IF EXISTS "users_manage_own_crash_reports" ON public.crash_reports;
CREATE POLICY "users_manage_own_crash_reports"
ON public.crash_reports
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_performance_metrics" ON public.performance_metrics;
CREATE POLICY "users_manage_own_performance_metrics"
ON public.performance_metrics
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_session_analytics" ON public.session_analytics;
CREATE POLICY "users_manage_own_session_analytics"
ON public.session_analytics
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 8. Helper Functions
CREATE OR REPLACE FUNCTION public.update_session_analytics_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    -- Calculate duration if session ended
    IF NEW.session_status = 'ended' AND NEW.session_end IS NOT NULL THEN
        NEW.duration_seconds := EXTRACT(EPOCH FROM (NEW.session_end - NEW.session_start))::INTEGER;
    END IF;
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_session_analytics_timestamp_trigger ON public.session_analytics;
CREATE TRIGGER update_session_analytics_timestamp_trigger
BEFORE UPDATE ON public.session_analytics
FOR EACH ROW
EXECUTE FUNCTION public.update_session_analytics_timestamp();

-- 9. Mock Data
DO $$
DECLARE
    demo_user_uuid UUID;
    demo_session_uuid UUID := gen_random_uuid();
    demo_crash_uuid UUID;
BEGIN
    -- Get demo user ID
    SELECT id INTO demo_user_uuid FROM auth.users WHERE email = 'demo@quietcheck.app' LIMIT 1;
    
    IF demo_user_uuid IS NOT NULL THEN
        -- Insert sample crash reports
        INSERT INTO public.crash_reports (
            user_id, crash_severity, error_message, stack_trace, error_type, 
            screen_name, app_version, device_info, os_version, crash_timestamp
        )
        VALUES
            (
                demo_user_uuid, 
                'error'::public.crash_severity, 
                'Failed to load mental load data', 
                'at DataService.fetchMentalLoadScores (data_service.dart:145)\nat DashboardScreen.loadData (dashboard_initial_page.dart:89)', 
                'NetworkException',
                'dashboard',
                '1.0.0',
                '{"model": "Pixel 7", "manufacturer": "Google"}',
                'Android 14',
                CURRENT_TIMESTAMP - INTERVAL '2 days'
            ),
            (
                demo_user_uuid,
                'warning'::public.crash_severity,
                'Slow API response detected',
                'at GeminiService.analyzeBurnoutRisk (gemini_service.dart:78)',
                'TimeoutWarning',
                'analytics_view',
                '1.0.0',
                '{"model": "Pixel 7", "manufacturer": "Google"}',
                'Android 14',
                CURRENT_TIMESTAMP - INTERVAL '1 day'
            )
        ON CONFLICT (id) DO NOTHING
        RETURNING id INTO demo_crash_uuid;

        -- Insert sample performance metrics
        INSERT INTO public.performance_metrics (
            user_id, metric_type, metric_name, duration_ms, screen_name, 
            success, metadata, recorded_at
        )
        VALUES
            (
                demo_user_uuid,
                'screen_load'::public.performance_metric_type,
                'Dashboard Load',
                1250,
                'dashboard',
                true,
                '{"widgets_loaded": 6, "data_sources": 3}',
                CURRENT_TIMESTAMP - INTERVAL '1 hour'
            ),
            (
                demo_user_uuid,
                'mental_load_calculation'::public.performance_metric_type,
                'Mental Load Score Calculation',
                340,
                'dashboard',
                true,
                '{"data_points": 150, "algorithm_version": "2.1"}',
                CURRENT_TIMESTAMP - INTERVAL '45 minutes'
            ),
            (
                demo_user_uuid,
                'ai_analysis'::public.performance_metric_type,
                'Gemini Burnout Analysis',
                2800,
                'analytics_view',
                true,
                '{"tokens_used": 450, "model": "gemini-pro"}',
                CURRENT_TIMESTAMP - INTERVAL '30 minutes'
            ),
            (
                demo_user_uuid,
                'api_call'::public.performance_metric_type,
                'Supabase Query',
                180,
                'dashboard',
                true,
                '{"query_type": "mental_load_scores", "rows_returned": 24}',
                CURRENT_TIMESTAMP - INTERVAL '20 minutes'
            )
        ON CONFLICT (id) DO NOTHING;

        -- Insert sample session analytics
        INSERT INTO public.session_analytics (
            user_id, session_id, session_status, session_start, session_end,
            screens_visited, features_used, events_count, mental_load_checks,
            recovery_sessions, app_version, device_info
        )
        VALUES
            (
                demo_user_uuid,
                demo_session_uuid,
                'ended'::public.session_status,
                CURRENT_TIMESTAMP - INTERVAL '2 hours',
                CURRENT_TIMESTAMP - INTERVAL '1 hour 30 minutes',
                ARRAY['splash_screen', 'dashboard', 'analytics_view', 'recovery_guidance'],
                ARRAY['mental_load_check', 'breathing_exercise', 'trend_analysis'],
                15,
                3,
                1,
                '1.0.0',
                '{"model": "Pixel 7", "manufacturer": "Google", "os": "Android 14"}'
            ),
            (
                demo_user_uuid,
                gen_random_uuid(),
                'active'::public.session_status,
                CURRENT_TIMESTAMP - INTERVAL '30 minutes',
                NULL,
                ARRAY['splash_screen', 'dashboard'],
                ARRAY['mental_load_check'],
                5,
                1,
                0,
                '1.0.0',
                '{"model": "Pixel 7", "manufacturer": "Google", "os": "Android 14"}'
            )
        ON CONFLICT (id) DO NOTHING;
    ELSE
        RAISE NOTICE 'Demo user not found. Run mental health data migration first.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;