-- Migration script to add comment replies, user mentions, and hashtags
-- Run this in Supabase SQL Editor

-- Add parent_comment_id to comments table
ALTER TABLE comments 
ADD COLUMN IF NOT EXISTS parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE;

-- Create post mentions table
CREATE TABLE IF NOT EXISTS post_mentions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    mentioned_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, mentioned_user_id)
);

-- Create hashtags table
CREATE TABLE IF NOT EXISTS hashtags (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create post hashtags table
CREATE TABLE IF NOT EXISTS post_hashtags (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    hashtag_id UUID REFERENCES hashtags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, hashtag_id)
);

-- Enable RLS for new tables
ALTER TABLE post_mentions ENABLE ROW LEVEL SECURITY;
ALTER TABLE hashtags ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_hashtags ENABLE ROW LEVEL SECURITY;

-- Post mentions policies
CREATE POLICY "Post mentions are viewable by everyone."
  ON post_mentions FOR SELECT
  USING ( true );

CREATE POLICY "Authenticated users can create mentions."
  ON post_mentions FOR INSERT
  WITH CHECK ( auth.role() = 'authenticated' );

CREATE POLICY "Users can delete mentions from their posts."
  ON post_mentions FOR DELETE
  USING ( auth.uid() IN (
    SELECT user_id FROM posts WHERE id = post_id
  ));

-- Hashtags policies
CREATE POLICY "Hashtags are viewable by everyone."
  ON hashtags FOR SELECT
  USING ( true );

CREATE POLICY "Authenticated users can create hashtags."
  ON hashtags FOR INSERT
  WITH CHECK ( auth.role() = 'authenticated' );

-- Post hashtags policies
CREATE POLICY "Post hashtags are viewable by everyone."
  ON post_hashtags FOR SELECT
  USING ( true );

CREATE POLICY "Authenticated users can create post hashtags."
  ON post_hashtags FOR INSERT
  WITH CHECK ( auth.role() = 'authenticated' );

CREATE POLICY "Users can delete hashtags from their posts."
  ON post_hashtags FOR DELETE
  USING ( auth.uid() IN (
    SELECT user_id FROM posts WHERE id = post_id
  ));
