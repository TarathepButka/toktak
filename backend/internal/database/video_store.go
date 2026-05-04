package database

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"
)

// ─── Structs ──────────────────────────────────────────────────

type VideoAuthor struct {
	ID          string `json:"id"`
	Username    string `json:"username"`
	DisplayName string `json:"display_name,omitempty"`
	AvatarURL   string `json:"avatar_url,omitempty"`
}

type Video struct {
	ID            string       `json:"id"`
	UserID        string       `json:"user_id"`
	VideoURL      string       `json:"video_url"`
	ThumbnailURL  string       `json:"thumbnail_url"`
	Caption       string       `json:"caption,omitempty"`
	DurationMs    int          `json:"duration_ms"`
	LikesCount    int          `json:"likes_count"`
	CommentsCount int          `json:"comments_count"`
	ViewsCount    int          `json:"views_count"`
	IsLiked       bool         `json:"is_liked"`
	CreatedAt     time.Time    `json:"created_at"`
	Author        *VideoAuthor `json:"author,omitempty"`
}

type CreateVideoInput struct {
	UserID       string
	VideoURL     string
	ThumbnailURL string
	Caption      string
	DurationMs   int
}

// ─── Feed ─────────────────────────────────────────────────────

// GetFeedVideos returns paginated feed videos with author info.
// requestingUserID is used to populate is_liked; pass "" to skip.
func (s *Store) GetFeedVideos(ctx context.Context, limit, offset int, requestingUserID string) ([]Video, error) {
	query := `
		SELECT
			v.id, v.user_id, v.video_url, v.thumbnail_url, COALESCE(v.caption,''),
			COALESCE(v.duration_ms,0), COALESCE(v.likes_count,0),
			COALESCE(v.comments_count,0), COALESCE(v.views_count,0),
			v.created_at,
			u.id, u.username, COALESCE(u.display_name,''), COALESCE(u.avatar_url,''),
			CASE WHEN l.user_id IS NOT NULL THEN 1 ELSE 0 END AS is_liked
		FROM videos v
		JOIN users u ON u.id = v.user_id
		LEFT JOIN likes l ON l.video_id = v.id AND l.user_id = ?
		ORDER BY v.created_at DESC
		LIMIT ? OFFSET ?
	`
	rows, err := s.db.QueryContext(ctx, query, requestingUserID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("get feed: %w", err)
	}
	defer rows.Close()

	return scanVideos(rows)
}

// ─── Videos ───────────────────────────────────────────────────

func (s *Store) GetVideoByID(ctx context.Context, videoID, requestingUserID string) (*Video, error) {
	query := `
		SELECT
			v.id, v.user_id, v.video_url, v.thumbnail_url, COALESCE(v.caption,''),
			COALESCE(v.duration_ms,0), COALESCE(v.likes_count,0),
			COALESCE(v.comments_count,0), COALESCE(v.views_count,0),
			v.created_at,
			u.id, u.username, COALESCE(u.display_name,''), COALESCE(u.avatar_url,''),
			CASE WHEN l.user_id IS NOT NULL THEN 1 ELSE 0 END AS is_liked
		FROM videos v
		JOIN users u ON u.id = v.user_id
		LEFT JOIN likes l ON l.video_id = v.id AND l.user_id = ?
		WHERE v.id = ?
		LIMIT 1
	`
	rows, err := s.db.QueryContext(ctx, query, requestingUserID, videoID)
	if err != nil {
		return nil, fmt.Errorf("get video: %w", err)
	}
	defer rows.Close()

	videos, err := scanVideos(rows)
	if err != nil {
		return nil, err
	}
	if len(videos) == 0 {
		return nil, sql.ErrNoRows
	}
	return &videos[0], nil
}

func (s *Store) CreateVideo(ctx context.Context, input CreateVideoInput) (*Video, error) {
	id := "vid_" + randomHex(16)
	now := time.Now().UTC().Format(time.RFC3339)
	_, err := s.db.ExecContext(ctx, `
		INSERT INTO videos (id, user_id, video_url, thumbnail_url, caption, duration_ms, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)
	`, id, input.UserID, input.VideoURL, input.ThumbnailURL, nullIfEmpty(input.Caption), input.DurationMs, now)
	if err != nil {
		return nil, fmt.Errorf("create video: %w", err)
	}
	return s.GetVideoByID(ctx, id, input.UserID)
}

func (s *Store) GetUserVideos(ctx context.Context, userID, requestingUserID string, limit, offset int) ([]Video, error) {
	query := `
		SELECT
			v.id, v.user_id, v.video_url, v.thumbnail_url, COALESCE(v.caption,''),
			COALESCE(v.duration_ms,0), COALESCE(v.likes_count,0),
			COALESCE(v.comments_count,0), COALESCE(v.views_count,0),
			v.created_at,
			u.id, u.username, COALESCE(u.display_name,''), COALESCE(u.avatar_url,''),
			CASE WHEN l.user_id IS NOT NULL THEN 1 ELSE 0 END AS is_liked
		FROM videos v
		JOIN users u ON u.id = v.user_id
		LEFT JOIN likes l ON l.video_id = v.id AND l.user_id = ?
		WHERE v.user_id = ?
		ORDER BY v.created_at DESC
		LIMIT ? OFFSET ?
	`
	rows, err := s.db.QueryContext(ctx, query, requestingUserID, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("get user videos: %w", err)
	}
	defer rows.Close()
	return scanVideos(rows)
}

// ─── Likes ────────────────────────────────────────────────────

func (s *Store) LikeVideo(ctx context.Context, userID, videoID string) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback() //nolint:errcheck

	_, err = tx.ExecContext(ctx, `
		INSERT OR IGNORE INTO likes (user_id, video_id, created_at)
		VALUES (?, ?, ?)
	`, userID, videoID, time.Now().UTC().Format(time.RFC3339))
	if err != nil {
		return fmt.Errorf("insert like: %w", err)
	}

	_, err = tx.ExecContext(ctx, `
		UPDATE videos SET likes_count = likes_count + 1 WHERE id = ?
	`, videoID)
	if err != nil {
		return fmt.Errorf("increment likes: %w", err)
	}

	return tx.Commit()
}

func (s *Store) UnlikeVideo(ctx context.Context, userID, videoID string) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback() //nolint:errcheck

	res, err := tx.ExecContext(ctx, `
		DELETE FROM likes WHERE user_id = ? AND video_id = ?
	`, userID, videoID)
	if err != nil {
		return fmt.Errorf("delete like: %w", err)
	}

	// Only decrement if a row was actually deleted (idempotent)
	if n, _ := res.RowsAffected(); n > 0 {
		_, err = tx.ExecContext(ctx, `
			UPDATE videos SET likes_count = MAX(likes_count - 1, 0) WHERE id = ?
		`, videoID)
		if err != nil {
			return fmt.Errorf("decrement likes: %w", err)
		}
	}

	return tx.Commit()
}

// ─── Search ───────────────────────────────────────────────────

func (s *Store) SearchVideos(ctx context.Context, keyword, requestingUserID string, limit, offset int) ([]Video, error) {
	var query string
	var args []any

	if strings.TrimSpace(keyword) == "" {
		// No keyword → trending (most viewed)
		query = `
			SELECT
				v.id, v.user_id, v.video_url, v.thumbnail_url, COALESCE(v.caption,''),
				COALESCE(v.duration_ms,0), COALESCE(v.likes_count,0),
				COALESCE(v.comments_count,0), COALESCE(v.views_count,0),
				v.created_at,
				u.id, u.username, COALESCE(u.display_name,''), COALESCE(u.avatar_url,''),
				CASE WHEN l.user_id IS NOT NULL THEN 1 ELSE 0 END AS is_liked
			FROM videos v
			JOIN users u ON u.id = v.user_id
			LEFT JOIN likes l ON l.video_id = v.id AND l.user_id = ?
			ORDER BY v.views_count DESC, v.likes_count DESC
			LIMIT ? OFFSET ?
		`
		args = []any{requestingUserID, limit, offset}
	} else {
		pattern := "%" + keyword + "%"
		query = `
			SELECT
				v.id, v.user_id, v.video_url, v.thumbnail_url, COALESCE(v.caption,''),
				COALESCE(v.duration_ms,0), COALESCE(v.likes_count,0),
				COALESCE(v.comments_count,0), COALESCE(v.views_count,0),
				v.created_at,
				u.id, u.username, COALESCE(u.display_name,''), COALESCE(u.avatar_url,''),
				CASE WHEN l.user_id IS NOT NULL THEN 1 ELSE 0 END AS is_liked
			FROM videos v
			JOIN users u ON u.id = v.user_id
			LEFT JOIN likes l ON l.video_id = v.id AND l.user_id = ?
			WHERE v.caption LIKE ? OR u.username LIKE ? OR u.display_name LIKE ?
			ORDER BY v.views_count DESC
			LIMIT ? OFFSET ?
		`
		args = []any{requestingUserID, pattern, pattern, pattern, limit, offset}
	}

	rows, err := s.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("search videos: %w", err)
	}
	defer rows.Close()
	return scanVideos(rows)
}

// ─── Session lookup (for auth middleware) ─────────────────────

func (s *Store) GetUserIDByAccessToken(ctx context.Context, accessToken string) (string, error) {
	var userID string
	var expiresAt string
	err := s.db.QueryRowContext(ctx, `
		SELECT user_id, expires_at FROM sessions WHERE access_token = ? LIMIT 1
	`, accessToken).Scan(&userID, &expiresAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return "", fmt.Errorf("invalid token")
		}
		return "", err
	}

	// Check expiry
	exp, parseErr := time.Parse(time.RFC3339, expiresAt)
	if parseErr != nil || time.Now().UTC().After(exp) {
		return "", fmt.Errorf("token expired")
	}

	return userID, nil
}

// ─── Schema migration (videos + likes tables) ─────────────────

func (s *Store) MigrateVideoSchema(ctx context.Context) error {
	stmts := []string{
		`CREATE TABLE IF NOT EXISTS videos (
			id            TEXT PRIMARY KEY,
			user_id       TEXT NOT NULL,
			video_url     TEXT NOT NULL,
			thumbnail_url TEXT NOT NULL,
			caption       TEXT,
			duration_ms   INTEGER DEFAULT 0,
			likes_count   INTEGER DEFAULT 0,
			comments_count INTEGER DEFAULT 0,
			views_count   INTEGER DEFAULT 0,
			created_at    TEXT NOT NULL,
			FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS likes (
			user_id    TEXT NOT NULL,
			video_id   TEXT NOT NULL,
			created_at TEXT NOT NULL,
			PRIMARY KEY(user_id, video_id),
			FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
			FOREIGN KEY(video_id) REFERENCES videos(id) ON DELETE CASCADE
		);`,
		`CREATE INDEX IF NOT EXISTS idx_videos_user_id ON videos(user_id);`,
		`CREATE INDEX IF NOT EXISTS idx_videos_created_at ON videos(created_at DESC);`,
		`CREATE INDEX IF NOT EXISTS idx_likes_video_id ON likes(video_id);`,
	}
	for _, stmt := range stmts {
		if _, err := s.db.ExecContext(ctx, stmt); err != nil {
			return fmt.Errorf("migrate video schema: %w", err)
		}
	}
	return nil
}

// ─── Helpers ──────────────────────────────────────────────────

func scanVideos(rows *sql.Rows) ([]Video, error) {
	videos := []Video{} // initialize to empty slice, not nil → JSON [] not null
	for rows.Next() {
		var v Video
		var a VideoAuthor
		var caption, authorDisplayName, authorAvatarURL sql.NullString
		var isLikedInt int
		var createdAtStr string

		if err := rows.Scan(
			&v.ID, &v.UserID, &v.VideoURL, &v.ThumbnailURL, &caption,
			&v.DurationMs, &v.LikesCount, &v.CommentsCount, &v.ViewsCount,
			&createdAtStr,
			&a.ID, &a.Username, &authorDisplayName, &authorAvatarURL,
			&isLikedInt,
		); err != nil {
			return nil, fmt.Errorf("scan video: %w", err)
		}

		if caption.Valid {
			v.Caption = caption.String
		}
		if authorDisplayName.Valid {
			a.DisplayName = authorDisplayName.String
		}
		if authorAvatarURL.Valid {
			a.AvatarURL = authorAvatarURL.String
		}
		v.IsLiked = isLikedInt == 1
		if parsed, err := time.Parse(time.RFC3339, createdAtStr); err == nil {
			v.CreatedAt = parsed
		}
		v.Author = &a
		videos = append(videos, v)
	}
	return videos, rows.Err()
}
