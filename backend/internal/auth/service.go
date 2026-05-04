package auth

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"regexp"
	"strings"
	"time"

	"github.com/toktak/backend/internal/database"
)

type Service struct {
	store          *database.Store
	httpClient     *http.Client
	googleClientID string
	lineChannelID  string
	accessTTL      time.Duration
	refreshTTL     time.Duration
}

type AuthResponse struct {
	AccessToken  string         `json:"access_token"`
	RefreshToken string         `json:"refresh_token"`
	User         *database.User `json:"user"`
}

type GoogleTokenInfo struct {
	Sub           string `json:"sub"`
	Email         string `json:"email"`
	EmailVerified string `json:"email_verified"`
	Name          string `json:"name"`
	Picture       string `json:"picture"`
	Audience      string `json:"aud"`
	Issuer        string `json:"iss"`
}

type LineProfile struct {
	UserID      string `json:"userId"`
	DisplayName string `json:"displayName"`
	PictureURL  string `json:"pictureUrl"`
	Status      string `json:"statusMessage"`
}

func NewService(store *database.Store, googleClientID, lineChannelID string) *Service {
	if strings.TrimSpace(googleClientID) == "" {
		googleClientID = "72745167900-endgcp6logut3eo1jj8p7t26bspm4hua.apps.googleusercontent.com"
	}
	if strings.TrimSpace(lineChannelID) == "" {
		lineChannelID = "2009953695"
	}

	return &Service{
		store:          store,
		httpClient:     &http.Client{Timeout: 10 * time.Second},
		googleClientID: googleClientID,
		lineChannelID:  lineChannelID,
		accessTTL:      24 * time.Hour,
		refreshTTL:     30 * 24 * time.Hour,
	}
}

func (s *Service) LoginWithGoogle(ctx context.Context, idToken string) (*AuthResponse, error) {
	if strings.TrimSpace(idToken) == "" {
		return nil, errors.New("missing id_token")
	}

	profile, err := s.verifyGoogleIDToken(ctx, idToken)
	if err != nil {
		return nil, err
	}

	user, err := s.store.UpsertUserByProvider(ctx, database.UpsertUserInput{
		Provider:       "google",
		ProviderUserID: profile.Sub,
		Email:          profile.Email,
		Username:       usernameFromProfile(profile.Email, profile.Sub, "google"),
		DisplayName:    fallbackString(profile.Name, "Google User"),
		AvatarURL:      profile.Picture,
		CreatedAt:      time.Now().UTC(),
		UpdatedAt:      time.Now().UTC(),
	})
	if err != nil {
		return nil, err
	}

	return s.issueSession(ctx, user)
}

func (s *Service) LoginWithLine(ctx context.Context, accessToken string) (*AuthResponse, error) {
	if strings.TrimSpace(accessToken) == "" {
		return nil, errors.New("missing access_token")
	}

	profile, err := s.verifyLineAccessToken(ctx, accessToken)
	if err != nil {
		return nil, err
	}

	user, err := s.store.UpsertUserByProvider(ctx, database.UpsertUserInput{
		Provider:       "line",
		ProviderUserID: profile.UserID,
		Username:       usernameFromProfile("", profile.UserID, "line"),
		DisplayName:    fallbackString(profile.DisplayName, "LINE User"),
		AvatarURL:      profile.PictureURL,
		CreatedAt:      time.Now().UTC(),
		UpdatedAt:      time.Now().UTC(),
	})
	if err != nil {
		return nil, err
	}

	return s.issueSession(ctx, user)
}

func (s *Service) RefreshSession(ctx context.Context, refreshToken string) (*AuthResponse, error) {
	if strings.TrimSpace(refreshToken) == "" {
		return nil, errors.New("missing refresh_token")
	}

	newAccessToken := newToken("atk")
	newRefreshToken := newToken("rtk")
	user, err := s.store.RotateSession(ctx, refreshToken, newAccessToken, newRefreshToken, time.Now().UTC().Add(s.refreshTTL))
	if err != nil {
		return nil, err
	}

	return &AuthResponse{
		AccessToken:  newAccessToken,
		RefreshToken: newRefreshToken,
		User:         user,
	}, nil
}

func (s *Service) issueSession(ctx context.Context, user *database.User) (*AuthResponse, error) {
	accessToken := newToken("atk")
	refreshToken := newToken("rtk")
	if err := s.store.CreateSession(ctx, user.ID, accessToken, refreshToken, time.Now().UTC().Add(s.refreshTTL)); err != nil {
		return nil, err
	}

	return &AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	}, nil
}

func (s *Service) verifyGoogleIDToken(ctx context.Context, idToken string) (*GoogleTokenInfo, error) {
	endpoint := "https://oauth2.googleapis.com/tokeninfo?id_token=" + url.QueryEscape(idToken)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, err
	}

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("google token verification failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("google token verification failed: status %d", resp.StatusCode)
	}

	var info GoogleTokenInfo
	if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
		return nil, fmt.Errorf("decode google token response: %w", err)
	}

	if info.Sub == "" {
		return nil, errors.New("invalid google token payload")
	}
	if info.Audience != s.googleClientID {
		return nil, fmt.Errorf("google token audience mismatch: got %s", info.Audience)
	}
	if info.Issuer != "accounts.google.com" && info.Issuer != "https://accounts.google.com" {
		return nil, fmt.Errorf("google token issuer mismatch: %s", info.Issuer)
	}

	return &info, nil
}

func (s *Service) verifyLineAccessToken(ctx context.Context, accessToken string) (*LineProfile, error) {
	profileReq, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://api.line.me/v2/profile", nil)
	if err != nil {
		return nil, err
	}
	profileReq.Header.Set("Authorization", "Bearer "+accessToken)

	resp, err := s.httpClient.Do(profileReq)
	if err != nil {
		return nil, fmt.Errorf("line profile request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("line token verification failed: status %d", resp.StatusCode)
	}

	var profile LineProfile
	if err := json.NewDecoder(resp.Body).Decode(&profile); err != nil {
		return nil, fmt.Errorf("decode line profile response: %w", err)
	}
	if profile.UserID == "" {
		return nil, errors.New("invalid line profile payload")
	}
	return &profile, nil
}

func usernameFromProfile(email, providerID, provider string) string {
	if strings.TrimSpace(email) != "" {
		if localPart := strings.Split(email, "@")[0]; localPart != "" {
			return sanitizeUsername(localPart)
		}
	}

	base := provider + "_" + providerID
	if len(base) > 24 {
		base = base[:24]
	}
	return sanitizeUsername(base)
}

func sanitizeUsername(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	value = regexp.MustCompile(`[^a-z0-9_]+`).ReplaceAllString(value, "_")
	value = strings.Trim(value, "_")
	if value == "" {
		return "user_" + newToken("u")
	}
	if len(value) > 32 {
		return value[:32]
	}
	return value
}

func fallbackString(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return value
}

func newToken(prefix string) string {
	return prefix + "_" + randomSuffix(24)
}

func randomSuffix(length int) string {
	if length <= 0 {
		return ""
	}
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return fmt.Sprintf("%x", time.Now().UTC().UnixNano())[:length]
	}
	encoded := hex.EncodeToString(bytes)
	if len(encoded) > length {
		return encoded[:length]
	}
	return encoded
}
