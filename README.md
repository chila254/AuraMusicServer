# AuraMusicServer

High-performance WebSocket server for AuraMusic's synchronized group listening feature.

## Quick Start

### Local Testing
```bash
docker-compose up -d
```
Server runs on `ws://localhost:8080/ws`

### Deploy to Cloud
See **DEPLOYMENT.md** for step-by-step guides for Railway, Render, DigitalOcean, etc.

## API Overview

All messages are JSON:
```json
{
  "type": "message_type",
  "payload": { /* data */ }
}
```

### Key Messages

**Create Room (Host):**
```json
{"type": "create_room", "payload": {"username": "Alice"}}
```

**Join Room (Guest):**
```json
{"type": "join_room", "payload": {"room_code": "ABC123XY", "username": "Bob"}}
```

**Approve Join (Host):**
```json
{"type": "approve_join", "payload": {"user_id": "user_456"}}
```

**Playback Control (Host):**
```json
{"type": "playback_action", "payload": {"action": "play", "position": 0}}
```

Actions: `play`, `pause`, `seek`, `change_track`, `skip_next`, `skip_prev`, `queue_add`, `queue_remove`, `queue_clear`

**Suggest Track (Guest):**
```json
{"type": "suggest_track", "payload": {"track_info": {"id": "123", "title": "Song", "artist": "Artist", "duration": 180000}}}
```

**Approve Suggestion (Host):**
```json
{"type": "approve_suggestion", "payload": {"suggestion_id": "sug_123"}}
```

**Request Sync (Any):**
```json
{"type": "request_sync"}
```

**Leave Room:**
```json
{"type": "leave_room"}
```

## Features

- ✅ Real-time synchronized playback
- ✅ Room management with approval-based joining
- ✅ Host playback control
- ✅ Song suggestions from guests
- ✅ Queue management
- ✅ 15-minute reconnection window
- ✅ Health check endpoint: `/health`

## Environment Variables

- `PORT` - Server port (default: 8080)

## Architecture

- **Framework:** Gorilla WebSocket
- **Language:** Go 1.21
- **Logging:** Uber Zap
- **Container:** Alpine Linux (10MB image)

## File Structure

```
.
├── main.go              # Core server logic
├── go.mod / go.sum      # Dependencies
├── Dockerfile           # Multi-stage build
├── docker-compose.yml   # Local setup
├── README.md            # This file
├── QUICKSTART.md        # 5-min setup
├── DEPLOYMENT.md        # Cloud deployment
└── IMPLEMENTATION.md    # Android integration
```

## Common Message Flows

### Creating & Joining a Room
1. Host: `create_room` → receives `room_created` with room code
2. Guest: `join_room` with code → Host receives `join_request`
3. Host: `approve_join` → Guest receives `join_approved` with room state
4. All: Receive `user_joined` notification

### Playing Music
1. Host: `playback_action` with `change_track` → All receive `sync_playback`
2. Host: `playback_action` with `play` → All receive `sync_playback`
3. Guest: `request_sync` → receives current `sync_state`

### Song Suggestions
1. Guest: `suggest_track` → Host receives `suggestion_received`
2. Host: `approve_suggestion` → Queue updates, guest receives `suggestion_approved`
3. Or Host: `reject_suggestion` → Guest receives `suggestion_rejected`

## Errors

Server sends error messages:
```json
{"type": "error", "payload": {"code": "error_code", "message": "description"}}
```

Common codes:
- `room_not_found` - Room doesn't exist
- `not_host` - Only host can do this action
- `not_in_room` - User not in a room
- `session_expired` - Reconnect window passed (>15 min)
- `invalid_payload` - Malformed message

## Monitoring

Check server health:
```bash
curl http://your-server:8080/health
```

View logs:
```bash
docker logs -f auramusic-server
```

## Reconnection

If connection drops, save the session token from room creation:
```json
{"type": "reconnect", "payload": {"session_token": "token_xyz"}}
```

Valid for 15 minutes. After that, must create/join new room.

## For Android Integration

See **IMPLEMENTATION.md** for Kotlin code examples.

Update your app's server URL:
```kotlin
private val SERVER_URL = "wss://your-server-url.com/ws"
```

## Deployment

**Railway (Recommended - 2 min setup):**
1. Push to GitHub
2. Connect repo to railway.app
3. Deploy
4. Get public URL

See **DEPLOYMENT.md** for detailed guides.

## License

GPL-3.0

---

**Next Steps:**
- Local testing: `docker-compose up -d`
- Deploy: See DEPLOYMENT.md
- Integrate: See IMPLEMENTATION.md
- Questions: Check logs with `docker logs auramusic-server`
