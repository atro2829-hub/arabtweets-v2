-- ============================================
-- AdenTweet V2 - Complete Database Schema
-- ============================================

-- 1. PROFILES TABLE
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT '',
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  cover_url TEXT,
  bio TEXT DEFAULT '',
  location TEXT DEFAULT '',
  website TEXT DEFAULT '',
  is_verified BOOLEAN DEFAULT FALSE,
  verification_type TEXT DEFAULT 'none' CHECK (verification_type IN ('none', 'blue', 'gold')),
  is_admin BOOLEAN DEFAULT FALSE,
  is_banned BOOLEAN DEFAULT FALSE,
  followers_count INT DEFAULT 0,
  following_count INT DEFAULT 0,
  tweets_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, username, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    NULL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. TWEETS TABLE
CREATE TABLE tweets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) > 0 AND char_length(content) <= 500),
  media_urls TEXT[] DEFAULT '{}',
  media_type TEXT DEFAULT 'none' CHECK (media_type IN ('none', 'image', 'video', 'gif', 'poll')),
  poll_id UUID,
  quote_tweet_id UUID REFERENCES tweets(id) ON DELETE SET NULL,
  reply_to_id UUID REFERENCES tweets(id) ON DELETE SET NULL,
  reply_to_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_pinned BOOLEAN DEFAULT FALSE,
  views_count INT DEFAULT 0,
  likes_count INT DEFAULT 0,
  retweets_count INT DEFAULT 0,
  replies_count INT DEFAULT 0,
  bookmarks_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tweets_user_id ON tweets(user_id);
CREATE INDEX idx_tweets_created_at ON tweets(created_at DESC);
CREATE INDEX idx_tweets_reply_to ON tweets(reply_to_id);

-- 3. POLLS TABLE
CREATE TABLE polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tweet_id UUID NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  options JSONB NOT NULL, -- [{id, text, votes}]
  expires_at TIMESTAMPTZ,
  total_votes INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. INTERACTION TABLES
CREATE TABLE likes (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  tweet_id UUID REFERENCES tweets(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, tweet_id)
);

CREATE TABLE retweets (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  tweet_id UUID REFERENCES tweets(id) ON DELETE CASCADE,
  content TEXT DEFAULT '', -- for quote retweets
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, tweet_id)
);

CREATE TABLE bookmarks (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  tweet_id UUID REFERENCES tweets(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, tweet_id)
);

CREATE TABLE follows (
  follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id)
);

CREATE TABLE blocks (
  blocker_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id)
);

CREATE TABLE views (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  tweet_id UUID REFERENCES tweets(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, tweet_id)
);

-- 5. NOTIFICATIONS TABLE
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  from_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  tweet_id UUID REFERENCES tweets(id) ON DELETE SET NULL,
  type TEXT NOT NULL CHECK (type IN ('like', 'retweet', 'follow', 'reply', 'mention', 'message')),
  is_read BOOLEAN DEFAULT FALSE,
  message TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE NOT is_read;

-- 6. MESSAGES SYSTEM
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  is_group BOOLEAN DEFAULT FALSE,
  name TEXT DEFAULT '',
  avatar_url TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE conversation_participants (
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  last_read_at TIMESTAMPTZ DEFAULT NOW(),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT DEFAULT '',
  media_url TEXT,
  media_type TEXT DEFAULT 'none' CHECK (media_type IN ('none', 'image', 'video', 'audio')),
  reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);

-- 7. REELS TABLE
CREATE TABLE reels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  video_url TEXT NOT NULL,
  thumbnail_url TEXT,
  caption TEXT DEFAULT '',
  duration INT DEFAULT 0,
  views_count INT DEFAULT 0,
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  shares_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reels_created ON reels(created_at DESC);

CREATE TABLE reel_likes (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  reel_id UUID REFERENCES reels(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, reel_id)
);

CREATE TABLE reel_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reel_id UUID NOT NULL REFERENCES reels(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. HASHTAGS
CREATE TABLE hashtags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tag TEXT UNIQUE NOT NULL,
  count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE tweet_hashtags (
  tweet_id UUID REFERENCES tweets(id) ON DELETE CASCADE,
  hashtag_id UUID REFERENCES hashtags(id) ON DELETE CASCADE,
  PRIMARY KEY (tweet_id, hashtag_id)
);

-- 9. REPORTS
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  tweet_id UUID REFERENCES tweets(id) ON DELETE SET NULL,
  reel_id UUID REFERENCES reels(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. AUTO-UPDATE COUNTERS
CREATE OR REPLACE FUNCTION update_tweet_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE tweets SET likes_count = likes_count + 1 WHERE id = NEW.tweet_id;
    -- Create notification
    INSERT INTO notifications (user_id, from_user_id, tweet_id, type, message)
    SELECT t.user_id, NEW.user_id, NEW.tweet_id, 'like', 'أعجب بتعليقك'
    FROM tweets t WHERE t.id = NEW.tweet_id AND t.user_id != NEW.user_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE tweets SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.tweet_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_like_changed
  AFTER INSERT OR DELETE ON likes
  FOR EACH ROW EXECUTE FUNCTION update_tweet_counts();

CREATE OR REPLACE FUNCTION update_retweet_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE tweets SET retweets_count = retweets_count + 1 WHERE id = NEW.tweet_id;
    INSERT INTO notifications (user_id, from_user_id, tweet_id, type, message)
    SELECT t.user_id, NEW.user_id, NEW.tweet_id, 'retweet', 'أعاد نشر تغريدتك'
    FROM tweets t WHERE t.id = NEW.tweet_id AND t.user_id != NEW.user_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE tweets SET retweets_count = GREATEST(retweets_count - 1, 0) WHERE id = OLD.tweet_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_retweet_changed
  AFTER INSERT OR DELETE ON retweets
  FOR EACH ROW EXECUTE FUNCTION update_retweet_counts();

CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE profiles SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
    UPDATE profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
    INSERT INTO notifications (user_id, from_user_id, type, message)
    SELECT NEW.following_id, NEW.follower_id, 'follow', 'تابعك'
    WHERE NEW.following_id != NEW.follower_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE profiles SET followers_count = GREATEST(followers_count - 1, 0) WHERE id = OLD.following_id;
    UPDATE profiles SET following_count = GREATEST(following_count - 1, 0) WHERE id = OLD.follower_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_follow_changed
  AFTER INSERT OR DELETE ON follows
  FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

-- Update tweet count on tweet create/delete
CREATE OR REPLACE FUNCTION update_user_tweet_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE profiles SET tweets_count = tweets_count + 1 WHERE id = NEW.user_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE profiles SET tweets_count = GREATEST(tweets_count - 1, 0) WHERE id = OLD.user_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_tweet_changed
  AFTER INSERT OR DELETE ON tweets
  FOR EACH ROW EXECUTE FUNCTION update_user_tweet_count();

-- ============================================
-- RPC FUNCTIONS
-- ============================================

-- Get home feed (following + own tweets)
CREATE OR REPLACE FUNCTION get_feed(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID, user_id UUID, content TEXT, media_urls TEXT[], media_type TEXT,
  quote_tweet_id UUID, reply_to_id UUID, reply_to_user_id UUID,
  is_pinned BOOLEAN, views_count INT, likes_count INT, retweets_count INT,
  replies_count INT, bookmarks_count INT, created_at TIMESTAMPTZ,
  display_name TEXT, username TEXT, avatar_url TEXT, is_verified BOOLEAN,
  verification_type TEXT, is_liked BOOLEAN, is_retweeted BOOLEAN, is_bookmarked BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id, t.user_id, t.content, t.media_urls, t.media_type,
    t.quote_tweet_id, t.reply_to_id, t.reply_to_user_id,
    t.is_pinned, t.views_count, t.likes_count, t.retweets_count,
    t.replies_count, t.bookmarks_count, t.created_at,
    p.display_name, p.username, p.avatar_url, p.is_verified, p.verification_type,
    EXISTS(SELECT 1 FROM likes l WHERE l.user_id = p_user_id AND l.tweet_id = t.id),
    EXISTS(SELECT 1 FROM retweets r WHERE r.user_id = p_user_id AND r.tweet_id = t.id),
    EXISTS(SELECT 1 FROM bookmarks b WHERE b.user_id = p_user_id AND b.tweet_id = t.id)
  FROM tweets t
  JOIN profiles p ON p.id = t.user_id
  LEFT JOIN follows f ON f.follower_id = p_user_id AND f.following_id = t.user_id
  WHERE t.user_id = p_user_id OR f.follower_id = p_user_id
  ORDER BY t.is_pinned DESC, t.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create tweet
CREATE OR REPLACE FUNCTION create_tweet(
  p_user_id UUID,
  p_content TEXT,
  p_media_urls TEXT[] DEFAULT '{}',
  p_media_type TEXT DEFAULT 'none',
  p_quote_tweet_id UUID DEFAULT NULL,
  p_reply_to_id UUID DEFAULT NULL,
  p_reply_to_user_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_tweet_id UUID;
BEGIN
  INSERT INTO tweets (user_id, content, media_urls, media_type, quote_tweet_id, reply_to_id, reply_to_user_id)
  VALUES (p_user_id, p_content, p_media_urls, p_media_type, p_quote_tweet_id, p_reply_to_id, p_reply_to_user_id)
  RETURNING id INTO v_tweet_id;

  -- Update reply count if it's a reply
  IF p_reply_to_id IS NOT NULL THEN
    UPDATE tweets SET replies_count = replies_count + 1 WHERE id = p_reply_to_id;
    -- Notify the replied-to user
    IF p_reply_to_user_id IS NOT NULL AND p_reply_to_user_id != p_user_id THEN
      INSERT INTO notifications (user_id, from_user_id, tweet_id, type, message)
      VALUES (p_reply_to_user_id, p_user_id, v_tweet_id, 'reply', 'رد على تغريدتك');
    END IF;
  END IF;

  -- Extract and store hashtags
  INSERT INTO hashtags (tag)
  SELECT DISTINCT regexp_matches(p_content, '#([^\s]+)', 'g')[1]
  ON CONFLICT (tag) DO UPDATE SET count = hashtags.count + 1;

  RETURN v_tweet_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle like
CREATE OR REPLACE FUNCTION toggle_like(p_user_id UUID, p_tweet_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_exists BOOLEAN;
BEGIN
  SELECT EXISTS(SELECT 1 FROM likes WHERE user_id = p_user_id AND tweet_id = p_tweet_id) INTO v_exists;
  IF v_exists THEN
    DELETE FROM likes WHERE user_id = p_user_id AND tweet_id = p_tweet_id;
    RETURN FALSE;
  ELSE
    INSERT INTO likes (user_id, tweet_id) VALUES (p_user_id, p_tweet_id);
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle retweet
CREATE OR REPLACE FUNCTION toggle_retweet(p_user_id UUID, p_tweet_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_exists BOOLEAN;
BEGIN
  SELECT EXISTS(SELECT 1 FROM retweets WHERE user_id = p_user_id AND tweet_id = p_tweet_id) INTO v_exists;
  IF v_exists THEN
    DELETE FROM retweets WHERE user_id = p_user_id AND tweet_id = p_tweet_id;
    RETURN FALSE;
  ELSE
    INSERT INTO retweets (user_id, tweet_id) VALUES (p_user_id, p_tweet_id);
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle bookmark
CREATE OR REPLACE FUNCTION toggle_bookmark(p_user_id UUID, p_tweet_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_exists BOOLEAN;
BEGIN
  SELECT EXISTS(SELECT 1 FROM bookmarks WHERE user_id = p_user_id AND tweet_id = p_tweet_id) INTO v_exists;
  IF v_exists THEN
    DELETE FROM bookmarks WHERE user_id = p_user_id AND tweet_id = p_tweet_id;
    RETURN FALSE;
  ELSE
    INSERT INTO bookmarks (user_id, tweet_id) VALUES (p_user_id, p_tweet_id);
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle follow
CREATE OR REPLACE FUNCTION toggle_follow(p_follower_id UUID, p_following_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_exists BOOLEAN;
BEGIN
  IF p_follower_id = p_following_id THEN RETURN FALSE; END IF;
  SELECT EXISTS(SELECT 1 FROM follows WHERE follower_id = p_follower_id AND following_id = p_following_id) INTO v_exists;
  IF v_exists THEN
    DELETE FROM follows WHERE follower_id = p_follower_id AND following_id = p_following_id;
    RETURN FALSE;
  ELSE
    INSERT INTO follows (follower_id, following_id) VALUES (p_follower_id, p_following_id);
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get tweet replies
CREATE OR REPLACE FUNCTION get_tweet_replies(
  p_tweet_id UUID,
  p_user_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID, user_id UUID, content TEXT, media_urls TEXT[], media_type TEXT,
  reply_to_id UUID, reply_to_user_id UUID, likes_count INT, retweets_count INT,
  replies_count INT, created_at TIMESTAMPTZ,
  display_name TEXT, username TEXT, avatar_url TEXT, is_verified BOOLEAN,
  verification_type TEXT, is_liked BOOLEAN, is_retweeted BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id, t.user_id, t.content, t.media_urls, t.media_type,
    t.reply_to_id, t.reply_to_user_id,
    t.likes_count, t.retweets_count, t.replies_count, t.created_at,
    p.display_name, p.username, p.avatar_url, p.is_verified, p.verification_type,
    COALESCE(EXISTS(SELECT 1 FROM likes l WHERE l.user_id = p_user_id AND l.tweet_id = t.id), FALSE),
    COALESCE(EXISTS(SELECT 1 FROM retweets r WHERE r.user_id = p_user_id AND r.tweet_id = t.id), FALSE)
  FROM tweets t
  JOIN profiles p ON p.id = t.user_id
  WHERE t.reply_to_id = p_tweet_id
  ORDER BY t.created_at ASC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user notifications
CREATE OR REPLACE FUNCTION get_user_notifications(
  p_user_id UUID,
  p_limit INT DEFAULT 30,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID, type TEXT, is_read BOOLEAN, message TEXT, created_at TIMESTAMPTZ,
  from_user_id UUID, from_username TEXT, from_avatar_url TEXT,
  from_display_name TEXT, tweet_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    n.id, n.type, n.is_read, n.message, n.created_at,
    n.from_user_id,
    fp.username, fp.avatar_url, fp.display_name,
    n.tweet_id
  FROM notifications n
  LEFT JOIN profiles fp ON fp.id = n.from_user_id
  WHERE n.user_id = p_user_id
  ORDER BY n.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mark notifications as read
CREATE OR REPLACE FUNCTION mark_notifications_read(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE notifications SET is_read = TRUE WHERE user_id = p_user_id AND NOT is_read;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notifications_count(p_user_id UUID)
RETURNS INT AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM notifications WHERE user_id = p_user_id AND NOT is_read;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get or create conversation
CREATE OR REPLACE FUNCTION get_or_create_conversation(p_user1 UUID, p_user2 UUID)
RETURNS UUID AS $$
DECLARE
  v_conv_id UUID;
BEGIN
  -- Check if conversation already exists
  SELECT c.id INTO v_conv_id
  FROM conversations c
  JOIN conversation_participants cp1 ON cp1.conversation_id = c.id AND cp1.user_id = p_user1
  JOIN conversation_participants cp2 ON cp2.conversation_id = c.id AND cp2.user_id = p_user2
  WHERE NOT c.is_group
  LIMIT 1;

  IF v_conv_id IS NULL THEN
    INSERT INTO conversations (is_group) VALUES (FALSE) RETURNING id INTO v_conv_id;
    INSERT INTO conversation_participants (conversation_id, user_id) VALUES (v_conv_id, p_user1);
    INSERT INTO conversation_participants (conversation_id, user_id) VALUES (v_conv_id, p_user2);
  END IF;

  RETURN v_conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user conversations
CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id UUID)
RETURNS TABLE (
  id UUID, name TEXT, avatar_url TEXT, updated_at TIMESTAMPTZ,
  last_message TEXT, last_message_time TIMESTAMPTZ,
  other_user_id UUID, other_username TEXT, other_avatar_url TEXT,
  other_display_name TEXT, other_is_verified BOOLEAN,
  unread_count INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id, c.name, c.avatar_url, c.updated_at,
    m.content AS last_message, m.created_at AS last_message_time,
    p.id AS other_user_id, p.username AS other_username, p.avatar_url AS other_avatar_url,
    p.display_name AS other_display_name, p.is_verified AS other_is_verified,
    (SELECT COUNT(*) FROM messages m2
     JOIN conversation_participants cp2 ON cp2.conversation_id = m2.conversation_id AND cp2.user_id = p_user_id
     WHERE m2.conversation_id = c.id AND m2.sender_id != p_user_id AND NOT m2.is_read
     AND m2.created_at > COALESCE(cp2.last_read_at, '1970-01-01'::timestamptz))::INT AS unread_count
  FROM conversations c
  JOIN conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = p_user_id
  JOIN conversation_participants cp_other ON cp_other.conversation_id = c.id AND cp_other.user_id != p_user_id
  JOIN profiles p ON p.id = cp_other.user_id
  LEFT JOIN LATERAL (
    SELECT m1.content, m1.created_at FROM messages m1
    WHERE m1.conversation_id = c.id
    ORDER BY m1.created_at DESC LIMIT 1
  ) m ON true
  WHERE NOT c.is_group
  ORDER BY c.updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get conversation messages
CREATE OR REPLACE FUNCTION get_conversation_messages(
  p_conversation_id UUID,
  p_user_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 30,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID, sender_id UUID, content TEXT, media_url TEXT, media_type TEXT,
  reply_to_id UUID, is_read BOOLEAN, created_at TIMESTAMPTZ,
  sender_username TEXT, sender_avatar_url TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    m.id, m.sender_id, m.content, m.media_url, m.media_type,
    m.reply_to_id, m.is_read, m.created_at,
    p.username AS sender_username, p.avatar_url AS sender_avatar_url
  FROM messages m
  JOIN profiles p ON p.id = m.sender_id
  JOIN conversation_participants cp ON cp.conversation_id = m.conversation_id AND cp.user_id = p_user_id
  WHERE m.conversation_id = p_conversation_id
  ORDER BY m.created_at DESC
  LIMIT p_limit OFFSET p_offset;

  -- Mark messages as read
  UPDATE conversation_participants SET last_read_at = NOW()
  WHERE conversation_id = p_conversation_id AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Send message
CREATE OR REPLACE FUNCTION send_message(
  p_conversation_id UUID,
  p_sender_id UUID,
  p_content TEXT DEFAULT '',
  p_media_url TEXT DEFAULT NULL,
  p_media_type TEXT DEFAULT 'none',
  p_reply_to_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_msg_id UUID;
  v_other_user_id UUID;
BEGIN
  INSERT INTO messages (conversation_id, sender_id, content, media_url, media_type, reply_to_id)
  VALUES (p_conversation_id, p_sender_id, p_content, p_media_url, p_media_type, p_reply_to_id)
  RETURNING id INTO v_msg_id;

  UPDATE conversations SET updated_at = NOW() WHERE id = p_conversation_id;

  -- Get other participant and notify
  SELECT cp.user_id INTO v_other_user_id
  FROM conversation_participants cp
  WHERE cp.conversation_id = p_conversation_id AND cp.user_id != p_sender_id
  LIMIT 1;

  IF v_other_user_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, from_user_id, type, message)
    VALUES (v_other_user_id, p_sender_id, 'message', SUBSTRING(p_content, 1, 50));
  END IF;

  RETURN v_msg_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search users
CREATE OR REPLACE FUNCTION search_users(
  p_query TEXT,
  p_limit INT DEFAULT 20
)
RETURNS TABLE (
  id UUID, display_name TEXT, username TEXT, avatar_url TEXT,
  bio TEXT, is_verified BOOLEAN, verification_type TEXT,
  followers_count INT, following_count INT, tweets_count INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT id, display_name, username, avatar_url, bio,
    is_verified, verification_type, followers_count, following_count, tweets_count
  FROM profiles
  WHERE NOT is_banned AND (
    username ILIKE '%' || p_query || '%'
    OR display_name ILIKE '%' || p_query || '%'
  )
  ORDER BY followers_count DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search tweets
CREATE OR REPLACE FUNCTION search_tweets(
  p_query TEXT,
  p_user_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID, user_id UUID, content TEXT, media_urls TEXT[], media_type TEXT,
  likes_count INT, retweets_count INT, replies_count INT, created_at TIMESTAMPTZ,
  display_name TEXT, username TEXT, avatar_url TEXT, is_verified BOOLEAN,
  is_liked BOOLEAN, is_retweeted BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id, t.user_id, t.content, t.media_urls, t.media_type,
    t.likes_count, t.retweets_count, t.replies_count, t.created_at,
    p.display_name, p.username, p.avatar_url, p.is_verified,
    COALESCE(EXISTS(SELECT 1 FROM likes l WHERE l.user_id = p_user_id AND l.tweet_id = t.id), FALSE),
    COALESCE(EXISTS(SELECT 1 FROM retweets r WHERE r.user_id = p_user_id AND r.tweet_id = t.id), FALSE)
  FROM tweets t
  JOIN profiles p ON p.id = t.user_id
  WHERE t.content ILIKE '%' || p_query || '%'
  ORDER BY t.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trending hashtags
CREATE OR REPLACE FUNCTION get_trending_hashtags(p_limit INT DEFAULT 10)
RETURNS TABLE (tag TEXT, count INT) AS $$
BEGIN
  RETURN QUERY
  SELECT tag, count FROM hashtags ORDER BY count DESC LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user profile
CREATE OR REPLACE FUNCTION get_user_profile(p_username TEXT)
RETURNS TABLE (
  id UUID, display_name TEXT, username TEXT, avatar_url TEXT, cover_url TEXT,
  bio TEXT, location TEXT, website TEXT, is_verified BOOLEAN,
  verification_type TEXT, is_admin BOOLEAN, is_banned BOOLEAN,
  followers_count INT, following_count INT, tweets_count INT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM profiles WHERE username = p_username LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user tweets
CREATE OR REPLACE FUNCTION get_user_tweets(
  p_user_id UUID,
  p_current_user_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID, content TEXT, media_urls TEXT[], media_type TEXT,
  likes_count INT, retweets_count INT, replies_count INT, bookmarks_count INT,
  views_count INT, created_at TIMESTAMPTZ,
  is_liked BOOLEAN, is_retweeted BOOLEAN, is_bookmarked BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id, t.content, t.media_urls, t.media_type,
    t.likes_count, t.retweets_count, t.replies_count, t.bookmarks_count,
    t.views_count, t.created_at,
    COALESCE(EXISTS(SELECT 1 FROM likes l WHERE l.user_id = p_current_user_id AND l.tweet_id = t.id), FALSE),
    COALESCE(EXISTS(SELECT 1 FROM retweets r WHERE r.user_id = p_current_user_id AND l.tweet_id = t.id), FALSE),
    COALESCE(EXISTS(SELECT 1 FROM bookmarks b WHERE b.user_id = p_current_user_id AND b.tweet_id = t.id), FALSE)
  FROM tweets t
  WHERE t.user_id = p_user_id AND t.reply_to_id IS NULL
  ORDER BY t.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get reels
CREATE OR REPLACE FUNCTION get_reels(
  p_user_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 10,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID, user_id UUID, video_url TEXT, thumbnail_url TEXT,
  caption TEXT, duration INT, views_count INT, likes_count INT,
  comments_count INT, shares_count INT, created_at TIMESTAMPTZ,
  display_name TEXT, username TEXT, avatar_url TEXT, is_liked BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id, r.user_id, r.video_url, r.thumbnail_url,
    r.caption, r.duration, r.views_count, r.likes_count,
    r.comments_count, r.shares_count, r.created_at,
    p.display_name, p.username, p.avatar_url,
    COALESCE(EXISTS(SELECT 1 FROM reel_likes rl WHERE rl.user_id = p_user_id AND rl.reel_id = r.id), FALSE)
  FROM reels r
  JOIN profiles p ON p.id = r.user_id
  ORDER BY r.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle reel like
CREATE OR REPLACE FUNCTION toggle_reel_like(p_user_id UUID, p_reel_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_exists BOOLEAN;
BEGIN
  SELECT EXISTS(SELECT 1 FROM reel_likes WHERE user_id = p_user_id AND reel_id = p_reel_id) INTO v_exists;
  IF v_exists THEN
    DELETE FROM reel_likes WHERE user_id = p_user_id AND reel_id = p_reel_id;
    UPDATE reels SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = p_reel_id;
    RETURN FALSE;
  ELSE
    INSERT INTO reel_likes (user_id, reel_id) VALUES (p_user_id, p_reel_id);
    UPDATE reels SET likes_count = likes_count + 1 WHERE id = p_reel_id;
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin functions
CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS TABLE (
  total_users INT, total_tweets INT, total_reports INT, total_reels INT,
  today_users INT, today_tweets INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM profiles)::INT,
    (SELECT COUNT(*) FROM tweets)::INT,
    (SELECT COUNT(*) FROM reports)::INT,
    (SELECT COUNT(*) FROM reels)::INT,
    (SELECT COUNT(*) FROM profiles WHERE created_at >= CURRENT_DATE)::INT,
    (SELECT COUNT(*) FROM tweets WHERE created_at >= CURRENT_DATE)::INT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_all_users(p_limit INT DEFAULT 50, p_offset INT DEFAULT 0)
RETURNS TABLE (
  id UUID, display_name TEXT, username TEXT, email TEXT,
  is_verified BOOLEAN, is_admin BOOLEAN, is_banned BOOLEAN,
  followers_count INT, tweets_count INT, created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id, p.display_name, p.username,
    (SELECT email FROM auth.users WHERE id = p.id) AS email,
    p.is_verified, p.is_admin, p.is_banned,
    p.followers_count, p.tweets_count, p.created_at
  FROM profiles p
  ORDER BY p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_all_reports(p_limit INT DEFAULT 50, p_offset INT DEFAULT 0)
RETURNS TABLE (
  id UUID, reporter_id UUID, target_user_id UUID, tweet_id UUID,
  reason TEXT, status TEXT, created_at TIMESTAMPTZ,
  reporter_username TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id, r.reporter_id, r.target_user_id, r.tweet_id,
    r.reason, r.status, r.created_at,
    p.username AS reporter_username
  FROM reports r
  LEFT JOIN profiles p ON p.id = r.reporter_id
  ORDER BY r.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- RLS POLICIES
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tweets ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE retweets ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE views ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE reels ENABLE ROW LEVEL SECURITY;
ALTER TABLE reel_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reel_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE hashtags ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;

-- Profiles: everyone can read, users can update own
CREATE POLICY "Profiles readable" ON profiles FOR SELECT USING (true);
CREATE POLICY "Profiles insert own" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Profiles update own" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Profiles admin update" ON profiles FOR UPDATE USING (
  EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin)
);

-- Tweets: everyone can read, authenticated can create
CREATE POLICY "Tweets readable" ON tweets FOR SELECT USING (true);
CREATE POLICY "Tweets create" ON tweets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Tweets delete own" ON tweets FOR DELETE USING (
  auth.uid() = user_id OR EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin)
);

-- Likes, retweets, bookmarks: manage own
CREATE POLICY "Likes own" ON likes FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Retweets own" ON retweets FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Bookmarks own" ON bookmarks FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Follows own" ON follows FOR ALL USING (auth.uid() = follower_id);
CREATE POLICY "Blocks own" ON blocks FOR ALL USING (auth.uid() = blocker_id);
CREATE POLICY "Views own" ON views FOR ALL USING (auth.uid() = user_id);

-- Notifications: read/write own
CREATE POLICY "Notifs read own" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Notifs insert" ON notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Notifs update own" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- Messages: participants can read/write
CREATE POLICY "Messages participants" ON messages FOR SELECT USING (
  EXISTS(SELECT 1 FROM conversation_participants WHERE conversation_id = messages.conversation_id AND user_id = auth.uid())
);
CREATE POLICY "Messages send" ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Conversations: participants only
CREATE POLICY "Convo participants" ON conversations FOR ALL USING (
  EXISTS(SELECT 1 FROM conversation_participants WHERE conversation_id = conversations.id AND user_id = auth.uid())
);

-- Conversation participants
CREATE POLICY "ConvParts read" ON conversation_participants FOR SELECT USING (
  EXISTS(SELECT 1 FROM conversation_participants WHERE conversation_id = conversation_participants.conversation_id AND user_id = auth.uid())
);
CREATE POLICY "ConvParts insert" ON conversation_participants FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Reels: everyone can read, authenticated can create
CREATE POLICY "Reels readable" ON reels FOR SELECT USING (true);
CREATE POLICY "Reels create" ON reels FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Reels delete own" ON reels FOR DELETE USING (
  auth.uid() = user_id OR EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin)
);
CREATE POLICY "ReelLikes own" ON reel_likes FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "ReelComments readable" ON reel_comments FOR SELECT USING (true);
CREATE POLICY "ReelComments create" ON reel_comments FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Hashtags: readable by all
CREATE POLICY "Hashtags readable" ON hashtags FOR SELECT USING (true);

-- Reports
CREATE POLICY "Reports create" ON reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Reports admin read" ON reports FOR SELECT USING (
  EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin)
);
CREATE POLICY "Reports admin update" ON reports FOR UPDATE USING (
  EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin)
);

-- Polls
CREATE POLICY "Polls readable" ON polls FOR SELECT USING (true);
CREATE POLICY "Polls create" ON polls FOR INSERT WITH CHECK (
  EXISTS(SELECT 1 FROM tweets WHERE id = polls.tweet_id AND user_id = auth.uid())
);

-- ============================================
-- STORAGE BUCKETS
-- ============================================
-- These need to be created via Supabase dashboard or API
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('covers', 'covers', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('media', 'media', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('reels', 'reels', true);

-- ============================================
-- ENABLE REALTIME
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE tweets;