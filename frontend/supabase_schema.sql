-- =====================================================
-- INSTAGRAM-LIKE SOCIAL MEDIA APP - DATABASE SCHEMA
-- Supabase PostgreSQL
-- =====================================================

-- !!! ÖNEMLİ: Bu SQL'i Supabase Dashboard > SQL Editor'de çalıştırın !!!

-- =====================================================
-- 1. POSTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  caption TEXT,
  media_urls TEXT[] NOT NULL DEFAULT '{}',
  media_type TEXT DEFAULT 'image' CHECK (media_type IN ('image', 'video', 'carousel')),
  location TEXT,
  like_count INT DEFAULT 0,
  comment_count INT DEFAULT 0,
  is_archived BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);

-- =====================================================
-- 2. LIKES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_likes_post_id ON likes(post_id);

-- =====================================================
-- 3. COMMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE NOT NULL,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  like_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);

-- =====================================================
-- 4. STORIES TABLE (24 saat sonra expire)
-- =====================================================
CREATE TABLE IF NOT EXISTS stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  media_url TEXT NOT NULL,
  media_type TEXT DEFAULT 'image' CHECK (media_type IN ('image', 'video')),
  view_count INT DEFAULT 0,
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours'),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stories_user_id ON stories(user_id);
CREATE INDEX IF NOT EXISTS idx_stories_expires_at ON stories(expires_at);

-- Story Views (kim görüntüledi)
CREATE TABLE IF NOT EXISTS story_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID REFERENCES stories(id) ON DELETE CASCADE NOT NULL,
  viewer_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(story_id, viewer_id)
);

-- =====================================================
-- 5. FOLLOWERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS followers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

CREATE INDEX IF NOT EXISTS idx_followers_follower ON followers(follower_id);
CREATE INDEX IF NOT EXISTS idx_followers_following ON followers(following_id);

-- =====================================================
-- 6. SAVED POSTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS saved_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

-- =====================================================
-- 7. NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  actor_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('like', 'comment', 'follow', 'mention', 'story_reply', 'message')),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- =====================================================
-- 8. RLS (Row Level Security) POLICIES
-- =====================================================

-- Posts: Herkes okuyabilir, sadece sahibi değiştirebilir
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Posts are viewable by everyone" ON posts;
CREATE POLICY "Posts are viewable by everyone" ON posts 
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own posts" ON posts;
CREATE POLICY "Users can insert own posts" ON posts 
  FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can update own posts" ON posts;
CREATE POLICY "Users can update own posts" ON posts 
  FOR UPDATE USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can delete own posts" ON posts;
CREATE POLICY "Users can delete own posts" ON posts 
  FOR DELETE USING (auth.uid()::text = user_id::text);

-- Likes
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Likes are viewable by everyone" ON likes;
CREATE POLICY "Likes are viewable by everyone" ON likes 
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own likes" ON likes;
CREATE POLICY "Users can manage own likes" ON likes 
  FOR ALL USING (auth.uid()::text = user_id::text);

-- Comments
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Comments are viewable by everyone" ON comments;
CREATE POLICY "Comments are viewable by everyone" ON comments 
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own comments" ON comments;
CREATE POLICY "Users can manage own comments" ON comments 
  FOR ALL USING (auth.uid()::text = user_id::text);

-- Stories
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Stories are viewable by everyone" ON stories;
CREATE POLICY "Stories are viewable by everyone" ON stories 
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own stories" ON stories;
CREATE POLICY "Users can manage own stories" ON stories 
  FOR ALL USING (auth.uid()::text = user_id::text);

-- Followers
ALTER TABLE followers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Followers are viewable by everyone" ON followers;
CREATE POLICY "Followers are viewable by everyone" ON followers 
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own follows" ON followers;
CREATE POLICY "Users can manage own follows" ON followers 
  FOR ALL USING (auth.uid()::text = follower_id::text);

-- Notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" ON notifications 
  FOR SELECT USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications" ON notifications 
  FOR UPDATE USING (auth.uid()::text = user_id::text);

-- =====================================================
-- 9. HELPER FUNCTIONS (Like/Comment count)
-- =====================================================

-- Increment like count
CREATE OR REPLACE FUNCTION increment_like_count(post_id_param UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts SET like_count = like_count + 1 WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrement like count
CREATE OR REPLACE FUNCTION decrement_like_count(post_id_param UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment comment count
CREATE OR REPLACE FUNCTION increment_comment_count(post_id_param UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts SET comment_count = comment_count + 1 WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrement comment count
CREATE OR REPLACE FUNCTION decrement_comment_count(post_id_param UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment story view count
CREATE OR REPLACE FUNCTION increment_story_view_count(story_id_param UUID)
RETURNS void AS $$
BEGIN
  UPDATE stories SET view_count = view_count + 1 WHERE id = story_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 10. STORAGE BUCKET (Supabase Storage)
-- =====================================================
-- Run this in Supabase Dashboard > Storage > New Bucket
-- Bucket name: media
-- Public: true

-- Storage policies (run in SQL Editor):
-- INSERT INTO storage.buckets (id, name, public) VALUES ('media', 'media', true);

COMMENT ON TABLE posts IS 'Instagram-like posts with media, captions, and engagement metrics';
COMMENT ON TABLE stories IS '24-hour ephemeral stories';
COMMENT ON TABLE followers IS 'User follow relationships';
