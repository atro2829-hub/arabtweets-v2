-- ============================================
-- ADENTWEET DATABASE SCHEMA (OPEN - NO RLS)
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- PROFILES
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT DEFAULT '',
  username TEXT UNIQUE,
  bio TEXT DEFAULT '',
  avatar_url TEXT DEFAULT '',
  cover_url TEXT DEFAULT '',
  location TEXT DEFAULT '',
  website TEXT DEFAULT '',
  is_verified BOOLEAN DEFAULT FALSE,
  verification_type TEXT DEFAULT 'none',
  is_private BOOLEAN DEFAULT FALSE,
  followers_count INT DEFAULT 0,
  following_count INT DEFAULT 0,
  tweets_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- TWEETS
CREATE TABLE tweets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL DEFAULT '',
  media_urls TEXT[] DEFAULT '{}',
  media_type TEXT DEFAULT 'none',
  poll_id UUID,
  quote_tweet_id UUID REFERENCES tweets(id) ON DELETE SET NULL,
  reply_to_id UUID REFERENCES tweets(id) ON DELETE CASCADE,
  reply_to_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_pinned BOOLEAN DEFAULT FALSE,
  views_count INT DEFAULT 0,
  likes_count INT DEFAULT 0,
  retweets_count INT DEFAULT 0,
  replies_count INT DEFAULT 0,
  bookmarks_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- POLLS
CREATE TABLE polls (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tweet_id UUID NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  multiple_choice BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE poll_options (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
  option_text TEXT NOT NULL,
  votes_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE poll_votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  poll_option_id UUID NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
  poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, poll_id)
);

-- INTERACTIONS
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tweet_id UUID NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tweet_id)
);

CREATE TABLE retweets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tweet_id UUID NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tweet_id)
);

CREATE TABLE bookmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tweet_id UUID NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tweet_id)
);

-- SOCIAL
CREATE TABLE follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

CREATE TABLE blocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(blocker_id, blocked_id)
);

-- VIEWS
CREATE TABLE tweet_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  tweet_id UUID NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tweet_id)
);

-- NOTIFICATIONS
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  type TEXT NOT NULL DEFAULT 'like',
  tweet_id UUID REFERENCES tweets(id) ON DELETE SET NULL,
  message TEXT DEFAULT '',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- MESSAGES
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE conversation_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL DEFAULT '',
  media_url TEXT DEFAULT '',
  message_type TEXT DEFAULT 'text',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- REELS
CREATE TABLE reels (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  video_url TEXT NOT NULL,
  thumbnail_url TEXT DEFAULT '',
  caption TEXT DEFAULT '',
  views_count INT DEFAULT 0,
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reel_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reel_id UUID NOT NULL REFERENCES reels(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, reel_id)
);

CREATE TABLE reel_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reel_id UUID NOT NULL REFERENCES reels(id) ON DELETE CASCADE,
  content TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- HASHTAGS
CREATE TABLE hashtags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tag TEXT UNIQUE NOT NULL,
  count INT DEFAULT 0
);

-- REPORTS
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  tweet_id UUID REFERENCES tweets(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  description TEXT DEFAULT '',
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES
CREATE INDEX idx_tweets_user_id ON tweets(user_id);
CREATE INDEX idx_tweets_created_at ON tweets(created_at DESC);
CREATE INDEX idx_tweets_reply_to ON tweets(reply_to_id);
CREATE INDEX idx_likes_user ON likes(user_id);
CREATE INDEX idx_likes_tweet ON likes(tweet_id);
CREATE INDEX idx_retweets_user ON retweets(user_id);
CREATE INDEX idx_retweets_tweet ON retweets(tweet_id);
CREATE INDEX idx_bookmarks_user ON bookmarks(user_id);
CREATE INDEX idx_bookmarks_tweet ON bookmarks(tweet_id);
CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_created ON messages(created_at);
CREATE INDEX idx_conv_participants_user ON conversation_participants(user_id);
CREATE INDEX idx_profiles_username ON profiles(username);

-- ============================================
-- TRIGGERS FOR COUNTER UPDATES
-- ============================================
CREATE OR REPLACE FUNCTION update_tweet_counters()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE tweets SET likes_count = likes_count + 1 WHERE id = NEW.tweet_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE tweets SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.tweet_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_like_counter
  AFTER INSERT OR DELETE ON likes
  FOR EACH ROW EXECUTE FUNCTION update_tweet_counters();

CREATE OR REPLACE FUNCTION update_retweet_counter()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE tweets SET retweets_count = retweets_count + 1 WHERE id = NEW.tweet_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE tweets SET retweets_count = GREATEST(retweets_count - 1, 0) WHERE id = OLD.tweet_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_retweet_counter
  AFTER INSERT OR DELETE ON retweets
  FOR EACH ROW EXECUTE FUNCTION update_retweet_counter();

CREATE OR REPLACE FUNCTION update_follow_counters()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE profiles SET following_count = following_count + 1 WHERE user_id = NEW.follower_id;
    UPDATE profiles SET followers_count = followers_count + 1 WHERE user_id = NEW.following_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE profiles SET following_count = GREATEST(following_count - 1, 0) WHERE user_id = OLD.follower_id;
    UPDATE profiles SET followers_count = GREATEST(followers_count - 1, 0) WHERE user_id = OLD.following_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_follow_counter
  AFTER INSERT OR DELETE ON follows
  FOR EACH ROW EXECUTE FUNCTION update_follow_counters();

CREATE OR REPLACE FUNCTION increment_tweet_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles SET tweets_count = tweets_count + 1 WHERE user_id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_tweet_count
  AFTER INSERT ON tweets
  FOR EACH ROW EXECUTE FUNCTION increment_tweet_count();

CREATE OR REPLACE FUNCTION create_profile_on_signup()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (user_id, display_name, username)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', ''),
          COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)))
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_create_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_profile_on_signup();

-- ============================================
-- RPC FUNCTIONS (OPEN ACCESS)
-- ============================================

-- Auto-create/update profile after auth
CREATE OR REPLACE FUNCTION get_or_create_profile(p_user_id UUID)
RETURNS TABLE(id UUID, user_id UUID, display_name TEXT, username TEXT, bio TEXT, avatar_url TEXT, cover_url TEXT, is_verified BOOLEAN, verification_type TEXT, followers_count INT, following_count INT, tweets_count INT) AS $$
  INSERT INTO profiles (user_id, display_name, username)
  VALUES (p_user_id, '', 'user_' || substr(p_user_id::text, 1, 8))
  ON CONFLICT (user_id) DO UPDATE SET updated_at = NOW()
  RETURNING profiles.id, profiles.user_id, profiles.display_name, profiles.username, profiles.bio,
            profiles.avatar_url, profiles.cover_url, profiles.is_verified, profiles.verification_type,
            profiles.followers_count, profiles.following_count, profiles.tweets_count;
$$ LANGUAGE sql SECURITY DEFINER;

-- Feed
CREATE OR REPLACE FUNCTION get_feed(p_user_id UUID, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE(id UUID, user_id UUID, content TEXT, media_urls TEXT[], media_type TEXT, quote_tweet_id UUID,
              reply_to_id UUID, reply_to_user_id UUID, is_pinned BOOLEAN, views_count INT,
              likes_count INT, retweets_count INT, replies_count INT, bookmarks_count INT,
              created_at TIMESTAMPTZ, display_name TEXT, username TEXT, avatar_url TEXT,
              is_verified BOOLEAN, verification_type TEXT, is_liked BOOLEAN, is_retweeted BOOLEAN, is_bookmarked BOOLEAN) AS $$
  SELECT
    t.id, t.user_id, t.content, t.media_urls, t.media_type, t.quote_tweet_id,
    t.reply_to_id, t.reply_to_user_id, t.is_pinned, t.views_count,
    t.likes_count, t.retweets_count, t.replies_count, t.bookmarks_count,
    t.created_at,
    p.display_name, p.username, p.avatar_url, p.is_verified, p.verification_type,
    EXISTS(SELECT 1 FROM likes WHERE user_id = p_user_id AND tweet_id = t.id) AS is_liked,
    EXISTS(SELECT 1 FROM retweets WHERE user_id = p_user_id AND tweet_id = t.id) AS is_retweeted,
    EXISTS(SELECT 1 FROM bookmarks WHERE user_id = p_user_id AND tweet_id = t.id) AS is_bookmarked
  FROM tweets t
  JOIN profiles p ON p.user_id = t.user_id
  WHERE (t.user_id = p_user_id OR EXISTS(SELECT 1 FROM follows WHERE follower_id = p_user_id AND following_id = t.user_id) OR t.user_id IS NOT NULL)
  ORDER BY t.created_at DESC
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql SECURITY DEFINER;

-- Create Tweet
CREATE OR REPLACE FUNCTION create_tweet(p_user_id UUID, p_content TEXT, p_media_urls TEXT[] DEFAULT '{}', p_media_type TEXT DEFAULT 'none', p_reply_to_id UUID DEFAULT NULL, p_quote_tweet_id UUID DEFAULT NULL)
RETURNS UUID AS $$
DECLARE
  v_tweet_id UUID;
BEGIN
  INSERT INTO tweets (user_id, content, media_urls, media_type, reply_to_id, quote_tweet_id)
  VALUES (p_user_id, p_content, p_media_urls, p_media_type, p_reply_to_id, p_quote_tweet_id)
  RETURNING id INTO v_tweet_id;

  IF p_reply_to_id IS NOT NULL THEN
    UPDATE tweets SET replies_count = replies_count + 1 WHERE id = p_reply_to_id;
  END IF;

  RETURN v_tweet_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle Like
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
    INSERT INTO notifications (user_id, actor_id, tweet_id, type, message)
    SELECT t.user_id, p_user_id, p_tweet_id, 'like', 'أعجب بتعليقك'
    FROM tweets t WHERE t.id = p_tweet_id AND t.user_id != p_user_id;
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle Retweet
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
    INSERT INTO notifications (user_id, actor_id, tweet_id, type, message)
    SELECT t.user_id, p_user_id, p_tweet_id, 'retweet', 'أعاد نشر تغريدتك'
    FROM tweets t WHERE t.id = p_tweet_id AND t.user_id != p_user_id;
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle Bookmark
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

-- Toggle Follow
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
    INSERT INTO notifications (user_id, actor_id, type, message)
    VALUES (p_following_id, p_follower_id, 'follow', 'بدأ بمتابعتك');
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get User Profile
CREATE OR REPLACE FUNCTION get_user_profile(p_user_id UUID, p_target_id UUID)
RETURNS TABLE(id UUID, user_id UUID, display_name TEXT, username TEXT, bio TEXT, avatar_url TEXT, cover_url TEXT,
              is_verified BOOLEAN, verification_type TEXT, is_private BOOLEAN, followers_count INT,
              following_count INT, tweets_count INT, is_following BOOLEAN, is_blocked BOOLEAN) AS $$
  SELECT
    p.id, p.user_id, p.display_name, p.username, p.bio, p.avatar_url, p.cover_url,
    p.is_verified, p.verification_type, p.is_private, p.followers_count,
    p.following_count, p.tweets_count,
    EXISTS(SELECT 1 FROM follows WHERE follower_id = p_user_id AND following_id = p_target_id),
    EXISTS(SELECT 1 FROM blocks WHERE blocker_id = p_user_id AND blocked_id = p_target_id)
  FROM profiles p
  WHERE p.user_id = p_target_id;
$$ LANGUAGE sql SECURITY DEFINER;

-- Search Users
CREATE OR REPLACE FUNCTION search_users(p_query TEXT, p_limit INT DEFAULT 20)
RETURNS TABLE(id UUID, user_id UUID, display_name TEXT, username TEXT, avatar_url TEXT, is_verified BOOLEAN, verification_type TEXT, followers_count INT) AS $$
  SELECT id, user_id, display_name, username, avatar_url, is_verified, verification_type, followers_count
  FROM profiles
  WHERE display_name ILIKE '%' || p_query || '%' OR username ILIKE '%' || p_query || '%'
  ORDER BY followers_count DESC
  LIMIT p_limit;
$$ LANGUAGE sql SECURITY DEFINER;

-- Search Tweets
CREATE OR REPLACE FUNCTION search_tweets(p_query TEXT, p_limit INT DEFAULT 20)
RETURNS TABLE(id UUID, user_id UUID, content TEXT, media_urls TEXT[], media_type TEXT,
              likes_count INT, retweets_count INT, replies_count INT, created_at TIMESTAMPTZ,
              display_name TEXT, username TEXT, avatar_url TEXT, is_verified BOOLEAN, verification_type TEXT) AS $$
  SELECT t.id, t.user_id, t.content, t.media_urls, t.media_type,
         t.likes_count, t.retweets_count, t.replies_count, t.created_at,
         p.display_name, p.username, p.avatar_url, p.is_verified, p.verification_type
  FROM tweets t
  JOIN profiles p ON p.user_id = t.user_id
  WHERE t.content ILIKE '%' || p_query || '%'
  ORDER BY t.created_at DESC
  LIMIT p_limit;
$$ LANGUAGE sql SECURITY DEFINER;

-- Get Replies
CREATE OR REPLACE FUNCTION get_tweet_replies(p_tweet_id UUID, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE(id UUID, user_id UUID, content TEXT, media_urls TEXT[], media_type TEXT,
              likes_count INT, retweets_count INT, replies_count INT, created_at TIMESTAMPTZ,
              display_name TEXT, username TEXT, avatar_url TEXT, is_verified BOOLEAN, verification_type TEXT) AS $$
  SELECT t.id, t.user_id, t.content, t.media_urls, t.media_type,
         t.likes_count, t.retweets_count, t.replies_count, t.created_at,
         p.display_name, p.username, p.avatar_url, p.is_verified, p.verification_type
  FROM tweets t
  JOIN profiles p ON p.user_id = t.user_id
  WHERE t.reply_to_id = p_tweet_id
  ORDER BY t.created_at ASC
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql SECURITY DEFINER;

-- Get User Notifications
CREATE OR REPLACE FUNCTION get_user_notifications(p_user_id UUID, p_limit INT DEFAULT 30, p_offset INT DEFAULT 0)
RETURNS TABLE(id UUID, user_id UUID, actor_id UUID, type TEXT, tweet_id UUID, message TEXT,
              is_read BOOLEAN, created_at TIMESTAMPTZ, actor_name TEXT, actor_username TEXT, actor_avatar TEXT) AS $$
  SELECT n.id, n.user_id, n.actor_id, n.type, n.tweet_id, n.message, n.is_read, n.created_at,
         a.display_name AS actor_name, a.username AS actor_username, a.avatar_url AS actor_avatar
  FROM notifications n
  LEFT JOIN profiles a ON a.user_id = n.actor_id
  WHERE n.user_id = p_user_id
  ORDER BY n.created_at DESC
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql SECURITY DEFINER;

-- Mark Notifications Read
CREATE OR REPLACE FUNCTION mark_notifications_read(p_user_id UUID)
RETURNS VOID AS $$
  UPDATE notifications SET is_read = TRUE WHERE user_id = p_user_id AND is_read = FALSE;
$$ LANGUAGE sql SECURITY DEFINER;

-- Get Unread Notifications Count
CREATE OR REPLACE FUNCTION get_unread_notifications_count(p_user_id UUID)
RETURNS INT AS $$
  SELECT COUNT(*) FROM notifications WHERE user_id = p_user_id AND is_read = FALSE;
$$ LANGUAGE sql SECURITY DEFINER;

-- Get or Create Conversation
CREATE OR REPLACE FUNCTION get_or_create_conversation(p_user1 UUID, p_user2 UUID)
RETURNS UUID AS $$
DECLARE
  v_conv_id UUID;
BEGIN
  SELECT c.id INTO v_conv_id
  FROM conversations c
  JOIN conversation_participants cp1 ON cp1.conversation_id = c.id AND cp1.user_id = p_user1
  JOIN conversation_participants cp2 ON cp2.conversation_id = c.id AND cp2.user_id = p_user2
  LIMIT 1;

  IF v_conv_id IS NULL THEN
    INSERT INTO conversations (updated_at) VALUES (NOW()) RETURNING id INTO v_conv_id;
    INSERT INTO conversation_participants (conversation_id, user_id) VALUES (v_conv_id, p_user1);
    INSERT INTO conversation_participants (conversation_id, user_id) VALUES (v_conv_id, p_user2);
  END IF;

  RETURN v_conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get User Conversations
CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id UUID)
RETURNS TABLE(id UUID, updated_at TIMESTAMPTZ, other_user_id UUID, other_name TEXT, other_username TEXT, other_avatar TEXT, last_message TEXT, last_message_time TIMESTAMPTZ) AS $$
  SELECT c.id, c.updated_at,
    cp.user_id AS other_user_id, p.display_name AS other_name, p.username AS other_username, p.avatar_url AS other_avatar,
    m.content AS last_message, m.created_at AS last_message_time
  FROM conversations c
  JOIN conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id != p_user_id
  JOIN conversation_participants me ON me.conversation_id = c.id AND me.user_id = p_user_id
  JOIN profiles p ON p.user_id = cp.user_id
  LEFT JOIN LATERAL (SELECT content, created_at FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) m ON TRUE
  ORDER BY c.id, c.updated_at DESC;
$$ LANGUAGE sql SECURITY DEFINER;

-- Get Conversation Messages
CREATE OR REPLACE FUNCTION get_conversation_messages(p_conversation_id UUID, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0)
RETURNS TABLE(id UUID, conversation_id UUID, sender_id UUID, content TEXT, media_url TEXT, message_type TEXT, is_read BOOLEAN, created_at TIMESTAMPTZ, sender_name TEXT, sender_username TEXT, sender_avatar TEXT) AS $$
  SELECT m.id, m.conversation_id, m.sender_id, m.content, m.media_url, m.message_type, m.is_read, m.created_at,
         p.display_name AS sender_name, p.username AS sender_username, p.avatar_url AS sender_avatar
  FROM messages m
  JOIN profiles p ON p.user_id = m.sender_id
  WHERE m.conversation_id = p_conversation_id
  ORDER BY m.created_at ASC
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql SECURITY DEFINER;

-- Send Message
CREATE OR REPLACE FUNCTION send_message(p_conversation_id UUID, p_sender_id UUID, p_content TEXT, p_media_url TEXT DEFAULT '', p_message_type TEXT DEFAULT 'text')
RETURNS UUID AS $$
DECLARE
  v_msg_id UUID;
BEGIN
  INSERT INTO messages (conversation_id, sender_id, content, media_url, message_type)
  VALUES (p_conversation_id, p_sender_id, p_content, p_media_url, p_message_type)
  RETURNING id INTO v_msg_id;

  UPDATE conversations SET updated_at = NOW() WHERE id = p_conversation_id;
  RETURN v_msg_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update Profile
CREATE OR REPLACE FUNCTION update_user_profile(
  p_user_id UUID,
  p_display_name TEXT DEFAULT NULL,
  p_username TEXT DEFAULT NULL,
  p_bio TEXT DEFAULT NULL,
  p_avatar_url TEXT DEFAULT NULL,
  p_cover_url TEXT DEFAULT NULL,
  p_location TEXT DEFAULT NULL,
  p_website TEXT DEFAULT NULL
) RETURNS VOID AS $$
  UPDATE profiles SET
    display_name = COALESCE(p_display_name, display_name),
    username = COALESCE(p_username, username),
    bio = COALESCE(p_bio, bio),
    avatar_url = COALESCE(p_avatar_url, avatar_url),
    cover_url = COALESCE(p_cover_url, cover_url),
    location = COALESCE(p_location, location),
    website = COALESCE(p_website, website),
    updated_at = NOW()
  WHERE user_id = p_user_id;
$$ LANGUAGE sql SECURITY DEFINER;

-- Get User Tweets
CREATE OR REPLACE FUNCTION get_user_tweets(p_user_id UUID, p_target_id UUID, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE(id UUID, user_id UUID, content TEXT, media_urls TEXT[], media_type TEXT,
              likes_count INT, retweets_count INT, replies_count INT, bookmarks_count INT,
              created_at TIMESTAMPTZ, is_liked BOOLEAN, is_retweeted BOOLEAN, is_bookmarked BOOLEAN) AS $$
  SELECT
    t.id, t.user_id, t.content, t.media_urls, t.media_type,
    t.likes_count, t.retweets_count, t.replies_count, t.bookmarks_count, t.created_at,
    EXISTS(SELECT 1 FROM likes WHERE user_id = p_user_id AND tweet_id = t.id),
    EXISTS(SELECT 1 FROM retweets WHERE user_id = p_user_id AND tweet_id = t.id),
    EXISTS(SELECT 1 FROM bookmarks WHERE user_id = p_user_id AND tweet_id = t.id)
  FROM tweets t
  WHERE t.user_id = p_target_id AND t.reply_to_id IS NULL
  ORDER BY t.created_at DESC
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql SECURITY DEFINER;

-- Get Trending Hashtags
CREATE OR REPLACE FUNCTION get_trending_hashtags(p_limit INT DEFAULT 20)
RETURNS TABLE(tag TEXT, count INT) AS $$
  SELECT tag, count FROM hashtags ORDER BY count DESC LIMIT p_limit;
$$ LANGUAGE sql SECURITY DEFINER;

-- ============================================
-- STORAGE BUCKETS
-- ============================================
INSERT INTO storage.buckets (id, name, public) VALUES
  ('avatars', 'avatars', true),
  ('covers', 'covers', true),
  ('media', 'media', true),
  ('reels', 'reels', true),
  ('chat-media', 'chat-media', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies (open)
CREATE POLICY "Public read" ON storage.objects FOR SELECT USING (true);
CREATE POLICY "Authenticated insert" ON storage.objects FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Owner delete" ON storage.objects FOR DELETE USING (auth.uid() = (auth.jwt() ->> 'sub')::uuid);

-- ============================================
-- ENABLE REALTIME
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE tweets;