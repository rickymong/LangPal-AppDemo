-- ============================================
-- LANGPAL DATABASE SCHEMA
-- Supabase PostgreSQL Database
-- ============================================
-- 
-- HOW TO USE:
-- 1. Go to your Supabase project dashboard
-- 2. Navigate to SQL Editor
-- 3. Paste this entire file
-- 4. Click "Run"
--
-- ============================================

-- ============================================
-- 1. TABLES
-- ============================================

-- User profiles (extends Supabase auth.users)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    profile_image_url TEXT,
    current_language TEXT DEFAULT 'English',
    chat_summary TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Languages the user is learning
CREATE TABLE user_languages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    language TEXT NOT NULL,
    proficiency_level TEXT DEFAULT 'beginner', -- beginner, intermediate, advanced
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, language)
);

-- AI Partners (tutors) - shared reference table
CREATE TABLE ai_partners (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    language TEXT NOT NULL,
    flag_path TEXT NOT NULL,
    personality TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Junction table: User <-> AI Partner relationships
CREATE TABLE user_ai_partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    ai_partner_id TEXT NOT NULL REFERENCES ai_partners(id) ON DELETE CASCADE,
    nickname TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, ai_partner_id)
);

-- Chat messages
CREATE TABLE chat_messages (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    ai_partner_id TEXT NOT NULL REFERENCES ai_partners(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    is_from_user BOOLEAN NOT NULL,
    message_type TEXT DEFAULT 'text', -- text, audio, correction, system
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. INDEXES (for performance)
-- ============================================

CREATE INDEX idx_user_languages_user_id ON user_languages(user_id);
CREATE INDEX idx_user_ai_partners_user_id ON user_ai_partners(user_id);
CREATE INDEX idx_chat_messages_user_ai ON chat_messages(user_id, ai_partner_id);
CREATE INDEX idx_chat_messages_created ON chat_messages(created_at DESC);

-- ============================================
-- 3. FUNCTIONS & TRIGGERS
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Auto-create user_profile when new auth user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NEW.email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ============================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ai_partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_partners ENABLE ROW LEVEL SECURITY;

-- user_profiles policies
CREATE POLICY "Users can view own profile"
    ON user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON user_profiles FOR UPDATE
    USING (auth.uid() = id);

-- user_languages policies
CREATE POLICY "Users can view own languages"
    ON user_languages FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own languages"
    ON user_languages FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own languages"
    ON user_languages FOR DELETE
    USING (auth.uid() = user_id);

-- user_ai_partners policies
CREATE POLICY "Users can view own AI partners"
    ON user_ai_partners FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can add AI partners"
    ON user_ai_partners FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove AI partners"
    ON user_ai_partners FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update AI partner relationship"
    ON user_ai_partners FOR UPDATE
    USING (auth.uid() = user_id);

-- chat_messages policies
CREATE POLICY "Users can view own messages"
    ON chat_messages FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own messages"
    ON chat_messages FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ai_partners policies (read-only for all authenticated users)
CREATE POLICY "Authenticated users can view AI partners"
    ON ai_partners FOR SELECT
    TO authenticated
    USING (true);

-- ============================================
-- 5. SEED DATA - AI Partners
-- ============================================

INSERT INTO ai_partners (id, name, language, flag_path, personality) VALUES
    ('ai_001', 'Sophia', 'Spanish', 'images/flags/spain_flag.jpg', 
     'Friendly and patient Spanish tutor from Madrid. Loves discussing culture, food, and travel.'),
    ('ai_002', 'Yuki', 'Japanese', 'images/flags/japan_flag.png', 
     'Enthusiastic Japanese tutor from Tokyo. Enjoys anime, technology, and traditional arts.'),
    ('ai_003', 'Hans', 'German', 'images/flags/german_flag.jpg', 
     'Precise and encouraging German tutor from Berlin. Passionate about music and engineering.');

-- ============================================
-- 6. HELPFUL VIEWS
-- ============================================

-- View: User's conversations with AI partners (with last message)
CREATE VIEW user_conversations AS
SELECT 
    uap.user_id,
    uap.ai_partner_id,
    ap.name AS ai_name,
    ap.language,
    ap.flag_path,
    uap.nickname,
    uap.is_favorite,
    uap.created_at AS started_at,
    (
        SELECT text 
        FROM chat_messages cm 
        WHERE cm.user_id = uap.user_id 
          AND cm.ai_partner_id = uap.ai_partner_id 
        ORDER BY cm.created_at DESC 
        LIMIT 1
    ) AS last_message,
    (
        SELECT created_at 
        FROM chat_messages cm 
        WHERE cm.user_id = uap.user_id 
          AND cm.ai_partner_id = uap.ai_partner_id 
        ORDER BY cm.created_at DESC 
        LIMIT 1
    ) AS last_message_at,
    (
        SELECT COUNT(*) 
        FROM chat_messages cm 
        WHERE cm.user_id = uap.user_id 
          AND cm.ai_partner_id = uap.ai_partner_id
    ) AS message_count
FROM user_ai_partners uap
JOIN ai_partners ap ON uap.ai_partner_id = ap.id;

-- ============================================
-- 7. STORAGE BUCKET (for profile images)
-- Run this separately in Supabase Dashboard > Storage
-- ============================================

-- To set up storage for profile pictures:
-- 1. Go to Supabase Dashboard > Storage
-- 2. Create a new bucket called "avatars"
-- 3. Make it public (or use signed URLs)
-- 4. Add these policies in SQL Editor:

-- INSERT INTO storage.buckets (id, name, public) 
-- VALUES ('avatars', 'avatars', true);

-- CREATE POLICY "Users can upload own avatar"
--     ON storage.objects FOR INSERT
--     WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- CREATE POLICY "Anyone can view avatars"
--     ON storage.objects FOR SELECT
--     USING (bucket_id = 'avatars');

