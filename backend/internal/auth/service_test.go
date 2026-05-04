package auth

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strings"
	"testing"

	"github.com/toktak/backend/internal/database"
)

type roundTripperFunc func(*http.Request) (*http.Response, error)

func (f roundTripperFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

func TestLoginWithGoogleCreatesAndReusesUser(t *testing.T) {
	store, err := database.NewStore(filepath.Join(t.TempDir(), "toktak.db"))
	if err != nil {
		t.Fatalf("new store: %v", err)
	}
	defer store.Close()

	service := NewService(store, "google-client-id", "line-channel-id")
	service.httpClient = &http.Client{
		Transport: roundTripperFunc(func(req *http.Request) (*http.Response, error) {
			switch {
			case strings.Contains(req.URL.Host, "oauth2.googleapis.com"):
				return jsonResponse(http.StatusOK, `{"sub":"google-sub-1","email":"user@example.com","name":"Google User","picture":"https://example.com/google.png","aud":"google-client-id","iss":"accounts.google.com"}`), nil
			default:
				return nil, fmt.Errorf("unexpected request: %s", req.URL.String())
			}
		}),
	}

	first, err := service.LoginWithGoogle(context.Background(), "google-id-token")
	if err != nil {
		t.Fatalf("first login: %v", err)
	}
	second, err := service.LoginWithGoogle(context.Background(), "google-id-token")
	if err != nil {
		t.Fatalf("second login: %v", err)
	}

	if first.User.ID != second.User.ID {
		t.Fatalf("expected same user id, got %s and %s", first.User.ID, second.User.ID)
	}
	if first.AccessToken == second.AccessToken {
		t.Fatalf("expected a fresh access token per session")
	}
}

func TestLoginWithLineCreatesAndReusesUser(t *testing.T) {
	store, err := database.NewStore(filepath.Join(t.TempDir(), "toktak.db"))
	if err != nil {
		t.Fatalf("new store: %v", err)
	}
	defer store.Close()

	service := NewService(store, "google-client-id", "line-channel-id")
	service.httpClient = &http.Client{
		Transport: roundTripperFunc(func(req *http.Request) (*http.Response, error) {
			switch {
			case strings.Contains(req.URL.Host, "api.line.me") && strings.Contains(req.URL.Path, "/v2/profile"):
				return jsonResponse(http.StatusOK, `{"userId":"line-user-1","displayName":"LINE User","pictureUrl":"https://example.com/line.png"}`), nil
			default:
				return nil, fmt.Errorf("unexpected request: %s", req.URL.String())
			}
		}),
	}

	first, err := service.LoginWithLine(context.Background(), "line-access-token")
	if err != nil {
		t.Fatalf("first login: %v", err)
	}
	second, err := service.LoginWithLine(context.Background(), "line-access-token")
	if err != nil {
		t.Fatalf("second login: %v", err)
	}

	if first.User.ID != second.User.ID {
		t.Fatalf("expected same user id, got %s and %s", first.User.ID, second.User.ID)
	}
	if first.User.Provider != "line" {
		t.Fatalf("expected provider line, got %q", first.User.Provider)
	}
}

func jsonResponse(statusCode int, body string) *http.Response {
	return &http.Response{
		StatusCode: statusCode,
		Body:       io.NopCloser(bytes.NewBufferString(body)),
		Header:     make(http.Header),
	}
}
