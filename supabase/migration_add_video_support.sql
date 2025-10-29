-- Migration script to update posts table for video support
-- Run this in Supabase SQL Editor

-- Add new columns to posts table
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS media_url TEXT,
ADD COLUMN IF NOT EXISTS media_type TEXT CHECK (media_type IN ('image', 'video'));

-- Migrate existing data
UPDATE posts 
SET media_url = image_url, 
    media_type = 'image' 
WHERE media_url IS NULL AND image_url IS NOT NULL;

-- Make media_url NOT NULL after migration
ALTER TABLE posts ALTER COLUMN media_url SET NOT NULL;
ALTER TABLE posts ALTER COLUMN media_type SET NOT NULL;

-- Drop old image_url column
ALTER TABLE posts DROP COLUMN IF EXISTS image_url;

-- Create new storage bucket for post media
INSERT INTO storage.buckets (id, name) 
VALUES ('post-media', 'post-media') 
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for post-media bucket
CREATE POLICY "Post media are publicly accessible."
  ON storage.objects FOR SELECT
  USING ( bucket_id = 'post-media' );

CREATE POLICY "Authenticated users can upload post media."
  ON storage.objects FOR INSERT
  WITH CHECK ( bucket_id = 'post-media' AND auth.role() = 'authenticated' );

-- Drop old post-images bucket policies if they exist
DROP POLICY IF EXISTS "Post images are publicly accessible." ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload post images." ON storage.objects;
