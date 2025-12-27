# RecipeJoe Android - Autonomous Build Setup

Dieses Setup erlaubt Claude Code, deine RecipeJoe iOS App **vollständig autonom** um eine native Android App zu erweitern.

## 🎯 Was passiert hier?

Claude Code läuft in einem isolierten Docker Container und:
- ✅ Liest dein **bestehendes CLAUDE.md**
- ✅ Erweitert das CLAUDE.md mit Android-Infos  
- ✅ Fügt Android App zum Projekt hinzu
- ✅ Nutzt dein **bestehendes Supabase Backend**
- ✅ Kann Subagents spawnen für parallele Arbeit
- ✅ Installiert alle Dependencies selbstständig
- ✅ Committed seine Arbeit zu Git
- ✅ Erstellt Dokumentation für manuelle Setup-Schritte
- ✅ **Hat volle Rechte** auf dein Projekt (alles in Git!)

## 📋 Voraussetzungen

- Docker & Docker Compose
- Anthropic API Key (Claude Code)
- Dein RecipeJoe Projekt

## 🚀 Quick Start

### 1. Setup

```bash
# In diesem Ordner
cd /pfad/zu/diesem/setup

# API Key setzen
export ANTHROPIC_API_KEY='sk-ant-...'

# Start Script ausführbar machen
chmod +x start.sh

# Start!
./start.sh
```

Das Script wird dich durch den Setup führen.

### 2. Optionen

#### 🤖 Option A: Voll Autonom (YOLO Mode)

```bash
docker exec -it recipejoe-claude bash -c 'cd /workspace/recipejoe && claude --dangerously-skip-permissions --max-turns 200 "$(cat /workspace/android-task.md)" 2>&1 | tee android-build.log'
```

- Läuft komplett ohne Inputs
- ~200 turns ($50-150)
- Log: `recipejoe/android-build.log`

#### 🤝 Option B: Semi-Autonom

```bash
docker exec -it recipejoe-claude bash
cd /workspace/recipejoe
claude
# Shift+Tab drücken → "auto-accept edit on"
# Dann: cat /workspace/android-task.md (Task anzeigen)
```

#### 🎮 Option C: Interaktiv

```bash
docker exec -it recipejoe-claude bash
cd /workspace/recipejoe
claude
# Du kontrollierst alles
```

## 📊 Monitoring

```bash
# Container logs
docker-compose logs -f

# Build log (autonomous mode)
tail -f recipejoe/android-build.log

# Git commits verfolgen
watch -n 5 'cd recipejoe && git log --oneline -10'

# Container betreten
docker exec -it recipejoe-claude bash

# Stoppen
docker-compose down
```

## 🏗️ Was Claude macht

### 1. Analyse
- Liest CLAUDE.md
- Checkt iOS App Struktur  
- Versteht Supabase Backend
- Identifiziert Features

### 2. CLAUDE.md erweitern
Fügt Android-Sektion hinzu mit:
- Development Philosophy (iOS-first!)
- Tech Stack (Kotlin, Compose, etc.)
- Platform Adaptations (Google Sign-In, Billing, FCM)
- Manual Setup Steps

### 3. Projekt Struktur

Claude wird wahrscheinlich so strukturieren:
```
RecipeJoe/
├── ios/                    # Deine iOS App
├── android/                # Neue Android App (von Claude)
│   ├── app/
│   │   └── src/main/java/com/recipejoe/
│   ├── build.gradle.kts
│   └── gradle.properties
├── docs/
│   └── android/           # Setup Guides
│       ├── GOOGLE_SIGNIN_SETUP.md
│       ├── BILLING_SETUP.md
│       └── FCM_SETUP.md
├── CLAUDE.md              # Updated!
└── README.md
```

**Oder**: Claude strukturiert um wenn es Sinn macht!

### 4. Features implementieren

- ✅ AI Recipe Import (YouTube, TikTok, Web, OCR)
- ✅ Recipe CRUD
- ✅ Google Sign-In (statt Apple)
- ✅ Google Play Billing (statt StoreKit)
- ✅ FCM (statt APNs)
- ✅ Supabase Integration (gleiche Tables!)

### 5. Documentation

Claude erstellt diese Docs für manuelle Steps:
- `docs/android/GOOGLE_SIGNIN_SETUP.md`
- `docs/android/BILLING_SETUP.md`
- `docs/android/FCM_SETUP.md`

## 🔒 Sicherheit

### Was Claude KANN:
- ✅ Alles in deinem RecipeJoe Projekt lesen/schreiben
- ✅ Android SDK, Gradle, npm, Git nutzen
- ✅ Subagents spawnen
- ✅ Developer Docs fetchen

### Was Claude NICHT KANN:
- ❌ System Files ändern
- ❌ SSH Keys lesen
- ❌ `rm -rf /` oder ähnliches
- ❌ Sudo

**Container läuft als `claude` user (non-root)**

## 💰 Kosten

**Autonomous Mode (200 turns)**:
- Conservative: ~$50
- Average: ~$100
- Worst case: ~$150

**Test mit `--max-turns 50` zuerst!**

## 🛠️ Troubleshooting

### Container startet nicht
```bash
docker-compose logs
docker-compose build --no-cache
```

### Claude hängt
```bash
docker-compose restart
```

### Zu viele Kosten
```bash
docker-compose down
# Editiere claude-settings.json: "maxTurns": 50
```

## 🎓 Nach dem Build

### Manuelle Steps

Claude wird dir genau erklären was du machen musst:

**1. Google Sign-In Setup**
- Google Cloud Console → OAuth
- Firebase Projekt
- SHA-1 Fingerprint
- Details in `docs/android/GOOGLE_SIGNIN_SETUP.md`

**2. Google Play Billing**
- Play Console → Produkte anlegen  
- Subscriptions konfigurieren
- Details in `docs/android/BILLING_SETUP.md`

**3. Firebase Cloud Messaging**
- FCM aktivieren
- Server Key ins Backend
- Details in `docs/android/FCM_SETUP.md`

### Testing

```bash
cd recipejoe/android
./gradlew build
./gradlew test
```

### Deployment

Claude wird eine README im android/ Ordner erstellen mit Deployment-Infos.

## 🚀 Next Steps nach dem Build

1. **Review Code**: `cd recipejoe && git log`
2. **Lies Docs**: Check `docs/android/`
3. **Test Build**: `cd android && ./gradlew build`
4. **Setup Google**: Follow die Setup Guides
5. **Iterate**: Starte Claude nochmal für Fixes

## 📚 Ressourcen

- [Claude Code Docs](https://code.claude.com/docs)
- [Android Development](https://developer.android.com)
- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Supabase Kotlin](https://github.com/supabase-community/supabase-kt)

## 💡 Pro-Tipps

1. **Start small**: Teste erstmal mit `--max-turns 50`
2. **Watch commits**: `watch -n 5 'git log --oneline -10'`
3. **Monitor logs**: Öffne `tail -f android-build.log` in separatem Terminal
4. **Checkpoint**: Claude macht auto-commits - easy zu reverten!
5. **Iterate**: Erster Run liefert Basis, dann iterativ verbessern

## 🤔 FAQ

**Q: Kann Claude meine iOS App kaputt machen?**  
A: Nein! Alles ist in Git. Einfach `git reset --hard` wenn was schief geht.

**Q: Nutzt Claude mein bestehendes Backend?**  
A: Ja! Claude wird Supabase-Client nutzen mit deinen existierenden Tables.

**Q: Kann ich die Projekt-Struktur selbst bestimmen?**  
A: Ja! Editiere `android-task.md` und gib Claude Vorgaben.

**Q: Was wenn Claude sich verheddert?**  
A: `docker-compose down`, dann `docker exec -it recipejoe-claude bash` und interaktiv debuggen.

**Q: Wie kann ich Claude eine bessere Architektur beibringen?**  
A: Ergänze Details in `android-task.md` vor dem Start!

Viel Erfolg! 🎉
