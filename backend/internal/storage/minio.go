package storage

import (
	"context"
	"fmt"
	"io"
	"net/url"
	"os"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

const (
	DefaultBucket = "toktak-videos"
	presignTTL    = 15 * time.Minute // presigned upload URL expiry
	publicTTL     = 7 * 24 * time.Hour
)

type MinIOClient struct {
	client         *minio.Client
	bucket         string
	endpoint       string
	publicEndpoint string // external URL clients use (e.g. http://10.0.2.2:9000)
}

func NewMinIOClient() (*MinIOClient, error) {
	endpoint := os.Getenv("MINIO_ENDPOINT")
	if endpoint == "" {
		endpoint = "localhost:9000"
	}
	accessKey := os.Getenv("MINIO_ACCESS_KEY")
	if accessKey == "" {
		accessKey = "minioadmin"
	}
	secretKey := os.Getenv("MINIO_SECRET_KEY")
	if secretKey == "" {
		secretKey = "minioadmin"
	}
	bucket := os.Getenv("MINIO_BUCKET")
	if bucket == "" {
		bucket = DefaultBucket
	}

	client, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: false, // set true for HTTPS in production
	})
	if err != nil {
		return nil, fmt.Errorf("init minio: %w", err)
	}

	publicEndpoint := os.Getenv("MINIO_PUBLIC_ENDPOINT")
	if publicEndpoint == "" {
		publicEndpoint = "http://" + endpoint
	}

	m := &MinIOClient{client: client, bucket: bucket, endpoint: endpoint, publicEndpoint: publicEndpoint}

	// Ensure bucket exists
	if err := m.ensureBucket(context.Background()); err != nil {
		return nil, err
	}

	return m, nil
}

func (m *MinIOClient) ensureBucket(ctx context.Context) error {
	exists, err := m.client.BucketExists(ctx, m.bucket)
	if err != nil {
		return fmt.Errorf("check bucket: %w", err)
	}
	if !exists {
		if err := m.client.MakeBucket(ctx, m.bucket, minio.MakeBucketOptions{}); err != nil {
			return fmt.Errorf("create bucket: %w", err)
		}
	}

	// Set public read policy so video_player can stream without auth headers
	policy := `{
		"Version":"2012-10-17",
		"Statement":[{
			"Effect":"Allow",
			"Principal":{"AWS":["*"]},
			"Action":["s3:GetObject"],
			"Resource":["arn:aws:s3:::` + m.bucket + `/*"]
		}]
	}`
	if err := m.client.SetBucketPolicy(ctx, m.bucket, policy); err != nil {
		return fmt.Errorf("set bucket policy: %w", err)
	}

	return nil
}

// PresignUpload generates a presigned PUT URL for direct file upload.
func (m *MinIOClient) PresignUpload(ctx context.Context, objectName, contentType string) (*url.URL, error) {
	// Use Presign method to ensure better URL generation and potential header inclusion
	u, err := m.client.Presign(ctx, "PUT", m.bucket, objectName, presignTTL, nil)
	if err != nil {
		return nil, err
	}
	return m.rewriteHost(u), nil
}

// PresignDownload generates a presigned GET URL for private object access.
func (m *MinIOClient) PresignDownload(ctx context.Context, objectName string) (*url.URL, error) {
	u, err := m.client.PresignedGetObject(ctx, m.bucket, objectName, publicTTL, nil)
	if err != nil {
		return nil, err
	}
	return m.rewriteHost(u), nil
}

// PublicURL returns the direct public URL using the public-facing endpoint.
func (m *MinIOClient) PublicURL(objectName string) string {
	return m.publicEndpoint + "/" + m.bucket + "/" + objectName
}

// rewriteHost replaces the internal MinIO host with the public-facing endpoint.
// It modifies the URL object in place to ensure all components (Path, Query) are preserved.
func (m *MinIOClient) rewriteHost(u *url.URL) *url.URL {
	pub, err := url.Parse(m.publicEndpoint)
	if err != nil {
		return u
	}
	u.Scheme = pub.Scheme
	u.Host = pub.Host
	return u
}

// Upload streams a file directly from the server (for server-side upload flow).
func (m *MinIOClient) Upload(ctx context.Context, objectName, contentType string, reader io.Reader, size int64) (string, error) {
	_, err := m.client.PutObject(ctx, m.bucket, objectName, reader, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("upload to minio: %w", err)
	}
	return m.PublicURL(objectName), nil
}
