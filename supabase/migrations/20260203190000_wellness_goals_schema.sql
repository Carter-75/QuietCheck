-- Wellness Goals Schema Migration
-- Creates tables for goal setting, progress tracking, milestone celebrations, and AI recommendations

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Goal categories enum
DO $$ BEGIN
  CREATE TYPE goal_category AS ENUM (
    'stress_reduction',
    'sleep_improvement',
    'mindfulness_practice',
    'work_life_balance',
    'physical_activity',
    'social_connection',
    'custom'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Goal status enum
DO $$ BEGIN
  CREATE TYPE goal_status AS ENUM (
    'active',
    'completed',
    'paused',
    'abandoned'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Milestone type enum
DO $$ BEGIN
  CREATE TYPE milestone_type AS ENUM (
    'streak_achievement',
    'progress_milestone',
    'goal_completion',
    'consistency_badge'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Wellness Goals Table
CREATE TABLE IF NOT EXISTS public.wellness_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category goal_category NOT NULL DEFAULT 'custom',
  target_value INTEGER NOT NULL,
  current_value INTEGER NOT NULL DEFAULT 0,
  unit TEXT NOT NULL DEFAULT 'sessions',
  status goal_status NOT NULL DEFAULT 'active',
  start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  target_date TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  last_progress_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Progress Log Table
CREATE TABLE IF NOT EXISTS public.goal_progress_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  goal_id UUID NOT NULL REFERENCES public.wellness_goals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  progress_value INTEGER NOT NULL,
  notes TEXT,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Milestones Table
CREATE TABLE IF NOT EXISTS public.goal_milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  goal_id UUID NOT NULL REFERENCES public.wellness_goals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  milestone_type milestone_type NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  achievement_value INTEGER NOT NULL,
  achieved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  celebrated BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- AI Recommendations Table
CREATE TABLE IF NOT EXISTS public.goal_ai_recommendations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  goal_id UUID REFERENCES public.wellness_goals(id) ON DELETE CASCADE,
  recommendation_text TEXT NOT NULL,
  reasoning TEXT,
  priority INTEGER NOT NULL DEFAULT 1,
  applied BOOLEAN NOT NULL DEFAULT FALSE,
  dismissed BOOLEAN NOT NULL DEFAULT FALSE,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_wellness_goals_user_id ON public.wellness_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_wellness_goals_status ON public.wellness_goals(status);
CREATE INDEX IF NOT EXISTS idx_wellness_goals_target_date ON public.wellness_goals(target_date);
CREATE INDEX IF NOT EXISTS idx_goal_progress_logs_goal_id ON public.goal_progress_logs(goal_id);
CREATE INDEX IF NOT EXISTS idx_goal_progress_logs_user_id ON public.goal_progress_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_goal_milestones_goal_id ON public.goal_milestones(goal_id);
CREATE INDEX IF NOT EXISTS idx_goal_milestones_user_id ON public.goal_milestones(user_id);
CREATE INDEX IF NOT EXISTS idx_goal_ai_recommendations_user_id ON public.goal_ai_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_goal_ai_recommendations_goal_id ON public.goal_ai_recommendations(goal_id);

-- RLS Policies
ALTER TABLE public.wellness_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_progress_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_ai_recommendations ENABLE ROW LEVEL SECURITY;

-- Wellness Goals Policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'wellness_goals' AND policyname = 'Users can view their own goals'
  ) THEN
    CREATE POLICY "Users can view their own goals"
      ON public.wellness_goals FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'wellness_goals' AND policyname = 'Users can create their own goals'
  ) THEN
    CREATE POLICY "Users can create their own goals"
      ON public.wellness_goals FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'wellness_goals' AND policyname = 'Users can update their own goals'
  ) THEN
    CREATE POLICY "Users can update their own goals"
      ON public.wellness_goals FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'wellness_goals' AND policyname = 'Users can delete their own goals'
  ) THEN
    CREATE POLICY "Users can delete their own goals"
      ON public.wellness_goals FOR DELETE
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- Goal Progress Logs Policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goal_progress_logs' AND policyname = 'Users can view their own progress logs'
  ) THEN
    CREATE POLICY "Users can view their own progress logs"
      ON public.goal_progress_logs FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goal_progress_logs' AND policyname = 'Users can create their own progress logs'
  ) THEN
    CREATE POLICY "Users can create their own progress logs"
      ON public.goal_progress_logs FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Goal Milestones Policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goal_milestones' AND policyname = 'Users can view their own milestones'
  ) THEN
    CREATE POLICY "Users can view their own milestones"
      ON public.goal_milestones FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goal_milestones' AND policyname = 'Users can create their own milestones'
  ) THEN
    CREATE POLICY "Users can create their own milestones"
      ON public.goal_milestones FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goal_milestones' AND policyname = 'Users can update their own milestones'
  ) THEN
    CREATE POLICY "Users can update their own milestones"
      ON public.goal_milestones FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Goal AI Recommendations Policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goal_ai_recommendations' AND policyname = 'Users can view their own recommendations'
  ) THEN
    CREATE POLICY "Users can view their own recommendations"
      ON public.goal_ai_recommendations FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goal_ai_recommendations' AND policyname = 'Users can create their own recommendations'
  ) THEN
    CREATE POLICY "Users can create their own recommendations"
      ON public.goal_ai_recommendations FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goal_ai_recommendations' AND policyname = 'Users can update their own recommendations'
  ) THEN
    CREATE POLICY "Users can update their own recommendations"
      ON public.goal_ai_recommendations FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for wellness_goals updated_at
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_wellness_goals_updated_at'
  ) THEN
    CREATE TRIGGER update_wellness_goals_updated_at
      BEFORE UPDATE ON public.wellness_goals
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;