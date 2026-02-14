-- #####################################################################
-- # HABIT TRACKER - FULL DATABASE SCHEMA
-- #####################################################################
--
-- This file contains the complete database schema for the Habit Tracker app.
-- It consolidates the base schema, all migrations/updates, and seed data.
--
-- SECTIONS:
-- 1. Base Tables & RLS (Habits, Completions, Categories)
-- 2. Feature Extenstions (Streaks, Reminders, Category Links)
-- 3. Seed Data (Optional dummy data)

-- #####################################################################
-- # 1. BASE TABLES & RLS
-- #####################################################################

-- Habits Table
CREATE TABLE IF NOT EXISTS public.habits (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  icon_asset text NOT NULL,
  color_hex text NOT NULL,
  frequency text NOT NULL CHECK (frequency IN ('daily', 'weekly')),
  reminder_time time without time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  archived boolean NOT NULL DEFAULT false,
  CONSTRAINT habits_pkey PRIMARY KEY (id)
);

-- Habit Completions Table
CREATE TABLE IF NOT EXISTS public.habit_completions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  habit_id uuid NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  completed_date date NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT habit_completions_pkey PRIMARY KEY (id),
  CONSTRAINT unique_completion_per_day UNIQUE (habit_id, completed_date)
);

-- Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  icon text,
  color_hex text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT categories_pkey PRIMARY KEY (id)
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------
-- RLS Policies
-- ---------------------------------------------------------------------

-- Habits Policies
CREATE POLICY "Users can view their own habits" ON public.habits
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own habits" ON public.habits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own habits" ON public.habits
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own habits" ON public.habits
  FOR DELETE USING (auth.uid() = user_id);

-- Completions Policies
CREATE POLICY "Users can view their own completions" ON public.habit_completions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own completions" ON public.habit_completions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own completions" ON public.habit_completions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own completions" ON public.habit_completions
  FOR DELETE USING (auth.uid() = user_id);

-- Categories Policies
CREATE POLICY "Users can view their own categories" ON public.categories
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own categories" ON public.categories
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own categories" ON public.categories
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own categories" ON public.categories
  FOR DELETE USING (auth.uid() = user_id);


-- #####################################################################
-- # 2. FEATURE EXTENSIONS & MIGRATIONS
-- #####################################################################

-- ---------------------------------------------------------------------
-- A. Category Linkage (Relationships)
-- ---------------------------------------------------------------------
-- Add category_id to habits table if it doesn't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'habits' AND column_name = 'category_id') THEN
        ALTER TABLE public.habits 
        ADD COLUMN category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL;
        
        -- Create index for performance
        CREATE INDEX idx_habits_category_id ON public.habits(category_id);
    END IF;
END $$;

-- ---------------------------------------------------------------------
-- B. Streak Tracking (Stats)
-- ---------------------------------------------------------------------
-- Add streak columns to habits table
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'habits' AND column_name = 'current_streak') THEN
        ALTER TABLE public.habits 
        ADD COLUMN current_streak INTEGER NOT NULL DEFAULT 0,
        ADD COLUMN longest_streak INTEGER NOT NULL DEFAULT 0,
        ADD COLUMN last_completed_date DATE;
    END IF;
END $$;

-- Streak History Table
CREATE TABLE IF NOT EXISTS public.streak_history (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    streak_count INTEGER NOT NULL,
    started_date DATE NOT NULL,
    ended_date DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT streak_history_pkey PRIMARY KEY (id)
);

-- RLS for Streak History
ALTER TABLE public.streak_history ENABLE ROW LEVEL SECURITY;

-- Drop existng policies to avoid errors if re-running
DROP POLICY IF EXISTS "Users can view their own streak history" ON public.streak_history;
DROP POLICY IF EXISTS "Users can insert their own streak history" ON public.streak_history;
DROP POLICY IF EXISTS "Users can update their own streak history" ON public.streak_history;
DROP POLICY IF EXISTS "Users can delete their own streak history" ON public.streak_history;

CREATE POLICY "Users can view their own streak history" ON public.streak_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own streak history" ON public.streak_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own streak history" ON public.streak_history
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own streak history" ON public.streak_history
    FOR DELETE USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- C. Notifications (Reminders)
-- ---------------------------------------------------------------------
-- Add reminder fields
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'habits' AND column_name = 'reminder_enabled') THEN
        ALTER TABLE habits 
        ADD COLUMN reminder_enabled BOOLEAN DEFAULT false;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'habits' AND column_name = 'reminder_time') THEN
        -- check if it already exists (it was nullable without time zone in base, might be updated here)
        -- In base schema: reminder_time time without time zone created.
        -- This block re-affirms it or adds if missing.
        NULL; -- Already handled or present
    ELSE
        ALTER TABLE habits ADD COLUMN reminder_time TIME;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'habits' AND column_name = 'reminder_days') THEN
        ALTER TABLE habits 
        ADD COLUMN reminder_days INTEGER[];
        
        COMMENT ON COLUMN habits.reminder_enabled IS 'Whether reminder notifications are enabled for this habit';
        COMMENT ON COLUMN habits.reminder_time IS 'Time of day to send reminder notification (HH:MM:SS format)';
        COMMENT ON COLUMN habits.reminder_days IS 'Array of day numbers (0=Sunday, 6=Saturday) when reminders should be sent';
    END IF;
END $$;


-- #####################################################################
-- # 3. SEED DATA (OPTIONAL)
-- #####################################################################
-- Uncomment the block below to insert dummy data for testing.
-- Replace 'TARGET_USER_ID_HERE' with your actual Supabase User ID.

/*
DO $$
DECLARE
    target_user_id uuid := 'TARGET_USER_ID_HERE'; -- <--- REPLACE THIS
    habit_run_id uuid;
    habit_water_id uuid;
    habit_read_id uuid;
    habit_meditate_id uuid;
    habit_code_id uuid;
    habit_clean_id uuid;
BEGIN
    -- 1. Clean up existing data for this user
    DELETE FROM public.habit_completions WHERE user_id = target_user_id;
    DELETE FROM public.habit_streak_history WHERE user_id = target_user_id; -- if exists
    DELETE FROM public.habits WHERE user_id = target_user_id;

    RAISE NOTICE 'Cleared old data for user: %', target_user_id;

    -- 2. Insert Habits
    INSERT INTO public.habits (user_id, name, description, icon_asset, color_hex, frequency, reminder_time)
    VALUES (target_user_id, 'Morning Run', '5km run around the park', '🏃', '#FF5722', 'daily', '06:30:00'::time)
    RETURNING id INTO habit_run_id;

    INSERT INTO public.habits (user_id, name, description, icon_asset, color_hex, frequency, reminder_time)
    VALUES (target_user_id, 'Drink 2L Water', 'Stay hydrated throughout the day', '💧', '#2196F3', 'daily', NULL)
    RETURNING id INTO habit_water_id;

    -- ... Add more habits as needed from original dummy_data.sql ...
    
    RAISE NOTICE 'Dummy data inserted.';
END $$;
*/
