# AuraMusicServer - Implementation Guide for AuraMusic App

This guide explains how to integrate AuraMusicServer with your AuraMusic Kotlin app.

## Overview

AuraMusicServer provides a WebSocket API for real-time synchronized listening sessions. Your app will:
1. Connect to the server via WebSocket
2. Exchange JSON messages for room management & playback control
3. Handle reconnection if connection drops
4. Keep playback synced across all users

## Getting Started

### 1. Update Server URL

In your Kotlin app, replace your Listen Together server URL:

```kotlin
// In your WebSocket client class
private val SERVER_URL = "wss://your-server-url.com/ws"

// For local testing:
// private val SERVER_URL = "ws://localhost:8080/ws"
```

### 2. Initialize WebSocket Connection

```kotlin
import okhttp3.OkHttpClient
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okhttp3.Request
import com.google.gson.Gson

class ListenTogetherClient(private val listener: EventListener) {
    private val client = OkHttpClient()
    private val gson = Gson()
    private var webSocket: WebSocket? = null
    
    interface EventListener {
        fun onRoomCreated(roomCode: String, userId: String, sessionToken: String)
        fun onJoinApproved(state: RoomState)
        fun onUserJoined(userId: String, username: String)
        fun onPlaybackSync(action: PlaybackAction)
        fun onError(code: String, message: String)
    }
    
    fun connect() {
        val request = Request.Builder()
            .url(SERVER_URL)
            .build()
        
        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                // Connected
            }
            
            override fun onMessage(webSocket: WebSocket, text: String) {
                handleMessage(text)
            }
            
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                listener.onError("connection_error", t.message ?: "Unknown error")
            }
        })
    }
    
    private fun handleMessage(json: String) {
        val msg = gson.fromJson(json, ServerMessage::class.java)
        when (msg.type) {
            "room_created" -> {
                val payload = gson.fromJson(msg.payload.toString(), RoomCreatedPayload::class.java)
                listener.onRoomCreated(payload.roomCode, payload.userId, payload.sessionToken)
            }
            "join_approved" -> {
                val payload = gson.fromJson(msg.payload.toString(), JoinApprovedPayload::class.java)
                listener.onJoinApproved(payload.state)
            }
            "sync_playback" -> {
                val payload = gson.fromJson(msg.payload.toString(), PlaybackActionPayload::class.java)
                listener.onPlaybackSync(payload)
            }
            "user_joined" -> {
                val payload = gson.fromJson(msg.payload.toString(), UserJoinedPayload::class.java)
                listener.onUserJoined(payload.userId, payload.username)
            }
            "error" -> {
                val payload = gson.fromJson(msg.payload.toString(), ErrorPayload::class.java)
                listener.onError(payload.code, payload.message)
            }
        }
    }
}

// Data classes for messages
data class ServerMessage(
    val type: String,
    val payload: Any
)

data class RoomCreatedPayload(
    val roomCode: String,
    val userId: String,
    val sessionToken: String
)

data class JoinApprovedPayload(
    val roomCode: String,
    val userId: String,
    val sessionToken: String,
    val state: RoomState
)

data class RoomState(
    val roomCode: String,
    val hostId: String,
    val users: List<UserInfo>,
    val currentTrack: TrackInfo?,
    val isPlaying: Boolean,
    val position: Long,
    val lastUpdate: Long,
    val volume: Float,
    val queue: List<TrackInfo>
)

data class UserInfo(
    val userId: String,
    val username: String,
    val isHost: Boolean,
    val isConnected: Boolean
)

data class TrackInfo(
    val id: String,
    val title: String,
    val artist: String,
    val album: String?,
    val duration: Long,
    val thumbnail: String?
)

data class PlaybackActionPayload(
    val action: String,  // "play", "pause", "seek", "change_track", etc.
    val trackId: String?,
    val position: Long,
    val trackInfo: TrackInfo?,
    val volume: Float
)

data class UserJoinedPayload(
    val userId: String,
    val username: String
)

data class ErrorPayload(
    val code: String,
    val message: String
)
```

## Key Functions

### Creating a Room (Host)

```kotlin
fun createRoom(username: String) {
    val payload = mapOf(
        "username" to username
    )
    sendMessage("create_room", payload)
}

private fun sendMessage(type: String, payload: Any) {
    val message = mapOf(
        "type" to type,
        "payload" to payload
    )
    val json = gson.toJson(message)
    webSocket?.send(json)
}
```

Response: `RoomCreatedPayload`
- Save `roomCode` for sharing
- Save `sessionToken` for reconnection

### Joining a Room (Guest)

```kotlin
fun joinRoom(roomCode: String, username: String) {
    val payload = mapOf(
        "room_code" to roomCode,
        "username" to username
    )
    sendMessage("join_room", payload)
}
```

Response: `JoinRequestPayload` sent to host

Host must approve:
```kotlin
fun approveJoinRequest(userId: String) {
    val payload = mapOf(
        "user_id" to userId
    )
    sendMessage("approve_join", payload)
}
```

Guest receives: `JoinApprovedPayload`

### Playback Control (Host Only)

**Change Track:**
```kotlin
fun changeTrack(track: TrackInfo) {
    val payload = mapOf(
        "action" to "change_track",
        "track_info" to track
    )
    sendMessage("playback_action", payload)
}
```

**Play:**
```kotlin
fun play(position: Long = 0) {
    val payload = mapOf(
        "action" to "play",
        "position" to position
    )
    sendMessage("playback_action", payload)
}
```

**Pause:**
```kotlin
fun pause(position: Long) {
    val payload = mapOf(
        "action" to "pause",
        "position" to position
    )
    sendMessage("playback_action", payload)
}
```

**Seek:**
```kotlin
fun seek(position: Long) {
    val payload = mapOf(
        "action" to "seek",
        "position" to position
    )
    sendMessage("playback_action", payload)
}
```

**Add to Queue:**
```kotlin
fun addToQueue(track: TrackInfo, insertNext: Boolean = false) {
    val payload = mapOf(
        "action" to "queue_add",
        "track_info" to track,
        "insert_next" to insertNext
    )
    sendMessage("playback_action", payload)
}
```

### Guest Features

**Suggest a Track:**
```kotlin
fun suggestTrack(track: TrackInfo) {
    val payload = mapOf(
        "track_info" to track
    )
    sendMessage("suggest_track", payload)
}
```

**Request Sync (Get current state):**
```kotlin
fun requestSync() {
    sendMessage("request_sync", emptyMap<String, Any>())
}
```

### Handling Disconnection & Reconnection

```kotlin
fun disconnect() {
    webSocket?.close(1000, "User disconnected")
}

fun reconnect(sessionToken: String) {
    // First, re-establish WebSocket connection
    connect()
    
    // Then send reconnect message
    val payload = mapOf(
        "session_token" to sessionToken
    )
    sendMessage("reconnect", payload)
}
```

Response: `ReconnectedPayload` with updated room state

## Best Practices

### 1. Keep Playback Synced

Guest should periodically request sync:
```kotlin
// Every 5-10 seconds
viewModelScope.launch(Dispatchers.IO) {
    while (isActive) {
        delay(5000)
        client.requestSync()
    }
}
```

### 2. Handle Message Queue

```kotlin
class MessageQueue {
    private val queue = mutableListOf<Pair<String, Any>>()
    private var isConnected = false
    
    fun sendMessage(type: String, payload: Any) {
        if (isConnected) {
            // Send immediately
            doSend(type, payload)
        } else {
            // Queue for later
            queue.add(type to payload)
        }
    }
    
    fun onConnected() {
        isConnected = true
        // Flush queue
        while (queue.isNotEmpty()) {
            val (type, payload) = queue.removeAt(0)
            doSend(type, payload)
        }
    }
}
```

### 3. Handle Errors Gracefully

```kotlin
private fun handleError(code: String, message: String) {
    when (code) {
        "room_not_found" -> {
            // Show "Room expired" UI
            showError("Room has ended")
        }
        "not_host" -> {
            // Guest tried host-only action
            showError("Only host can do this")
        }
        "session_expired" -> {
            // Session token expired (>15 min)
            showError("Connection expired, create new room")
        }
        else -> showError(message)
    }
}
```

### 4. Save Session Token

```kotlin
// In shared preferences
fun saveSession(roomCode: String, sessionToken: String) {
    val prefs = context.getSharedPreferences("listen_together", Context.MODE_PRIVATE)
    prefs.edit().apply {
        putString("room_code", roomCode)
        putString("session_token", sessionToken)
        apply()
    }
}

fun getSavedSession(): Pair<String, String>? {
    val prefs = context.getSharedPreferences("listen_together", Context.MODE_PRIVATE)
    val roomCode = prefs.getString("room_code", null) ?: return null
    val token = prefs.getString("session_token", null) ?: return null
    return roomCode to token
}
```

## Testing

### Local Testing

1. Start server:
```bash
cd AuraMusicServer
docker-compose up -d
```

2. Update app to use `ws://localhost:8080/ws`

3. Test flows:
   - Create room
   - Share room code
   - Join from another device
   - Test playback sync
   - Test disconnect/reconnect

### Production Testing

1. Deploy to Railway/Render
2. Update server URL in app
3. Test with friends
4. Check logs for errors

## Common Issues

### Connection Fails
**Problem:** WebSocket connection refused
**Solution:**
- Verify server is running
- Check firewall allows port
- Ensure using `wss://` for HTTPS

### Out of Sync
**Problem:** Guest's playback doesn't match host
**Solution:**
- Guest should call `requestSync()` regularly
- Add delay compensation: `position + (now - lastUpdate)`
- Check network latency

### Session Expired
**Problem:** Reconnect fails after 15 minutes
**Solution:**
- Sessions expire after 15 minutes idle
- Reconnect within 15 minutes or create new room
- Show warning at 14 minutes

## Debugging

Enable debug logging:

```kotlin
// Add to WebSocketListener
override fun onMessage(webSocket: WebSocket, text: String) {
    Log.d("ListenTogether", "Received: $text")
    handleMessage(text)
}

private fun sendMessage(type: String, payload: Any) {
    val message = mapOf(
        "type" to type,
        "payload" to payload
    )
    val json = gson.toJson(message)
    Log.d("ListenTogether", "Sending: $json")
    webSocket?.send(json)
}
```

Check server logs:
```bash
docker logs -f auramusic-server
```

## API Reference

See `README.md` for complete message reference.

---

**Your AuraMusic app is now ready to sync with friends!** 🎵
