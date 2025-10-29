-- Add comment likes/dislikes tables
CREATE TABLE IF NOT EXISTS comment_likes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(comment_id, user_id)
);

CREATE TABLE IF NOT EXISTS comment_dislikes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(comment_id, user_id)
);

-- Enable RLS
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_dislikes ENABLE ROW LEVEL SECURITY;

-- Comment likes policies
CREATE POLICY "Comment likes are viewable by everyone."
  ON comment_likes FOR SELECT
  USING ( true );

CREATE POLICY "Authenticated users can like comments."
  ON comment_likes FOR INSERT
  WITH CHECK ( auth.role() = 'authenticated' );

CREATE POLICY "Users can remove own comment likes."
  ON comment_likes FOR DELETE
  USING ( auth.uid() = user_id );

-- Comment dislikes policies
CREATE POLICY "Comment dislikes are viewable by everyone."
  ON comment_dislikes FOR SELECT
  USING ( true );

CREATE POLICY "Authenticated users can dislike comments."
  ON comment_dislikes FOR INSERT
  WITH CHECK ( auth.role() = 'authenticated' );

CREATE POLICY "Users can remove own comment dislikes."
  ON comment_dislikes FOR DELETE
  USING ( auth.uid() = user_id );

