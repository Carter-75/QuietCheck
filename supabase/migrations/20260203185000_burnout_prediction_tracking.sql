-- Migration: Burnout Prediction Tracking
-- Purpose: Store predictive burnout analysis results and warning history
-- Created: 2026-02-03 18:50:00

-- 1. Create enum for prediction confidence levels
DO $$ BEGIN
    CREATE TYPE public.prediction_confidence AS ENUM ('low', 'medium', 'high');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Create burnout_predictions table
CREATE TABLE IF NOT EXISTS public.burnout_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    predicted_threshold_date TIMESTAMPTZ NOT NULL,
    current_mental_load_score INTEGER NOT NULL CHECK (current_mental_load_score >= 0 AND current_mental_load_score <= 100),
    predicted_mental_load_score INTEGER NOT NULL CHECK (predicted_mental_load_score >= 0 AND predicted_mental_load_score <= 100),
    hours_until_threshold INTEGER NOT NULL,
    confidence_level public.prediction_confidence NOT NULL,
    identified_triggers JSONB,
    behavioral_patterns JSONB,
    warning_sent BOOLEAN DEFAULT FALSE,
    warning_sent_at TIMESTAMPTZ,
    prediction_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_burnout_predictions_user_id ON public.burnout_predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_burnout_predictions_threshold_date ON public.burnout_predictions(predicted_threshold_date);
CREATE INDEX IF NOT EXISTS idx_burnout_predictions_timestamp ON public.burnout_predictions(prediction_timestamp);
CREATE INDEX IF NOT EXISTS idx_burnout_predictions_warning_sent ON public.burnout_predictions(warning_sent);

-- 4. Enable Row Level Security
ALTER TABLE public.burnout_predictions ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies
CREATE POLICY "Users can view their own burnout predictions"
    ON public.burnout_predictions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own burnout predictions"
    ON public.burnout_predictions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own burnout predictions"
    ON public.burnout_predictions
    FOR UPDATE
    USING (auth.uid() = user_id);

-- 6. Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.burnout_predictions TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;