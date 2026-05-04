-- 001_initial_schema.up.sql

-- USERS
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE,
    username        VARCHAR(50) UNIQUE NOT NULL,
    display_name    VARCHAR(100),
    avatar_url      TEXT,
    bio             TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- AUTH PROVIDERS
CREATE TABLE IF NOT EXISTS auth_providers (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
    provider    VARCHAR(20) NOT NULL,
    provider_id VARCHAR(255) NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(provider, provider_id)
);

-- VIDEOS
CREATE TABLE IF NOT EXISTS videos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    video_url       TEXT NOT NULL,
    thumbnail_url   TEXT NOT NULL,
    caption         TEXT,
    duration_ms     INT,
    width           INT,
    height          INT,
    likes_count     INT DEFAULT 0,
    comments_count  INT DEFAULT 0,
    views_count     INT DEFAULT 0,
    status          VARCHAR(20) DEFAULT 'processing',
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- LIKES
CREATE TABLE IF NOT EXISTS likes (
    user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
    video_id   UUID REFERENCES videos(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, video_id)
);

-- COMMENTS (nested)
CREATE TABLE IF NOT EXISTS comments (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
    video_id   UUID REFERENCES videos(id) ON DELETE CASCADE,
    parent_id  UUID REFERENCES comments(id) ON DELETE CASCADE,
    content    TEXT NOT NULL,
    depth      INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- HASHTAGS
CREATE TABLE IF NOT EXISTS hashtags (
    id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS video_hashtags (
    video_id   UUID REFERENCES videos(id) ON DELETE CASCADE,
    hashtag_id UUID REFERENCES hashtags(id) ON DELETE CASCADE,
    PRIMARY KEY (video_id, hashtag_id)
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_videos_user_id ON videos(user_id);
CREATE INDEX IF NOT EXISTS idx_videos_created_at ON videos(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_videos_status ON videos(status);
CREATE INDEX IF NOT EXISTS idx_likes_video_id ON likes(video_id);
CREATE INDEX IF NOT EXISTS idx_comments_video_id ON comments(video_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_auth_providers_user ON auth_providers(user_id);
