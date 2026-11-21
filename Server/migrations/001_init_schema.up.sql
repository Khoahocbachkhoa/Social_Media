-- 1. USER 
CREATE TABLE users (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    avatar VARCHAR(500),
    bio TEXT,
    role VARCHAR(20) NOT NULL DEFAULT 'USER' CHECK (role IN ('ADMIN', 'USER')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. FOLLOWS
CREATE TABLE follows (
    follower_id INT NOT NULL,
    following_id INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id),
    CHECK (follower_id <> following_id),
    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. POSTS & POST_MEDIA
CREATE TABLE posts (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT,
    privacy VARCHAR(20) NOT NULL DEFAULT 'PUBLIC' CHECK (privacy IN ('PUBLIC', 'FRIENDS', 'PRIVATE')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE post_media (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id INT NOT NULL,
    media_url TEXT NOT NULL,
    media_type VARCHAR(20) NOT NULL CHECK (media_type IN ('IMAGE', 'VIDEO', 'AUDIO', 'FILE')),
    display_order INT NOT NULL DEFAULT 0,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
);

-- 4. COMMENTS & COMMENT_MEDIA
CREATE TABLE comments (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    parent_comment_id INT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES comments(id) ON DELETE CASCADE
);

CREATE TABLE comment_media (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    comment_id INT NOT NULL,
    media_url TEXT NOT NULL,
    media_type VARCHAR(20) NOT NULL CHECK (media_type IN ('IMAGE', 'VIDEO', 'AUDIO', 'FILE')),
    display_order INT NOT NULL DEFAULT 0,
    FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE
);

-- 5. SHARES & SAVED_POSTS
CREATE TABLE shares (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    caption TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE saved_posts (
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
);

-- 6. STORIES & STORY_VIEWS
CREATE TABLE stories (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    media_type VARCHAR(20) NOT NULL DEFAULT 'IMAGE' CHECK (media_type IN ('IMAGE', 'VIDEO')),
    media_url TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_stories_expires_at_user_id 
    ON stories (expires_at, user_id) INCLUDE (media_type, created_at);

CREATE TABLE story_views (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    story_id INT NOT NULL,
    user_id INT NOT NULL,
    viewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (story_id, user_id)
);

-- 7. CONVERSATIONS, MEMBERS, MESSAGES & READS
CREATE TABLE conversations (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type VARCHAR(20) NOT NULL CHECK (type IN ('DIRECT', 'GROUP')),
    name VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK ((type = 'DIRECT' AND name IS NULL) OR (type = 'GROUP' AND name IS NOT NULL))
);

CREATE TABLE conversation_members (
    conversation_id INT NOT NULL,
    user_id INT NOT NULL,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (conversation_id, user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

CREATE TABLE messages (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sender_id INT NOT NULL,
    conversation_id INT NOT NULL,
    parent_message_id INT NULL,
    content TEXT,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_message_id) REFERENCES messages(id) ON DELETE SET NULL
);

CREATE TABLE message_media (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    message_id INT NOT NULL,
    media_url TEXT NOT NULL,
    media_type VARCHAR(20) NOT NULL CHECK (media_type IN ('IMAGE', 'VIDEO', 'AUDIO', 'FILE')),
    display_order INT NOT NULL DEFAULT 0,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);

CREATE TABLE message_reads (
    user_id INT NOT NULL,
    message_id INT NOT NULL,
    read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, message_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);

-- 8. REACTIONS
CREATE TABLE reactions (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    post_id INT NULL,
    comment_id INT NULL,
    message_id INT NULL,
    story_id INT NULL,
    type VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE,

    -- Đảm bảo mỗi reaction chỉ gắn với đúng 1 đối tượng
    CHECK (
        num_nonnulls(post_id, comment_id, message_id, story_id) = 1
    )
);

-- Chống 1 user thả nhiều reaction trên cùng 1 đối tượng
CREATE UNIQUE INDEX uq_reactions_user_post ON reactions (user_id, post_id) WHERE post_id IS NOT NULL;
CREATE UNIQUE INDEX uq_reactions_user_comment ON reactions (user_id, comment_id) WHERE comment_id IS NOT NULL;
CREATE UNIQUE INDEX uq_reactions_user_message ON reactions (user_id, message_id) WHERE message_id IS NOT NULL;
CREATE UNIQUE INDEX uq_reactions_user_story ON reactions (user_id, story_id) WHERE story_id IS NOT NULL;

-- 9. NOTIFICATIONS
CREATE TABLE notifications (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type VARCHAR(20) NOT NULL CHECK (type IN ('REACTED', 'COMMENTED', 'FOLLOWED', 'MESSAGED', 'SHARED')),
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    post_id INT NULL,
    comment_id INT NULL,
    message_id INT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_receiver ON notifications(receiver_id, is_read, created_at DESC);