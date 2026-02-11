-- QuietCheck Supabase Schema
-- Generated based on DataService.dart usage

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Mental Load Scores
create table if not exists mental_load_scores (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) not null,
    score integer not null,
    zone text not null,
    encrypted_context text,
    recorded_at timestamp with time zone default now()
);

-- 2. User Settings
create table if not exists user_settings (
    user_id uuid references auth.users(id) primary key,
    theme_mode text default 'system',
    notifications_enabled boolean default true,
    data_collection_enabled boolean default true,
    last_updated timestamp with time zone default now()
    -- Add other settings fields as needed based on JSON model
);

-- 3. Analytics Records
create table if not exists analytics_records (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) not null,
    date date not null,
    avg_mental_load numeric,
    peak_mental_load integer,
    baseline_comparison numeric,
    data jsonb default '{}'::jsonb, -- Store complex nested data
    unique(user_id, date)
);

-- 4. Subscription Data
create table if not exists subscription_data (
    user_id uuid references auth.users(id) primary key,
    tier text default 'free',
    status text default 'active',
    valid_until timestamp with time zone,
    features jsonb default '[]'::jsonb
);

-- 5. Billing History
create table if not exists billing_history (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) not null,
    transaction_date timestamp with time zone default now(),
    amount numeric not null,
    currency text default 'USD',
    description text,
    status text default 'completed'
);

-- 6. Recovery Sessions
create table if not exists recovery_sessions (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) not null,
    session_date timestamp with time zone default now(),
    duration_seconds integer,
    type text,
    effectiveness_score integer,
    notes text
);

-- 7. Activity Tracking Records
create table if not exists activity_tracking_records (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) not null,
    tracking_date date not null,
    total_screen_time_minutes integer default 0,
    app_switch_count integer default 0,
    app_switch_velocity numeric default 0,
    focus_sessions_count integer default 0,
    focus_duration_minutes integer default 0,
    activity_pattern text,
    data_collection_timestamp timestamp with time zone default now(),
    unique(user_id, tracking_date)
);

-- 8. Burnout Predictions
create table if not exists burnout_predictions (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) not null,
    prediction_timestamp timestamp with time zone default now(),
    predicted_threshold_date timestamp with time zone,
    current_mental_load_score integer,
    predicted_mental_load_score integer,
    hours_until_threshold integer,
    confidence_level text,
    identified_triggers text[],
    behavioral_patterns text[],
    warning_sent boolean default false,
    warning_sent_at timestamp with time zone
);

-- 9. App Usage Records
create table if not exists app_usage_records (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) not null,
    tracking_date date not null,
    app_name text,
    app_package_name text,
    usage_duration_minutes integer default 0,
    open_count integer default 0,
    unique(user_id, tracking_date, app_package_name)
);

-- 10. Wellness Goals
create table if not exists wellness_goals (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) not null,
    title text not null,
    description text,
    category text,
    current_value integer default 0,
    target_value integer not null,
    unit text,
    current_streak integer default 0,
    longest_streak integer default 0,
    start_date timestamp with time zone default now(),
    target_date timestamp with time zone,
    last_progress_date date,
    status text default 'active', -- active, completed, abandoned
    completed_at timestamp with time zone,
    created_at timestamp with time zone default now()
);

-- 11. Goal Progress Logs
create table if not exists goal_progress_logs (
    id uuid default uuid_generate_v4() primary key,
    goal_id uuid references wellness_goals(id) on delete cascade,
    user_id uuid references auth.users(id) not null,
    progress_value integer not null,
    notes text,
    logged_at timestamp with time zone default now()
);

-- 12. Goal Milestones
create table if not exists goal_milestones (
    id uuid default uuid_generate_v4() primary key,
    goal_id uuid references wellness_goals(id) on delete cascade,
    user_id uuid references auth.users(id) not null,
    milestone_type text, -- goal_completion, streak_achievement
    title text,
    description text,
    achievement_value integer,
    achieved_at timestamp with time zone default now(),
    celebrated boolean default false
);

-- 13. Goal AI Recommendations
create table if not exists goal_ai_recommendations (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) not null,
    goal_id uuid references wellness_goals(id) on delete cascade,
    recommendation_text text,
    priority integer default 0,
    generated_at timestamp with time zone default now(),
    dismissed boolean default false
);

-- ROW LEVEL SECURITY (RLS) POLICIES
-- Enabling RLS on all tables
alter table mental_load_scores enable row level security;
alter table user_settings enable row level security;
alter table analytics_records enable row level security;
alter table subscription_data enable row level security;
alter table billing_history enable row level security;
alter table recovery_sessions enable row level security;
alter table activity_tracking_records enable row level security;
alter table burnout_predictions enable row level security;
alter table app_usage_records enable row level security;
alter table wellness_goals enable row level security;
alter table goal_progress_logs enable row level security;
alter table goal_milestones enable row level security;
alter table goal_ai_recommendations enable row level security;

-- Basic policy: Users can only see and modify their own data
-- Policies allow users to select, insert, and update rows where user_id matches their auth.uid()

-- 1. Mental Load Scores
create policy "Users can view their own mental load scores" on mental_load_scores for select using (auth.uid() = user_id);
create policy "Users can insert their own mental load scores" on mental_load_scores for insert with check (auth.uid() = user_id);
create policy "Users can update their own mental load scores" on mental_load_scores for update using (auth.uid() = user_id);

-- 2. User Settings
create policy "Users can view their own settings" on user_settings for select using (auth.uid() = user_id);
create policy "Users can insert their own settings" on user_settings for insert with check (auth.uid() = user_id);
create policy "Users can update their own settings" on user_settings for update using (auth.uid() = user_id);

-- 3. Analytics Records
create policy "Users can view their own analytics" on analytics_records for select using (auth.uid() = user_id);
create policy "Users can insert their own analytics" on analytics_records for insert with check (auth.uid() = user_id);
create policy "Users can update their own analytics" on analytics_records for update using (auth.uid() = user_id);

-- 4. Subscription Data
create policy "Users can view their own subscription" on subscription_data for select using (auth.uid() = user_id);
create policy "Users can insert their own subscription" on subscription_data for insert with check (auth.uid() = user_id);
create policy "Users can update their own subscription" on subscription_data for update using (auth.uid() = user_id);

-- 5. Billing History
create policy "Users can view their own billing" on billing_history for select using (auth.uid() = user_id);
create policy "Users can insert their own billing" on billing_history for insert with check (auth.uid() = user_id);

-- 6. Recovery Sessions
create policy "Users can view their own recovery sessions" on recovery_sessions for select using (auth.uid() = user_id);
create policy "Users can insert their own recovery sessions" on recovery_sessions for insert with check (auth.uid() = user_id);
create policy "Users can update their own recovery sessions" on recovery_sessions for update using (auth.uid() = user_id);

-- 7. Activity Tracking Records
create policy "Users can view their own activity logs" on activity_tracking_records for select using (auth.uid() = user_id);
create policy "Users can insert their own activity logs" on activity_tracking_records for insert with check (auth.uid() = user_id);
create policy "Users can update their own activity logs" on activity_tracking_records for update using (auth.uid() = user_id);

-- 8. Burnout Predictions
create policy "Users can view their own predictions" on burnout_predictions for select using (auth.uid() = user_id);
create policy "Users can insert their own predictions" on burnout_predictions for insert with check (auth.uid() = user_id);
create policy "Users can update their own predictions" on burnout_predictions for update using (auth.uid() = user_id);

-- 9. App Usage Records
create policy "Users can view their own app usage" on app_usage_records for select using (auth.uid() = user_id);
create policy "Users can insert their own app usage" on app_usage_records for insert with check (auth.uid() = user_id);
create policy "Users can update their own app usage" on app_usage_records for update using (auth.uid() = user_id);

-- 10. Wellness Goals
create policy "Users can view their own goals" on wellness_goals for select using (auth.uid() = user_id);
create policy "Users can insert their own goals" on wellness_goals for insert with check (auth.uid() = user_id);
create policy "Users can update their own goals" on wellness_goals for update using (auth.uid() = user_id);

-- 11. Goal Progress Logs
create policy "Users can view their own goal logs" on goal_progress_logs for select using (auth.uid() = user_id);
create policy "Users can insert their own goal logs" on goal_progress_logs for insert with check (auth.uid() = user_id);

-- 12. Goal Milestones
create policy "Users can view their own milestones" on goal_milestones for select using (auth.uid() = user_id);
create policy "Users can insert their own milestones" on goal_milestones for insert with check (auth.uid() = user_id);
create policy "Users can update their own milestones" on goal_milestones for update using (auth.uid() = user_id);

-- 13. Goal AI Recommendations
create policy "Users can view their own AI recommendations" on goal_ai_recommendations for select using (auth.uid() = user_id);
-- AI Recommendations are usually generated by server/edge functions, but if client generates them:
create policy "Users can insert their own AI recommendations" on goal_ai_recommendations for insert with check (auth.uid() = user_id);
create policy "Users can update their own AI recommendations" on goal_ai_recommendations for update using (auth.uid() = user_id);
