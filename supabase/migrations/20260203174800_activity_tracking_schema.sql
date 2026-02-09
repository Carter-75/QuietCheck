-- Activity Tracking Schema Migration
-- Tables: activity_tracking_records, app_usage_records

-- 1. Types
DROP TYPE IF EXISTS public.activity_pattern_type CASCADE;
CREATE TYPE public.activity_pattern_type AS ENUM ('focused', 'distracted', 'multitasking', 'idle');

-- 2. Activity Tracking Records Table
CREATE TABLE IF NOT EXISTS public.activity_tracking_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    tracking_date DATE NOT NULL,
    total_screen_time_minutes INTEGER NOT NULL DEFAULT 0,
    app_switch_count INTEGER NOT NULL DEFAULT 0,
    app_switch_velocity DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    focus_sessions_count INTEGER DEFAULT 0,
    focus_duration_minutes INTEGER DEFAULT 0,
    activity_pattern public.activity_pattern_type DEFAULT 'idle'::public.activity_pattern_type,
    battery_level_start INTEGER CHECK (battery_level_start >= 0 AND battery_level_start <= 100),
    battery_level_end INTEGER CHECK (battery_level_end >= 0 AND battery_level_end <= 100),
    data_collection_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. App Usage Records Table (aggregated per app per day)
CREATE TABLE IF NOT EXISTS public.app_usage_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    tracking_date DATE NOT NULL,
    app_package_name TEXT NOT NULL,
    app_name TEXT,
    usage_duration_minutes INTEGER NOT NULL DEFAULT 0,
    open_count INTEGER DEFAULT 0,
    last_used_timestamp TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, tracking_date, app_package_name)
);

-- 4. Indexes
CREATE INDEX IF NOT EXISTS idx_activity_tracking_user_id ON public.activity_tracking_records(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_tracking_date ON public.activity_tracking_records(tracking_date);
CREATE INDEX IF NOT EXISTS idx_activity_tracking_timestamp ON public.activity_tracking_records(data_collection_timestamp);
CREATE INDEX IF NOT EXISTS idx_app_usage_user_id ON public.app_usage_records(user_id);
CREATE INDEX IF NOT EXISTS idx_app_usage_date ON public.app_usage_records(tracking_date);
CREATE INDEX IF NOT EXISTS idx_app_usage_package ON public.app_usage_records(app_package_name);

-- 5. Enable RLS
ALTER TABLE public.activity_tracking_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_usage_records ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
DROP POLICY IF EXISTS "users_manage_own_activity_tracking" ON public.activity_tracking_records;
CREATE POLICY "users_manage_own_activity_tracking"
ON public.activity_tracking_records
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_app_usage" ON public.app_usage_records;
CREATE POLICY "users_manage_own_app_usage"
ON public.app_usage_records
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 7. Mock Data
DO $$
DECLARE
    demo_user_uuid UUID;
    today_date DATE := CURRENT_DATE;
BEGIN
    -- Get demo user ID
    SELECT id INTO demo_user_uuid FROM auth.users WHERE email = 'demo@quietcheck.app' LIMIT 1;
    
    IF demo_user_uuid IS NOT NULL THEN
        -- Insert sample activity tracking records (last 7 days)
        FOR i IN 0..6 LOOP
            INSERT INTO public.activity_tracking_records (
                user_id, tracking_date, total_screen_time_minutes, app_switch_count,
                app_switch_velocity, focus_sessions_count, focus_duration_minutes,
                activity_pattern, battery_level_start, battery_level_end
            ) VALUES (
                demo_user_uuid,
                today_date - i,
                180 + (i * 15),
                45 + (i * 5),
                2.5 + (i * 0.3),
                3 + (i % 2),
                90 + (i * 10),
                CASE 
                    WHEN i % 4 = 0 THEN 'focused'::public.activity_pattern_type
                    WHEN i % 4 = 1 THEN 'distracted'::public.activity_pattern_type
                    WHEN i % 4 = 2 THEN 'multitasking'::public.activity_pattern_type
                    ELSE 'idle'::public.activity_pattern_type
                END,
                100 - (i * 5),
                85 - (i * 5)
            )
            ON CONFLICT DO NOTHING;
        END LOOP;
        
        -- Insert sample app usage records for today
        INSERT INTO public.app_usage_records (
            user_id, tracking_date, app_package_name, app_name,
            usage_duration_minutes, open_count, last_used_timestamp
        ) VALUES 
            (demo_user_uuid, today_date, 'com.example.email', 'Email', 45, 12, NOW() - INTERVAL '1 hour'),
            (demo_user_uuid, today_date, 'com.example.browser', 'Browser', 90, 8, NOW() - INTERVAL '30 minutes'),
            (demo_user_uuid, today_date, 'com.example.social', 'Social Media', 60, 25, NOW() - INTERVAL '15 minutes'),
            (demo_user_uuid, today_date, 'com.example.productivity', 'Productivity', 120, 5, NOW() - INTERVAL '2 hours')
        ON CONFLICT (user_id, tracking_date, app_package_name) DO NOTHING;
    END IF;
END;
$$;