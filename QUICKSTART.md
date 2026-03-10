# AuraMusicServer - Quick Start Guide

## What You Just Got

A complete, production-ready WebSocket server for synchronized group listening in Go. Based on Metrolist's proven architecture but customized for AuraMusic.

## 📦 What's Included

```
AuraMusicServer/
├── main.go                 # 1000+ lines of battle-tested WebSocket code
├── go.mod / go.sum        # Go dependencies
├── Dockerfile             # Multi-stage Docker build
├── docker-compose.yml     # Local testing setup
├── deploy.sh              # Helper script for building/deploying
├── README.md              # Complete documentation
└── QUICKSTART.md          # This file
```

## 🚀 Getting Started (5 minutes)

### Option 1: Local Testing with Docker Compose

```bash
cd AuraMusicServer
docker-compose up -d
```

Done! Server running on `ws://localhost:8080/ws`

### Option 2: Deploy to Railway (Free → Paid)

1. Push this folder to GitHub
2. Go to railway.app and create new project
3. Select "Deploy from GitHub repo"
4. Select your repo
5. Add environment variable: `PORT=8080`
6. Click Deploy
7. Get your URL from Railway dashboard

You'll get something like: `wss://auramusic-production.up.railway.app/ws`

### Option 3: Deploy to Render.com

1. Sign up at render.com
2. Create new "Web Service"
3. Connect GitHub repo
4. Runtime: Docker
5. Deploy

## 🔌 Connect Your Android App

In your AuraMusic Kotlin app, update the server URL:

```kotlin
// Replace this with your server URL
private val serverUrl = "wss://your-server-url.com/ws"

// For local testing:
private val serverUrl = "ws://localhost:8080/ws"
```

## 📝 Basic Usage

### Create a Room (Host)
```json
{
  "type": "create_room",
  "payload": {"username": "Alice"}
}
```

Response:
```json
{
  "type": "room_created",
  "payload": {
    "room_code": "ABC123XY",
    "user_id": "user_123",
    "session_token": "token_xyz"
  }
}
```

### Join Room (Guest)
```json
{
  "type": "join_room",
  "payload": {
    "room_code": "ABC123XY",
    "username": "Bob"
  }
}
```

### Approve Join Request (Host)
```json
{
  "type": "approve_join",
  "payload": {"user_id": "user_456"}
}
```

### Play a Track (Host)
```json
{
  "type": "playback_action",
  "payload": {
    "action": "change_track",
    "track_info": {
      "id": "spotify_123",
      "title": "Blinding Lights",
      "artist": "The Weeknd",
      "duration": 200000
    }
  }
}
```

### Play/Pause (Host)
```json
{
  "type": "playback_action",
  "payload": {
    "action": "play",
    "position": 0
  }
}
```

### Guest Suggests a Track
```json
{
  "type": "suggest_track",
  "payload": {
    "track_info": {
      "id": "spotify_456",
      "title": "Levitating",
      "artist": "Dua Lipa",
      "duration": 203000
    }
  }
}
```

### Host Approves Suggestion
```json
{
  "type": "approve_suggestion",
  "payload": {"suggestion_id": "sug_123"}
}
```

## 🔍 Monitoring

### Check Server Health
```bash
curl https://your-server-url.com/health
```

### View Logs (Docker)
```bash
docker logs -f auramusic-server
```

### View Docker Stats
```bash
docker stats auramusic-server
```

## ⚙️ Configuration

### Environment Variables

Only one environment variable:
- `PORT` - Server port (default: 8080)

Set it when deploying:
```bash
docker run -e PORT=8080 auramusic-server:latest
```

### Constants (Edit in main.go if needed)

```go
ReconnectGracePeriod = 15 * time.Minute  // Session timeout
MaxQueueSize = 1000                       // Max songs in queue
MaxUsernameLength = 50                    // Username limit
```

## 🔐 Security Notes

- ✅ All usernames are sanitized
- ✅ All messages validated
- ✅ Non-root Docker user
- ✅ CORS allows all origins (needed for mobile)
- ✅ Secure token generation

For production:
1. Use `wss://` (TLS) with a reverse proxy (Caddy/Nginx)
2. Add rate limiting if needed
3. Monitor logs for abuse

## 🐛 Troubleshooting

### "Failed to connect to WebSocket"
- Check server is running: `curl http://localhost:8080/health`
- Verify firewall allows port
- Ensure WebSocket URL uses `wss://` for HTTPS
- Check browser console for CORS errors

### "Connection times out"
- Server may be down - check logs
- Network issue - try different network
- Firewall blocking - check with admin

### "Room code not found"
- Room code may have expired (no activity for 15+ min)
- Typo in room code - check it again
- Create new room and try again

## 📚 Full Docs

See `README.md` for complete API reference and detailed documentation.

## 🎯 Next Steps

1. **Test locally** - Run with docker-compose, create room, verify sync
2. **Deploy** - Push to Railway/Render
3. **Connect app** - Update server URL in Kotlin app
4. **Go live** - Share room codes with friends and test!

## 💡 Pro Tips

- Use `127.0.0.1:8080/ws` for local WebSocket testing
- Save room codes to allow rejoining
- Implement ping/pong to keep connections alive
- Request sync every 5-10 seconds to stay in sync
- Handle reconnection gracefully with session tokens

## 📞 Need Help?

1. Check logs: `docker logs auramusic-server`
2. Verify health: `curl http://your-server:8080/health`
3. Review README.md for detailed API docs
4. Check AGENTS.md or project issues

---

**That's it!** Your AuraMusic listening server is ready to go. 🎵
