# RecipeJoe Android - Claude Code Builder

This setup runs Claude Code in an isolated Docker container to add a native Android app to your RecipeJoe iOS project.

## Why Docker?

- **Security**: Claude runs in an isolated container, can't affect your system
- **Android SDK**: Container includes Android SDK, Gradle, and all build tools
- **Persistence**: Your login and work are saved between sessions
- **Easy cleanup**: Just `docker-compose down` to stop everything

## Prerequisites

- Docker & Docker Compose
- Claude Max subscription (for login)

## Quick Start

```bash
# Navigate to this folder
cd recipejoe-android-setup

# Make start script executable
chmod +x start.sh

# Start (builds container, prompts for login)
./start.sh
```

## Step-by-Step

### 1. Build and Start Container

```bash
cd recipejoe-android-setup
docker-compose build
docker-compose up -d
```

### 2. Login to Claude (First Time Only)

```bash
docker exec -it recipejoe-claude claude login
```

This shows a URL and code. Open the URL in your browser and enter the code to authorize with your Max subscription. Your login is saved for future sessions.

### 3. Start Working

```bash
# Enter the container
docker exec -it recipejoe-claude bash

# Navigate to project
cd /workspace/RecipeJoe

# Start Claude
claude
```

Then paste the task from `/workspace/android-task.md` or describe what you want to build.

## Using the Task File

The `android-task.md` file contains instructions for building the Android app. You can:

```bash
# View the task
cat /workspace/android-task.md

# Or copy-paste it into Claude
```

## Monitoring

```bash
# Enter container
docker exec -it recipejoe-claude bash

# View git commits (from your Mac)
watch -n 5 'git log --oneline -10'

# Stop container
docker-compose down

# Remove container and start fresh
docker-compose down -v
docker-compose up -d
```

## Project Structure After Build

```
RecipeJoe/
├── RecipeJoe/              # iOS app (existing)
├── android/                # Android app (NEW)
│   ├── app/
│   │   └── src/main/java/com/recipejoe/
│   ├── build.gradle.kts
│   └── gradlew
├── docs/
│   └── android/            # Setup guides (NEW)
│       ├── GOOGLE_SIGNIN_SETUP.md
│       ├── BILLING_SETUP.md
│       └── FCM_SETUP.md
├── supabase/               # Backend (shared)
└── CLAUDE.md               # Updated with Android section
```

## Manual Steps After Build

Claude will create documentation for these manual steps:

**1. Google Sign-In Setup**
- Google Cloud Console: Create OAuth credentials
- Firebase project setup
- SHA-1 fingerprint configuration
- See: `docs/android/GOOGLE_SIGNIN_SETUP.md`

**2. Google Play Billing**
- Play Console: Create products matching iOS
- Configure subscriptions
- See: `docs/android/BILLING_SETUP.md`

**3. Firebase Cloud Messaging**
- Enable FCM
- Configure server key in backend
- See: `docs/android/FCM_SETUP.md`

## Security

**Claude CAN (inside container):**
- Read/write everything in RecipeJoe project
- Use Android SDK, Gradle, npm, Git
- Fetch developer documentation

**Claude CANNOT:**
- Access files outside the project
- Modify your system
- Read SSH keys or credentials
- Run `sudo`

Container runs as non-root `claude` user.

## Troubleshooting

### Container won't start
```bash
docker-compose logs
docker-compose build --no-cache
```

### Need to re-login
```bash
docker exec -it recipejoe-claude claude login
```

### Start fresh (removes login)
```bash
docker-compose down -v
docker-compose up -d
```

## After the Build

```bash
# Review changes (from your Mac)
git log --oneline -20

# Test Android build (inside container)
cd /workspace/RecipeJoe/android && ./gradlew build

# Run tests
cd /workspace/RecipeJoe/android && ./gradlew test
```

## Tips

1. **Interactive mode**: Work with Claude step by step for better control
2. **Monitor commits**: Everything is in Git, easy to revert
3. **Iterate**: First session creates foundation, then improve incrementally
4. **Your login persists**: You only need to login once, it's saved in Docker volume
