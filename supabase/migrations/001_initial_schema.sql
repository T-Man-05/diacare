-- ============================================================================
-- DIACARE SUPABASE MIGRATION - Initial Schema
-- ============================================================================
-- 
-- This migration creates the complete PostgreSQL schema for DiaCare.
-- It converts the SQLite schema to Supabase-optimized PostgreSQL with:
-- - UUID primary keys linked to auth.users
-- - Proper constraints and indexes
-- - Row Level Security policies
--
-- Run this in Supabase SQL Editor or via migrations
-- ============================================================================

-- ============================================================================
-- EXTENSIONS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- PROFILES TABLE (extends auth.users)
-- ============================================================================
-- Links to Supabase Auth - stores additional user profile data
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    username TEXT NOT NULL,
    full_name TEXT DEFAULT '',
    profile_image_url TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('Male', 'Female', 'Other', NULL)),
    height DECIMAL(5,2),  -- in cm, max 999.99
    weight DECIMAL(5,2),  -- in kg, max 999.99
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for email lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- ============================================================================
-- DIABETIC PROFILES TABLE
-- ============================================================================
-- Stores diabetes-specific configuration for each user
CREATE TABLE IF NOT EXISTS public.diabetic_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    diabetic_type TEXT NOT NULL DEFAULT 'Type 1' 
        CHECK (diabetic_type IN ('Type 1', 'Type 2', 'Gestational', 'Prediabetes', 'Other')),
    treatment_type TEXT NOT NULL DEFAULT 'Insulin'
        CHECK (treatment_type IN ('Insulin', 'Medication', 'Diet', 'Exercise', 'Combination')),
    min_glucose INTEGER NOT NULL DEFAULT 70 CHECK (min_glucose >= 0 AND min_glucose <= 500),
    max_glucose INTEGER NOT NULL DEFAULT 180 CHECK (max_glucose >= 0 AND max_glucose <= 500),
    diagnosis_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_glucose_range CHECK (min_glucose < max_glucose),
    CONSTRAINT unique_user_profile UNIQUE (user_id)
);

-- Create index for user lookups
CREATE INDEX IF NOT EXISTS idx_diabetic_profiles_user ON public.diabetic_profiles(user_id);

-- ============================================================================
-- GLUCOSE READINGS TABLE
-- ============================================================================
-- Stores blood glucose measurements
CREATE TABLE IF NOT EXISTS public.glucose_readings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    value DECIMAL(6,2) NOT NULL CHECK (value >= 0 AND value <= 1000),
    unit TEXT NOT NULL DEFAULT 'mg/dL' CHECK (unit IN ('mg/dL', 'mmol/L')),
    reading_type TEXT NOT NULL DEFAULT 'before_meal'
        CHECK (reading_type IN ('fasting', 'before_meal', 'after_meal', 'bedtime', 'random')),
    notes TEXT,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create composite index for efficient queries
CREATE INDEX IF NOT EXISTS idx_glucose_user_date 
    ON public.glucose_readings(user_id, recorded_at DESC);

-- ============================================================================
-- HEALTH CARDS TABLE
-- ============================================================================
-- Stores daily health metrics (water, pills, activity, carbs, insulin)
CREATE TABLE IF NOT EXISTS public.health_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    card_type TEXT NOT NULL 
        CHECK (card_type IN ('water', 'pills', 'activity', 'carbs', 'insulin')),
    value DECIMAL(10,2) NOT NULL CHECK (value >= 0),
    unit TEXT NOT NULL,
    recorded_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- Unique constraint: one entry per card type per day per user
    CONSTRAINT unique_health_card_per_day UNIQUE (user_id, card_type, recorded_date)
);

-- Create composite index for efficient queries
CREATE INDEX IF NOT EXISTS idx_health_cards_user_date 
    ON public.health_cards(user_id, recorded_date DESC);

-- ============================================================================
-- REMINDERS TABLE
-- ============================================================================
-- Stores medication and activity reminders
CREATE TABLE IF NOT EXISTS public.reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    reminder_type TEXT NOT NULL
        CHECK (reminder_type IN ('medication', 'glucose', 'water', 'exercise', 'meal', 'custom')),
    scheduled_time TIME NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    recurrence_pattern TEXT 
        CHECK (recurrence_pattern IN ('hourly', 'daily', 'weekly', 'monthly', NULL)),
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'done', 'not_done', 'skipped', 'completed')),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create composite index for efficient queries
CREATE INDEX IF NOT EXISTS idx_reminders_user_time 
    ON public.reminders(user_id, scheduled_time);
CREATE INDEX IF NOT EXISTS idx_reminders_status 
    ON public.reminders(user_id, status) WHERE is_enabled = TRUE;

-- ============================================================================
-- USER PREFERENCES TABLE
-- ============================================================================
-- Stores user preferences (synced from device)
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    theme TEXT NOT NULL DEFAULT 'light' CHECK (theme IN ('light', 'dark', 'system')),
    locale TEXT NOT NULL DEFAULT 'en' CHECK (locale IN ('en', 'fr', 'ar')),
    units TEXT NOT NULL DEFAULT 'mg/dL' CHECK (units IN ('mg/dL', 'mmol/L')),
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    biometric_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_preferences UNIQUE (user_id)
);

-- Create index for user lookups
CREATE INDEX IF NOT EXISTS idx_user_preferences_user ON public.user_preferences(user_id);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, username, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'full_name', '')
    );
    
    -- Create default diabetic profile
    INSERT INTO public.diabetic_profiles (user_id)
    VALUES (NEW.id);
    
    -- Create default preferences
    INSERT INTO public.user_preferences (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to update updated_at on profiles
DROP TRIGGER IF EXISTS on_profiles_updated ON public.profiles;
CREATE TRIGGER on_profiles_updated
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Trigger to update updated_at on diabetic_profiles
DROP TRIGGER IF EXISTS on_diabetic_profiles_updated ON public.diabetic_profiles;
CREATE TRIGGER on_diabetic_profiles_updated
    BEFORE UPDATE ON public.diabetic_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Trigger to update updated_at on reminders
DROP TRIGGER IF EXISTS on_reminders_updated ON public.reminders;
CREATE TRIGGER on_reminders_updated
    BEFORE UPDATE ON public.reminders
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Trigger to update updated_at on user_preferences
DROP TRIGGER IF EXISTS on_user_preferences_updated ON public.user_preferences;
CREATE TRIGGER on_user_preferences_updated
    BEFORE UPDATE ON public.user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Trigger to create profile on new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diabetic_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.glucose_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PROFILES POLICIES
-- ============================================================================
-- Users can only view and update their own profile

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Note: INSERT is handled by the trigger, DELETE cascades from auth.users

-- ============================================================================
-- DIABETIC PROFILES POLICIES
-- ============================================================================
-- Users can only access their own diabetic profile

DROP POLICY IF EXISTS "Users can view own diabetic profile" ON public.diabetic_profiles;
CREATE POLICY "Users can view own diabetic profile"
    ON public.diabetic_profiles
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own diabetic profile" ON public.diabetic_profiles;
CREATE POLICY "Users can update own diabetic profile"
    ON public.diabetic_profiles
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Note: INSERT is handled by the trigger

-- ============================================================================
-- GLUCOSE READINGS POLICIES
-- ============================================================================
-- Users can only CRUD their own glucose readings

DROP POLICY IF EXISTS "Users can view own glucose readings" ON public.glucose_readings;
CREATE POLICY "Users can view own glucose readings"
    ON public.glucose_readings
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own glucose readings" ON public.glucose_readings;
CREATE POLICY "Users can insert own glucose readings"
    ON public.glucose_readings
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own glucose readings" ON public.glucose_readings;
CREATE POLICY "Users can update own glucose readings"
    ON public.glucose_readings
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own glucose readings" ON public.glucose_readings;
CREATE POLICY "Users can delete own glucose readings"
    ON public.glucose_readings
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- HEALTH CARDS POLICIES
-- ============================================================================
-- Users can only CRUD their own health cards

DROP POLICY IF EXISTS "Users can view own health cards" ON public.health_cards;
CREATE POLICY "Users can view own health cards"
    ON public.health_cards
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own health cards" ON public.health_cards;
CREATE POLICY "Users can insert own health cards"
    ON public.health_cards
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own health cards" ON public.health_cards;
CREATE POLICY "Users can update own health cards"
    ON public.health_cards
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own health cards" ON public.health_cards;
CREATE POLICY "Users can delete own health cards"
    ON public.health_cards
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- REMINDERS POLICIES
-- ============================================================================
-- Users can only CRUD their own reminders

DROP POLICY IF EXISTS "Users can view own reminders" ON public.reminders;
CREATE POLICY "Users can view own reminders"
    ON public.reminders
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own reminders" ON public.reminders;
CREATE POLICY "Users can insert own reminders"
    ON public.reminders
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own reminders" ON public.reminders;
CREATE POLICY "Users can update own reminders"
    ON public.reminders
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own reminders" ON public.reminders;
CREATE POLICY "Users can delete own reminders"
    ON public.reminders
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- USER PREFERENCES POLICIES
-- ============================================================================
-- Users can only access their own preferences

DROP POLICY IF EXISTS "Users can view own preferences" ON public.user_preferences;
CREATE POLICY "Users can view own preferences"
    ON public.user_preferences
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own preferences" ON public.user_preferences;
CREATE POLICY "Users can update own preferences"
    ON public.user_preferences
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Note: INSERT is handled by the trigger

-- ============================================================================
-- GRANTS
-- ============================================================================
-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant table permissions to authenticated users
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, UPDATE ON public.diabetic_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.glucose_readings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.health_cards TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reminders TO authenticated;
GRANT SELECT, UPDATE ON public.user_preferences TO authenticated;

-- Grant sequence usage for UUID generation (if needed)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
