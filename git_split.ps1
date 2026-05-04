$ErrorActionPreference = "Continue"

Write-Host "Starting Git Flow..."

git checkout development

function CommitAndMerge {
    param(
        [string]$BranchName,
        [string[]]$Paths,
        [string]$Message
    )
    Write-Host "Processing branch $BranchName..."
    git checkout -b $BranchName
    foreach ($path in $Paths) {
        if (Test-Path $path) {
            git add $path
        }
    }
    
    # Try to commit, if there are changes
    $status = git status --porcelain
    if ($status) {
        git commit -m $Message
        git checkout development
        git merge $BranchName
        git push origin $BranchName
    } else {
        Write-Host "No changes for $BranchName, skipping."
        git checkout development
        git branch -d $BranchName
    }
}

CommitAndMerge -BranchName "feature/base-setup" -Paths @(".gitignore", "pubspec.yaml", "pubspec.lock", "analysis_options.yaml", ".metadata", ".env.example", "docker-compose.yml") -Message "chore: initial project setup and configs"

CommitAndMerge -BranchName "feature/native-config" -Paths @("android/", "ios/") -Message "build: add android and ios native configuration"

CommitAndMerge -BranchName "feature/backend" -Paths @("backend/") -Message "feat: implement go backend with gin, postgres, and minio"

CommitAndMerge -BranchName "feature/flutter-core" -Paths @("lib/core/", "lib/main.dart", "lib/app.dart", "lib/injection.dart", "assets/", "test/") -Message "feat: flutter core architecture, routing, and DI setup"

CommitAndMerge -BranchName "feature/auth" -Paths @("lib/features/auth/") -Message "feat: social authentication (LINE, Google)"

CommitAndMerge -BranchName "feature/feed" -Paths @("lib/features/feed/") -Message "feat: video feed with auto-play and visibility detection"

CommitAndMerge -BranchName "feature/profile" -Paths @("lib/features/profile/") -Message "feat: user profile and video grid"

CommitAndMerge -BranchName "feature/search" -Paths @("lib/features/search/") -Message "feat: search functionality for videos and users"

CommitAndMerge -BranchName "feature/upload" -Paths @("lib/features/upload/") -Message "feat: video upload to MinIO via presigned URL"

# Catch-all
Write-Host "Processing remaining files..."
git checkout -b feature/misc
git add .
$status = git status --porcelain
if ($status) {
    git commit -m "chore: catch-all remaining files"
    git checkout development
    git merge feature/misc
    git push origin feature/misc
} else {
    git checkout development
    git branch -d feature/misc
}

Write-Host "Pushing development..."
git push -u origin development

Write-Host "Merging to main..."
git checkout -b main origin/main
git merge development
git push origin main

git checkout development
Write-Host "Done!"
