BEGIN;

CREATE TABLE friendships (
    requester_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(10) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACCEPTED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (requester_id, addressee_id),
    CHECK (requester_id <> addressee_id)
);

DROP TABLE follows;

ALTER TABLE posts DROP CONSTRAINT posts_privacy_check;
ALTER TABLE posts ADD CONSTRAINT posts_privacy_check CHECK (privacy IN ('FRIENDS', 'PRIVATE'));
ALTER TABLE posts ALTER COLUMN privacy SET DEFAULT 'FRIENDS';
ALTER TABLE posts DROP COLUMN privacy;
DROP TABLE comment_media;
DROP TABLE message_reads;

CREATE INDEX IF NOT EXISTS idx_posts_user_created ON posts (user_id, created_at DESC);

ALTER TABLE reactions DROP COLUMN story_id;
ALTER TABLE reactions
    ADD CONSTRAINT reactions_one_target_check
    CHECK (num_nonnulls(post_id, comment_id, message_id) = 1);

DELETE FROM notifications WHERE type = 'SHARED';
ALTER TABLE notifications DROP CONSTRAINT notifications_type_check;
UPDATE notifications SET type = 'FRIEND_REQUEST' WHERE type = 'FOLLOWED';
ALTER TABLE notifications
    ADD CONSTRAINT notifications_type_check
    CHECK (type IN ('REACTED', 'COMMENTED', 'FRIEND_REQUEST', 'FRIEND_ACCEPTED', 'MESSAGED'));

DROP TABLE IF EXISTS story_views;
DROP TABLE IF EXISTS stories;
DROP TABLE IF EXISTS shares;
DROP TABLE IF EXISTS saved_posts;

COMMIT;