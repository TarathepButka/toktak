package database

import (
	"context"
	"path/filepath"
	"testing"
	"time"
)

func TestUpsertUserByProviderCreatesAndUpdatesUser(t *testing.T) {
	store, err := NewStore(filepath.Join(t.TempDir(), "toktak.db"))
	if err != nil {
		t.Fatalf("new store: %v", err)
	}
	defer store.Close()

	ctx := context.Background()
	first, err := store.UpsertUserByProvider(ctx, UpsertUserInput{
		Provider:       "google",
		ProviderUserID: "google-sub-123",
		Email:          "creator@example.com",
		Username:       "creator",
		DisplayName:    "Creator One",
		AvatarURL:      "https://example.com/avatar.png",
		CreatedAt:      time.Now().UTC(),
		UpdatedAt:      time.Now().UTC(),
	})
	if err != nil {
		t.Fatalf("first upsert: %v", err)
	}

	second, err := store.UpsertUserByProvider(ctx, UpsertUserInput{
		Provider:       "google",
		ProviderUserID: "google-sub-123",
		Email:          "creator@example.com",
		Username:       "creator-updated",
		DisplayName:    "Creator Two",
		AvatarURL:      "https://example.com/avatar-2.png",
		CreatedAt:      time.Now().UTC(),
		UpdatedAt:      time.Now().UTC(),
	})
	if err != nil {
		t.Fatalf("second upsert: %v", err)
	}

	if first.ID != second.ID {
		t.Fatalf("expected same user id, got %s and %s", first.ID, second.ID)
	}
	if second.DisplayName != "Creator Two" {
		t.Fatalf("expected updated display name, got %q", second.DisplayName)
	}

	var providerCount int
	if err := store.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM auth_providers WHERE provider = ? AND provider_id = ?`, "google", "google-sub-123").Scan(&providerCount); err != nil {
		t.Fatalf("count provider rows: %v", err)
	}
	if providerCount != 1 {
		t.Fatalf("expected exactly one auth provider row, got %d", providerCount)
	}

	var userCount int
	if err := store.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM users`).Scan(&userCount); err != nil {
		t.Fatalf("count users: %v", err)
	}
	if userCount != 1 {
		t.Fatalf("expected one user row, got %d", userCount)
	}
}
