-- HAAAH Sports Supabase DB Schema (Sunday League Edition)
-- Copy and paste this entirely into the Supabase SQL Editor and hit "Run"
-- WARNING: This will drop existing tables. Do not run in production if you have real data!

DROP TABLE IF EXISTS post_comments CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS tickets CASCADE;
DROP TABLE IF EXISTS games CASCADE;
DROP TABLE IF EXISTS fixtures CASCADE;
DROP TABLE IF EXISTS team_players CASCADE;
DROP TABLE IF EXISTS teams CASCADE;
DROP TABLE IF EXISTS venues CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- 1. Create Users Table (Extended profile linked to Supabase Auth)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    username TEXT,
    position TEXT DEFAULT 'SUB', -- 'GK', 'DEF', 'MID', 'FWD', 'SUB'
    -- Player Stats
    goals INTEGER DEFAULT 0,
    assists INTEGER DEFAULT 0,
    appearances INTEGER DEFAULT 0,
    motm INTEGER DEFAULT 0,
    -- Player Attributes (0-99 scale)
    pace INTEGER DEFAULT 75,
    shooting INTEGER DEFAULT 75,
    dribbling INTEGER DEFAULT 75,
    physical INTEGER DEFAULT 75,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Teams Table
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    logo_url TEXT,
    manager_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    -- League Standings
    played INTEGER DEFAULT 0,
    won INTEGER DEFAULT 0,
    drawn INTEGER DEFAULT 0,
    lost INTEGER DEFAULT 0,
    points INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Team Players Roster (Links profiles to teams)
CREATE TABLE team_players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    position TEXT DEFAULT 'SUB', -- Position assigned within the team
    is_captain BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'INVITED', -- 'INVITED', 'CONFIRMED'
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id, profile_id)
);

-- 4. Create Venues Table (Physical locations)
CREATE TABLE venues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    price_per_hour NUMERIC NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create Fixtures Table (Team vs Team match)
CREATE TABLE fixtures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venue_id UUID REFERENCES venues(id) ON DELETE SET NULL,
    home_team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    away_team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    home_score INTEGER,
    away_score INTEGER,
    date_time TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'SCHEDULED', -- 'SCHEDULED', 'LIVE', 'FINISHED', 'POSTPONED'
    is_live BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.5 Create Match Attendance Table (Junction between fixtures and profiles)
CREATE TABLE match_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fixture_id UUID REFERENCES fixtures(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    scanned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(fixture_id, profile_id)
);

-- ==========================================
-- 6. Social Feed Tables
-- ==========================================

-- Photo posts
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    caption TEXT,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Post likes
CREATE TABLE post_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, profile_id)
);

-- Post comments
CREATE TABLE post_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    author_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Followers
CREATE TABLE followers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- ==========================================
-- Set Up Realtime Subscriptions
-- ==========================================
ALTER PUBLICATION supabase_realtime ADD TABLE fixtures;
ALTER PUBLICATION supabase_realtime ADD TABLE teams;

-- ==========================================
-- Insert Mock Data for UI Testing
-- ==========================================

-- Insert Mock Venues
INSERT INTO venues (id, name, address, lat, lng, price_per_hour)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'McDan Park', 'East Legon, Boundary Rd', 5.6358, -0.1557, 150.00),
    ('22222222-2222-2222-2222-222222222222', 'Ajax Park', 'Legon Campus', 5.5684, -0.2520, 100.00)
ON CONFLICT DO NOTHING;

-- Insert Mock Teams
INSERT INTO teams (id, name, played, won, drawn, lost, points)
VALUES 
    ('aaaa1111-aaaa-1111-aaaa-111111111111', 'OSU TITANS FC', 12, 10, 1, 1, 31),
    ('bbbb2222-bbbb-2222-bbbb-222222222222', 'LABADI WARRIORS', 12, 9, 2, 1, 29),
    ('cccc3333-cccc-3333-cccc-333333333333', 'LEGON ELITES', 12, 8, 0, 4, 24),
    ('dddd4444-dddd-4444-dddd-444444444444', 'TEMA MARINERS', 12, 7, 2, 3, 23)
ON CONFLICT DO NOTHING;

-- Insert Mock Fixtures
INSERT INTO fixtures (id, venue_id, home_team_id, away_team_id, home_score, away_score, date_time, status, is_live)
VALUES 
    -- Live Match
    ('ffff5555-ffff-5555-ffff-555555555555', '11111111-1111-1111-1111-111111111111', 'aaaa1111-aaaa-1111-aaaa-111111111111', 'bbbb2222-bbbb-2222-bbbb-222222222222', 2, 1, NOW() - INTERVAL '45 minutes', 'LIVE', true),
    -- Upcoming Match
    ('eeee6666-eeee-6666-eeee-666666666666', '22222222-2222-2222-2222-222222222222', 'cccc3333-cccc-3333-cccc-333333333333', 'dddd4444-dddd-4444-dddd-444444444444', NULL, NULL, NOW() + INTERVAL '2 hours', 'SCHEDULED', false)
ON CONFLICT DO NOTHING;

-- ==========================================
-- Row Level Security (RLS) Policies
-- ==========================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE fixtures ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_attendance ENABLE ROW LEVEL SECURITY;

-- Disable strict restrictions for development/testing so you don't get blocked
CREATE POLICY "Public Read Access" ON profiles FOR SELECT USING (true);
CREATE POLICY "Public Read Access" ON teams FOR SELECT USING (true);
CREATE POLICY "Public Read Access" ON team_players FOR SELECT USING (true);
CREATE POLICY "Public Read Access" ON venues FOR SELECT USING (true);
CREATE POLICY "Public Read Access" ON fixtures FOR SELECT USING (true);
CREATE POLICY "Public Read Access" ON match_attendance FOR SELECT USING (true);
CREATE POLICY "Public Read Access" ON posts FOR SELECT USING (true);
CREATE POLICY "Public Read Access" ON post_comments FOR SELECT USING (true);

-- Allow authenticated users to Insert/Update for now (You can restrict this later)
CREATE POLICY "Auth Insert" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Auth Update" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Auth Modify" ON teams FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth Modify" ON team_players FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth Modify" ON venues FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth Modify" ON fixtures FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth Modify" ON posts FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth Modify" ON post_comments FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth Modify" ON post_likes FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth Modify" ON followers FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth Modify" ON match_attendance FOR ALL USING (auth.uid() IS NOT NULL);

-- ==========================================
-- 8. Storage Policies for post-images and avatars
-- ==========================================

-- IMPORTANT: You must first create the buckets in the Supabase Dashboard UI
-- if you haven't already. Or run this SQL if your Supabase instance allows it:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('post-images', 'post-images', true) ON CONFLICT DO NOTHING;
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;

-- Drop existing policies if you are re-running this script
DROP POLICY IF EXISTS "Public Read Access on post-images" ON storage.objects;
DROP POLICY IF EXISTS "Auth Insert on post-images" ON storage.objects;
DROP POLICY IF EXISTS "Auth Update/Delete on post-images" ON storage.objects;

DROP POLICY IF EXISTS "Public Read Access on avatars" ON storage.objects;
DROP POLICY IF EXISTS "Auth Insert on avatars" ON storage.objects;
DROP POLICY IF EXISTS "Auth Update/Delete on avatars" ON storage.objects;

-- Allow public read access to all images
CREATE POLICY "Public Read Access on post-images"
ON storage.objects FOR SELECT
USING ( bucket_id = 'post-images' );

-- Allow authenticated users to upload images
CREATE POLICY "Auth Insert on post-images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'post-images' 
    AND auth.uid() IS NOT NULL
);

-- Allow users to update/delete their own images
CREATE POLICY "Auth Update/Delete on post-images"
ON storage.objects FOR ALL
USING (
    bucket_id = 'post-images' 
    AND auth.uid() = owner
);

-- Allow public read access to avatars
CREATE POLICY "Public Read Access on avatars"
ON storage.objects FOR SELECT
USING ( bucket_id = 'avatars' );

-- Allow authenticated users to upload avatars
CREATE POLICY "Auth Insert on avatars"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.uid() IS NOT NULL
);

-- Allow users to update/delete their own avatars
CREATE POLICY "Auth Update/Delete on avatars"
ON storage.objects FOR ALL
USING (
    bucket_id = 'avatars' 
    AND auth.uid() = owner
);
