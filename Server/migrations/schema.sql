-- 1. USERS
CREATE TABLE users (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    avatar VARCHAR(500),
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. FRIENDSHIPS
CREATE TABLE friendships (
    requester_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(10) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'ACCEPTED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (requester_id, addressee_id),
    CHECK (requester_id <> addressee_id)
);

-- Prevent duplicate relationships in opposite directions (A->B and B->A).
CREATE UNIQUE INDEX uq_friendships_pair
    ON friendships (
        LEAST(requester_id, addressee_id),
        GREATEST(requester_id, addressee_id)
    );

-- 3. POSTS
-- All posts are private to the author and their accepted friends.
CREATE TABLE posts (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_posts_user_created
    ON posts (user_id, created_at DESC);

-- 4. POST_MEDIA
CREATE TABLE post_media (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    media_type VARCHAR(20) NOT NULL
        CHECK (media_type IN ('IMAGE', 'VIDEO', 'AUDIO', 'FILE')),
    display_order INT NOT NULL DEFAULT 0
);

CREATE INDEX idx_post_media_post_order
    ON post_media (post_id, display_order);

-- 5. COMMENTS
-- comment chỉ hỗ trợ text!
CREATE TABLE comments (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_comment_id INT REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_comments_post_created
    ON comments (post_id, created_at);

CREATE INDEX idx_comments_parent
    ON comments (parent_comment_id)
    WHERE parent_comment_id IS NOT NULL;

-- 6. CONVERSATIONS
-- Bảng trò chuyện: có thể trò chuyện riêng tư hoặc trò chuyện nhóm
CREATE TABLE conversations (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type VARCHAR(20) NOT NULL
        CHECK (type IN ('DIRECT', 'GROUP')),
    name VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (
        (type = 'DIRECT' AND name IS NULL)
        OR
        (type = 'GROUP' AND name IS NOT NULL)
    )
);

-- 7. CONVERSATION_MEMBERS
CREATE TABLE conversation_members (
    conversation_id INT NOT NULL
        REFERENCES conversations(id) ON DELETE CASCADE,
    user_id INT NOT NULL
        REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (conversation_id, user_id)
);

CREATE INDEX idx_conversation_members_user
    ON conversation_members (user_id, conversation_id);

-- 8. MESSAGES
-- tin nhắn giữa các thành viên
CREATE TABLE messages (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sender_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    conversation_id INT NOT NULL
        REFERENCES conversations(id) ON DELETE CASCADE,
    parent_message_id INT REFERENCES messages(id) ON DELETE SET NULL,
    content TEXT,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation_sent
    ON messages (conversation_id, sent_at DESC);

-- 9. MESSAGE_MEDIA
-- tin nhắn giờ cũng hỗ trợ ảnh và video
CREATE TABLE message_media (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    message_id INT NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    media_type VARCHAR(20) NOT NULL
        CHECK (media_type IN ('IMAGE', 'VIDEO', 'AUDIO', 'FILE')),
    display_order INT NOT NULL DEFAULT 0
);

CREATE INDEX idx_message_media_message_order
    ON message_media (message_id, display_order);

-- 10. REACTIONS
CREATE TABLE reactions (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id INT REFERENCES posts(id) ON DELETE CASCADE,
    comment_id INT REFERENCES comments(id) ON DELETE CASCADE,
    message_id INT REFERENCES messages(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (num_nonnulls(post_id, comment_id, message_id) = 1)
);

CREATE UNIQUE INDEX uq_reactions_user_post
    ON reactions (user_id, post_id)
    WHERE post_id IS NOT NULL;

CREATE UNIQUE INDEX uq_reactions_user_comment
    ON reactions (user_id, comment_id)
    WHERE comment_id IS NOT NULL;

CREATE UNIQUE INDEX uq_reactions_user_message
    ON reactions (user_id, message_id)
    WHERE message_id IS NOT NULL;

-- 11. NOTIFICATIONS
CREATE TABLE notifications (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type VARCHAR(20) NOT NULL
        CHECK (type IN (
            'REACTED',
            'COMMENTED',
            'FRIEND_REQUEST',
            'FRIEND_ACCEPTED',
            'MESSAGED'
        )),
    sender_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id INT REFERENCES posts(id) ON DELETE CASCADE,
    comment_id INT REFERENCES comments(id) ON DELETE CASCADE,
    message_id INT REFERENCES messages(id) ON DELETE CASCADE,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_receiver
    ON notifications (receiver_id, is_read, created_at DESC);