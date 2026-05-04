# TokTak

TokTak is a modern, full-stack short-video application clone (inspired by TikTok). It features a robust Flutter frontend built with Clean Architecture and BLoC, and a high-performance Go backend powered by PostgreSQL and MinIO for video streaming.

## 🚀 Features

- **Infinite Video Feed**: Smooth, auto-playing video feed with visibility detection.
- **Social Authentication**: Seamless login via Google and LINE SDK.
- **Video Upload**: Direct video uploads to MinIO object storage using presigned URLs.
- **Search**: Discover trending videos and users.
- **User Profile**: View user information and their uploaded videos.
- **Clean Architecture**: Highly modular, testable, and maintainable codebase.

## 🛠 Tech Stack

**Frontend (Flutter)**
- Flutter SDK
- BLoC & Freezed (State Management & Data Classes)
- Dio (Networking)
- Video Player & Cached Network Image
- LINE SDK & Google Sign-In

**Backend (Go)**
- Go (Gin Web Framework)
- PostgreSQL (Database)
- MinIO (S3-compatible Object Storage for Videos)
- Docker & Docker Compose (Infrastructure)

## 📦 Prerequisites

Before running the project, ensure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Go (1.20+)](https://go.dev/doc/install)
- [Docker & Docker Compose](https://docs.docker.com/get-docker/)

## 🏃 Getting Started

### 1. Infrastructure Setup (Database & Storage)
The project uses Docker Compose to run PostgreSQL and MinIO locally.
```bash
docker-compose up -d
```
*Note: Make sure to create the required MinIO buckets as defined in your setup.*

### 2. Backend Setup
Navigate to the backend directory and configure your environment variables.
```bash
cd backend
# Make sure .env is correctly configured at the root directory
go mod download
go run ./cmd/api/main.go
```
*The backend API will run on `http://localhost:8080` (or `10.0.2.2:8080` for Android Emulator).*

### 3. Frontend Setup
Navigate to the project root and install dependencies.
```bash
flutter pub get

# Check emulator
flutter emulators

# Launch emulator
flutter emulators --launch <emulator_id>

# If you make changes to models, run the build runner:
# flutter pub run build_runner build --delete-conflicting-outputs
```

Run the app on your preferred device/emulator:
```bash
flutter run
```
*Note: For Android Emulator, the API base URL is configured to `10.0.2.2`. LINE Login requires the correct Custom URL Scheme (`line3rdp...`) configured in the LINE Developers Console.*

## 📂 Project Structure

```text
.
├── android/            # Android specific code
├── ios/                # iOS specific code
├── backend/            # Go Backend API
│   ├── cmd/            # Entry points
│   └── internal/       # Core backend logic (auth, feed, user, video)
├── lib/                # Flutter Frontend
│   ├── core/           # Shared utilities, constants, theme, network
│   └── features/       # Feature modules (auth, feed, profile, search, upload)
└── docker-compose.yml  # Local infrastructure configuration
```
