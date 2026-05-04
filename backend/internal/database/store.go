package database

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	_ "modernc.org/sqlite"
)

type Store struct {
	db *sql.DB
}

type User struct {
	ID           string    `json:"id"`
	Email        string    `json:"email,omitempty"`
	Username     string    `json:"username"`
	DisplayName  string    `json:"display_name,omitempty"`
	AvatarURL    string    `json:"avatar_url,omitempty"`
	Bio          string    `json:"bio,omitempty"`
	VideosCount  int       `json:"videos_count"`
	LikesCount   int       `json:"likes_count"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at,omitempty"`
	Provider     string    `json:"provider,omitempty"`
	ProviderUser string    `json:"provider_user_id,omitempty"`
}

type UpsertUserInput struct {
	Provider       string
	ProviderUserID string
	Email          string
	Username       string
	DisplayName    string
	AvatarURL      string
	Bio            string
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

func NewStore(dbPath string) (*Store, error) {
	if strings.TrimSpace(dbPath) == "" {
		dbPath = filepath.Join("data", "toktak.db")
	}

	cleanPath := filepath.Clean(dbPath)
	if err := os.MkdirAll(filepath.Dir(cleanPath), 0o755); err != nil {
		return nil, fmt.Errorf("create db dir: %w", err)
	}

	db, err := sql.Open("sqlite", "file:"+filepath.ToSlash(cleanPath)+"?_pragma=foreign_keys(1)&_pragma=busy_timeout(5000)")
	if err != nil {
		return nil, fmt.Errorf("open db: %w", err)
	}

	store := &Store{db: db}
	if err := store.migrate(context.Background()); err != nil {
		_ = db.Close()
		return nil, err
	}

	return store, nil
}

func (s *Store) Close() error {
	if s == nil || s.db == nil {
		return nil
	}
	return s.db.Close()
}

func (s *Store) migrate(ctx context.Context) error {
	statements := []string{
		`CREATE TABLE IF NOT EXISTS users (
			id TEXT PRIMARY KEY,
			email TEXT,
			username TEXT NOT NULL UNIQUE,
			display_name TEXT,
			avatar_url TEXT,
			bio TEXT,
			created_at TEXT NOT NULL,
			updated_at TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS auth_providers (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			provider TEXT NOT NULL,
			provider_id TEXT NOT NULL,
			created_at TEXT NOT NULL,
			UNIQUE(provider, provider_id),
			FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS sessions (
			refresh_token TEXT PRIMARY KEY,
			access_token TEXT NOT NULL UNIQUE,
			user_id TEXT NOT NULL,
			expires_at TEXT NOT NULL,
			created_at TEXT NOT NULL,
			FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
		);`,
	}

	for _, statement := range statements {
		if _, err := s.db.ExecContext(ctx, statement); err != nil {
			return fmt.Errorf("migrate schema: %w", err)
		}
	}

	return nil
}

func (s *Store) FindUserByProvider(ctx context.Context, provider, providerUserID string) (*User, error) {
	query := `
		SELECT u.id, u.email, u.username, u.display_name, u.avatar_url, u.bio, u.created_at, u.updated_at, ap.provider, ap.provider_id,
		       (SELECT COUNT(*) FROM videos WHERE user_id = u.id) AS videos_count,
		       (SELECT COALESCE(SUM(likes_count), 0) FROM videos WHERE user_id = u.id) AS likes_count
		FROM auth_providers ap
		JOIN users u ON u.id = ap.user_id
		WHERE ap.provider = ? AND ap.provider_id = ?
		LIMIT 1
	`

	row := s.db.QueryRowContext(ctx, query, provider, providerUserID)
	user, err := scanUser(row)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	return &user, nil
}

func (s *Store) GetUserByID(ctx context.Context, userID string) (*User, error) {
	query := `
		SELECT u.id, u.email, u.username, u.display_name, u.avatar_url, u.bio, u.created_at, u.updated_at, ap.provider, ap.provider_id,
		       (SELECT COUNT(*) FROM videos WHERE user_id = u.id) AS videos_count,
		       (SELECT COALESCE(SUM(likes_count), 0) FROM videos WHERE user_id = u.id) AS likes_count
		FROM users u
		LEFT JOIN auth_providers ap ON ap.user_id = u.id
		WHERE u.id = ?
		LIMIT 1
	`

	row := s.db.QueryRowContext(ctx, query, userID)
	user, err := scanUser(row)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	return &user, nil
}

func (s *Store) UpsertUserByProvider(ctx context.Context, input UpsertUserInput) (*User, error) {
	if input.CreatedAt.IsZero() {
		input.CreatedAt = time.Now().UTC()
	}
	if input.UpdatedAt.IsZero() {
		input.UpdatedAt = input.CreatedAt
	}

	user, err := s.FindUserByProvider(ctx, input.Provider, input.ProviderUserID)
	if err != nil {
		return nil, err
	}
	if user != nil {
		if _, err := s.db.ExecContext(ctx, `
			UPDATE users
			SET email = ?, username = ?, display_name = ?, avatar_url = ?, bio = ?, updated_at = ?
			WHERE id = ?
		`, nullIfEmpty(input.Email), input.Username, nullIfEmpty(input.DisplayName), nullIfEmpty(input.AvatarURL), nullIfEmpty(input.Bio), input.UpdatedAt.Format(time.RFC3339), user.ID); err != nil {
			return nil, err
		}

		refreshed, err := s.GetUserByID(ctx, user.ID)
		if err != nil {
			return nil, err
		}
		if refreshed == nil {
			return nil, sql.ErrNoRows
		}
		return refreshed, nil
	}

	userID := newID()
	for {
		_, err = s.db.ExecContext(ctx, `
			INSERT INTO users (id, email, username, display_name, avatar_url, bio, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, nullIfEmpty(input.Email), input.Username, nullIfEmpty(input.DisplayName), nullIfEmpty(input.AvatarURL), nullIfEmpty(input.Bio), input.CreatedAt.Format(time.RFC3339), input.UpdatedAt.Format(time.RFC3339))
		if err == nil {
			break
		}
		if !isUniqueConstraintError(err) {
			return nil, err
		}

		input.Username = input.Username + "_" + shortID(input.ProviderUserID)
	}

	if _, err := s.db.ExecContext(ctx, `
		INSERT INTO auth_providers (user_id, provider, provider_id, created_at)
		VALUES (?, ?, ?, ?)
	`, userID, input.Provider, input.ProviderUserID, input.CreatedAt.Format(time.RFC3339)); err != nil {
		return nil, err
	}

	created, err := s.GetUserByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if created == nil {
		return nil, sql.ErrNoRows
	}
	return created, nil
}

func (s *Store) CreateSession(ctx context.Context, userID, accessToken, refreshToken string, expiresAt time.Time) error {
	now := time.Now().UTC()
	_, err := s.db.ExecContext(ctx, `
		INSERT INTO sessions (refresh_token, access_token, user_id, expires_at, created_at)
		VALUES (?, ?, ?, ?, ?)
	`, refreshToken, accessToken, userID, expiresAt.UTC().Format(time.RFC3339), now.Format(time.RFC3339))
	return err
}

func (s *Store) RotateSession(ctx context.Context, refreshToken, newAccessToken, newRefreshToken string, expiresAt time.Time) (*User, error) {
	row := s.db.QueryRowContext(ctx, `
		SELECT user_id
		FROM sessions
		WHERE refresh_token = ?
		LIMIT 1
	`, refreshToken)

	var userID string
	if err := row.Scan(&userID); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, sql.ErrNoRows
		}
		return nil, err
	}

	if _, err := s.db.ExecContext(ctx, `
		UPDATE sessions
		SET refresh_token = ?, access_token = ?, expires_at = ?
		WHERE refresh_token = ?
	`, newRefreshToken, newAccessToken, expiresAt.UTC().Format(time.RFC3339), refreshToken); err != nil {
		return nil, err
	}

	return s.GetUserByID(ctx, userID)
}

func scanUser(row *sql.Row) (User, error) {
	var user User
	var email, displayName, avatarURL, bio, provider, providerUserID sql.NullString
	var createdAt, updatedAt string

	err := row.Scan(
		&user.ID, &email, &user.Username, &displayName, &avatarURL, &bio,
		&createdAt, &updatedAt, &provider, &providerUserID,
		&user.VideosCount, &user.LikesCount,
	)
	if err != nil {
		return User{}, err
	}

	if email.Valid {
		user.Email = email.String
	}
	if displayName.Valid {
		user.DisplayName = displayName.String
	}
	if avatarURL.Valid {
		user.AvatarURL = avatarURL.String
	}
	if bio.Valid {
		user.Bio = bio.String
	}
	if provider.Valid {
		user.Provider = provider.String
	}
	if providerUserID.Valid {
		user.ProviderUser = providerUserID.String
	}

	if parsed, err := time.Parse(time.RFC3339, createdAt); err == nil {
		user.CreatedAt = parsed
	}
	if parsed, err := time.Parse(time.RFC3339, updatedAt); err == nil {
		user.UpdatedAt = parsed
	}

	return user, nil
}

func nullIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	return value
}

func isUniqueConstraintError(err error) bool {
	return err != nil && strings.Contains(strings.ToLower(err.Error()), "unique")
}

func newID() string {
	return "usr_" + randomHex(16)
}

func shortID(value string) string {
	if len(value) >= 8 {
		return value[:8]
	}
	return value + randomHex(8-len(value))
}

func randomHex(length int) string {
	if length <= 0 {
		return ""
	}
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return hex.EncodeToString([]byte(fmt.Sprintf("%d", time.Now().UTC().UnixNano())))[:length]
	}
	encoded := hex.EncodeToString(bytes)
	if len(encoded) > length {
		return encoded[:length]
	}
	return encoded
}
