-- Add saved posts table
CREATE TABLE IF NOT EXISTS saved_posts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

-- Enable RLS
ALTER TABLE saved_posts ENABLE ROW LEVEL SECURITY;

-- Saved posts policies
CREATE POLICY "Users can view own saved posts."
  ON saved_posts FOR SELECT
  USING ( auth.uid() = user_id );

CREATE POLICY "Authenticated users can save posts."
  ON saved_posts FOR INSERT
  WITH CHECK ( auth.role() = 'authenticated' AND auth.uid() = user_id );

CREATE POLICY "Users can remove own saved posts."
  ON saved_posts FOR DELETE
  USING ( auth.uid() = user_id );

