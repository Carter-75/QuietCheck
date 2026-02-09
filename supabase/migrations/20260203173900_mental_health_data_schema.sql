-- Mental Health Data Schema Migration
-- Tables: user_profiles, mental_load_scores, user_settings, analytics_records, subscription_data, recovery_sessions

-- 1. Types
DROP TYPE IF EXISTS public.user_role CASCADE;
CREATE TYPE public.user_role AS ENUM ('user', 'premium');

DROP TYPE IF EXISTS public.mental_load_zone CASCADE;
CREATE TYPE public.mental_load_zone AS ENUM ('optimal', 'moderate', 'elevated', 'critical');

DROP TYPE IF EXISTS public.subscription_status CASCADE;
CREATE TYPE public.subscription_status AS ENUM ('trial', 'active', 'expired', 'cancelled');

DROP TYPE IF EXISTS public.recovery_technique_type CASCADE;
CREATE TYPE public.recovery_technique_type AS ENUM ('breathing', 'muscle_relaxation', 'grounding', 'mindful_observation');

-- 2. Core Tables
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    role public.user_role DEFAULT 'user'::public.user_role,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.mental_load_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
    zone public.mental_load_zone NOT NULL,
    encrypted_context TEXT,
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    sensitivity_value DOUBLE PRECISION DEFAULT 50.0 CHECK (sensitivity_value >= 0 AND sensitivity_value <= 100),
    selected_sound_pack TEXT DEFAULT 'Calming Waves',
    quiet_hours_start TIME DEFAULT '22:00:00',
    quiet_hours_end TIME DEFAULT '07:00:00',
    high_severity_notifications BOOLEAN DEFAULT true,
    medium_severity_notifications BOOLEAN DEFAULT true,
    low_severity_notifications BOOLEAN DEFAULT false,
    vibration_enabled BOOLEAN DEFAULT true,
    encrypted_preferences TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.analytics_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    avg_mental_load DOUBLE PRECISION NOT NULL,
    peak_mental_load INTEGER NOT NULL,
    data_points_collected INTEGER DEFAULT 0,
    baseline_comparison DOUBLE PRECISION,
    sleep_quality INTEGER CHECK (sleep_quality >= 0 AND sleep_quality <= 100),
    encrypted_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.subscription_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status public.subscription_status DEFAULT 'trial'::public.subscription_status,
    trial_days_remaining INTEGER DEFAULT 7,
    subscription_start_date TIMESTAMPTZ,
    next_payment_date DATE,
    encrypted_payment_info TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.billing_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    transaction_date DATE NOT NULL,
    amount TEXT NOT NULL,
    status TEXT DEFAULT 'Completed',
    encrypted_receipt_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.recovery_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    technique_type public.recovery_technique_type NOT NULL,
    technique_title TEXT NOT NULL,
    duration_minutes INTEGER NOT NULL,
    completed BOOLEAN DEFAULT false,
    elapsed_time_seconds INTEGER DEFAULT 0,
    session_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    encrypted_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_id ON public.user_profiles(id);
CREATE INDEX IF NOT EXISTS idx_mental_load_scores_user_id ON public.mental_load_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_mental_load_scores_recorded_at ON public.mental_load_scores(recorded_at);
CREATE INDEX IF NOT EXISTS idx_analytics_records_user_id ON public.analytics_records(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_records_date ON public.analytics_records(date);
CREATE INDEX IF NOT EXISTS idx_recovery_sessions_user_id ON public.recovery_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_billing_history_user_id ON public.billing_history(user_id);

-- 4. Functions
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'user'::public.user_role)
    );
    
    -- Create default user settings
    INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id);
    
    -- Create default subscription data (trial)
    INSERT INTO public.subscription_data (user_id, status, trial_days_remaining)
    VALUES (NEW.id, 'trial'::public.subscription_status, 7);
    
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- 5. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mental_load_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recovery_sessions ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_mental_load_scores" ON public.mental_load_scores;
CREATE POLICY "users_manage_own_mental_load_scores"
ON public.mental_load_scores
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_user_settings" ON public.user_settings;
CREATE POLICY "users_manage_own_user_settings"
ON public.user_settings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_analytics_records" ON public.analytics_records;
CREATE POLICY "users_manage_own_analytics_records"
ON public.analytics_records
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_subscription_data" ON public.subscription_data;
CREATE POLICY "users_manage_own_subscription_data"
ON public.subscription_data
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_billing_history" ON public.billing_history;
CREATE POLICY "users_manage_own_billing_history"
ON public.billing_history
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_recovery_sessions" ON public.recovery_sessions;
CREATE POLICY "users_manage_own_recovery_sessions"
ON public.recovery_sessions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 7. Triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_user_settings_updated_at ON public.user_settings;
CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_subscription_data_updated_at ON public.subscription_data;
CREATE TRIGGER update_subscription_data_updated_at
    BEFORE UPDATE ON public.subscription_data
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- 8. Mock Data
DO $$
DECLARE
    demo_user_uuid UUID := gen_random_uuid();
    today_date DATE := CURRENT_DATE;
BEGIN
    -- Create demo auth user (trigger creates user_profiles, user_settings, subscription_data automatically)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (demo_user_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'demo@quietcheck.com', crypt('demo123', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Demo User'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null)
    ON CONFLICT (id) DO NOTHING;

    -- Mental load scores (last 7 days)
    INSERT INTO public.mental_load_scores (user_id, score, zone, recorded_at) VALUES
        (demo_user_uuid, 45, 'moderate'::public.mental_load_zone, now() - INTERVAL '6 days'),
        (demo_user_uuid, 62, 'moderate'::public.mental_load_zone, now() - INTERVAL '5 days'),
        (demo_user_uuid, 78, 'elevated'::public.mental_load_zone, now() - INTERVAL '4 days'),
        (demo_user_uuid, 55, 'moderate'::public.mental_load_zone, now() - INTERVAL '3 days'),
        (demo_user_uuid, 70, 'elevated'::public.mental_load_zone, now() - INTERVAL '2 days'),
        (demo_user_uuid, 35, 'optimal'::public.mental_load_zone, now() - INTERVAL '1 day'),
        (demo_user_uuid, 40, 'optimal'::public.mental_load_zone, now())
    ON CONFLICT (id) DO NOTHING;

    -- Analytics records (last 7 days)
    INSERT INTO public.analytics_records (user_id, date, avg_mental_load, peak_mental_load, data_points_collected, baseline_comparison, sleep_quality) VALUES
        (demo_user_uuid, today_date - 6, 45.0, 52, 24, -5.0, 75),
        (demo_user_uuid, today_date - 5, 62.0, 68, 24, 7.0, 65),
        (demo_user_uuid, today_date - 4, 78.0, 85, 24, 18.0, 50),
        (demo_user_uuid, today_date - 3, 55.0, 62, 24, -3.0, 70),
        (demo_user_uuid, today_date - 2, 70.0, 78, 24, 5.0, 55),
        (demo_user_uuid, today_date - 1, 35.0, 42, 24, -5.0, 85),
        (demo_user_uuid, today_date, 40.0, 48, 18, -2.0, 80)
    ON CONFLICT (id) DO NOTHING;

    -- Billing history
    INSERT INTO public.billing_history (user_id, transaction_date, amount, status) VALUES
        (demo_user_uuid, today_date - 30, '$1.99', 'Completed'),
        (demo_user_uuid, today_date - 60, '$1.99', 'Completed'),
        (demo_user_uuid, today_date - 90, '$1.99', 'Completed')
    ON CONFLICT (id) DO NOTHING;

    -- Recovery sessions
    INSERT INTO public.recovery_sessions (user_id, technique_type, technique_title, duration_minutes, completed, elapsed_time_seconds) VALUES
        (demo_user_uuid, 'breathing'::public.recovery_technique_type, 'Box Breathing', 5, true, 300),
        (demo_user_uuid, 'muscle_relaxation'::public.recovery_technique_type, 'Progressive Muscle Relaxation', 15, true, 900),
        (demo_user_uuid, 'grounding'::public.recovery_technique_type, 'Grounding Exercise (5-4-3-2-1)', 7, false, 240)
    ON CONFLICT (id) DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;