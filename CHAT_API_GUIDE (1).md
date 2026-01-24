# Chat WebSocket API Documentation

## Overview

The chat system provides real-time private messaging between users using WebSocket connections. Users can send text, images, audio, and video messages.

### Key Features
- Real-time bi-directional communication via WebSockets
- Private one-on-one conversations
- Support for text, image, audio, and video messages and replies
- Message read receipts
- Typing indicators
- Message history with pagination
- Secure, authenticated connections

---

## Architecture

### Technology Stack
- **WebSockets**: Django Channels with Redis backend
- **Authentication**: Knox token-based authentication
- **Message Broker**: Redis for channel layer
- **Database**: PostgreSQL for message persistence

---

## HTTP API Endpoints

### Base URL
All chat HTTP endpoints are prefixed with `/api/v1/chat/`.

### 1. Create Conversation

Create a new private conversation between two users.

- **Endpoint:** `/api/v1/chat/conversations/`
- **Method:** `POST`
- **Authentication:** Required (Bearer Token)

#### Request Body
```json
{
  "participant_ids": ["user_123", "user_456"]
}
```

#### Success Response (201 Created)
```json
{
  "success": true,
  "message": "Conversation created successfully.",
  "data": {
    "id": "conv_abc123",
    "conversation_type": "private",
    "participant_ids": ["user_123", "user_456"],
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z",
    "last_message_at": null
  },
  "status_code": 201
}
```

**Note:** If a conversation already exists between these users, the existing conversation is returned.

---

### 2. Get Conversations List

Fetch all conversations for the authenticated user with pagination.

- **Endpoint:** `/api/v1/chat/conversations/{page}/{page_size}/`
- **Method:** `GET`
- **Authentication:** Required

#### URL Parameters
- `page`: integer (starts from 1)
- `page_size`: integer (1-50)

#### Example Request
```http
GET /api/v1/chat/conversations/1/20/
Authorization: Bearer 
```

#### Success Response (200 OK)
```json
{
  "success": true,
  "message": "Conversations fetched successfully.",
  "data": {
    "conversations": [
      {
        "id": "conv_abc123",
        "conversation_type": "private",
        "participant_ids": ["user_123", "user_456"],
        "created_at": "2025-01-15T10:30:00Z",
        "updated_at": "2025-01-15T10:35:00Z",
        "last_message_at": "2025-01-15T10:35:00Z",
        "last_message": {
          "id": "msg_xyz789",
          "message_type": "text",
          "text_content": "Hello!",
          "is_reply": false,
          "previous_message_id": null,
          "previous_message_content": null,
          "previous_message_sender_id": null,
          "created_at": "2025-01-15T10:35:00Z"
        },
        "unread_count": 3
      }
    ],
    "previous_link": null,
    "next_link": "/api/v1/chat/conversations/2/20/"
  },
  "status_code": 200
}
```

---

### 3. Send Message

Send a message in a conversation (also broadcasts via WebSocket).

- **Endpoint:** `/api/v1/chat/conversations/{conversation_id}/messages/`
- **Method:** `POST`
- **Authentication:** Required

#### Request Body

**Text Message:**
```json
{
  "message_type": "text",
  "text_content": "Hello, how are you?",
  "is_reply": false,
}
```

**Media Message:**
```json
{
  "message_type": "image",
  "media_url": "https://example.com/media/image.jpg"
}
```

#### Success Response (201 Created)
```json
{
  "success": true,
  "message": "Message sent successfully.",
  "data": {
    "id": "msg_xyz789",
    "conversation_id": "conv_abc123",
    "sender_id": "user_123",
    "message_type": "text",
    "text_content": "Hello, how are you?",
    "media_url": null,
    "is_reply": false,
    "previous_message_id": null,
    "previous_message_content": null,
    "previous_message_sender_id": null,
    "status": "sent",
    "created_at": "2025-01-15T10:35:00Z",
    "updated_at": "2025-01-15T10:35:00Z",
    "read_at": null
  },
  "status_code": 201
}
```

---

### 4. Get Conversation Messages

Fetch message history for a conversation with pagination.

- **Endpoint:** `/api/v1/chat/conversations/{conversation_id}/messages/{page}/{page_size}/`
- **Method:** `GET`
- **Authentication:** Required

#### URL Parameters
- `conversation_id`: string
- `page`: integer
- `page_size`: integer (1-100)

#### Example Request
```http
GET /api/v1/chat/conversations/conv_abc123/messages/1/50/
Authorization: Bearer 
```

#### Success Response (200 OK)
```json
{
  "success": true,
  "message": "Messages fetched successfully.",
  "data": {
    "messages": [
      {
        "id": "msg_xyz789",
        "conversation_id": "conv_abc123",
        "sender_id": "user_123",
        "message_type": "text",
        "text_content": "Hello!",
        "media_url": null,
        "is_reply": false,
        "previous_message_id": null,
        "previous_message_content": null,
        "previous_message_sender_id": null,
        "status": "read",
        "created_at": "2025-01-15T10:35:00Z",
        "updated_at": "2025-01-15T10:36:00Z",
        "read_at": "2025-01-15T10:36:00Z"
      }
    ],
    "previous_link": null,
    "next_link": null,
    "total_count": 1
  },
  "status_code": 200
}
```

---

### 5. Mark Messages as Read

Mark messages in a conversation as read.

- **Endpoint:** `/api/v1/chat/conversations/{conversation_id}/mark-read/`
- **Method:** `POST`
- **Authentication:** Required

#### Request Body

**Mark specific messages:**
```json
{
  "message_ids": ["msg_xyz789", "msg_abc456"]
}
```

**Mark all messages:**
```json
{
  "message_ids": []
}
```

#### Success Response (200 OK)
```json
{
  "success": true,
  "message": "Messages marked as read successfully.",
  "data": {},
  "status_code": 200
}
```

---

### 6. Upload Media

Upload media files (image, audio, video) for chat messages.

- **Endpoint:** `/api/v1/chat/media/upload/`
- **Method:** `POST`
- **Authentication:** Required
- **Content-Type:** `multipart/form-data`

#### Request Body (Form Data)
- `file`: File (required)
- `message_type`: string (required) - one of: "image", "audio", "video"

#### File Limits
- Max size: 50MB
- **Images**: JPEG, PNG, GIF, WebP
- **Audio**: MP3, WAV, OGG, AAC
- **Video**: MP4, WebM, QuickTime

#### Example Request
```bash
curl -X POST http://localhost:8000/api/v1/chat/media/upload/ \
  -H "Authorization: Bearer " \
  -F "file=@/path/to/image.jpg" \
  -F "message_type=image"
```

#### Success Response (201 Created)
```json
{
  "success": true,
  "message": "Media uploaded successfully.",
  "data": {
    "media_url": "https://example.com/media/image.jpg",
    "message_type": "image"
  },
  "status_code": 201
}
```

### 7. WebSocket Endpoint

```bash
ws://localhost:8000/ws/chat/{conversation_id}/

# Replace 'ws' with 'wss' in production.
# To authenticate, send the auth token in headers or as a query(e.g. ?token=<auth_token>)
```

---

## Message Types

### Send via WebSocket

```json
// Typing indicator
{"type": "typing", "is_typing": true}

// Read receipt
{"type": "read", "message_ids": ["msg_123"]}

// Ping (heartbeat)
{"type": "ping"}
```

### Receive via WebSocket

```json
// New message
{
  "type": "chat_message",
  "message_content_type": "text",
  "id": "msg_123",
  "conversation_id": "conv_abc123",
  "sender_id": "user_456",
  "message_type": "text",
  "text_content": "Hello!",
  "media_url": null,
  "is_reply": false,
  "previous_message_id": null,
  "previous_message_content": null,
  "previous_message_sender_id": null,
  "status": "read",
  "created_at": "2025-01-15T10:35:00Z",
  "updated_at": "2025-01-15T10:36:00Z",
  "read_at": "2025-01-15T10:36:00Z"
}

// Typing indicator
{
  "type": "typing_indicator",
  "user_id": "user_456",
  "username": "john",
  "is_typing": true
}

// Read receipt
{
  "type": "read_receipt",
  "user_id": "user_456",
  "message_ids": ["msg_123"]
}
```

---

## Example flow

### Create a Conversation
```bash
curl -X POST http://localhost:8000/api/v1/chat/conversations/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"participant_ids": ["user1_id", "user2_id"]}'
```

### Send a Text Message
```bash
curl -X POST http://localhost:8000/api/v1/chat/conversations/conv_123/messages/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message_type": "text",
    "text_content": "Hello!"
  }'
```

### Upload and Send Media
```bash
# 1. Upload file
curl -X POST http://localhost:8000/api/v1/chat/media/upload/ \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@image.jpg" \
  -F "message_type=image"

# 2. Send message with media_url
curl -X POST http://localhost:8000/api/v1/chat/conversations/conv_123/messages/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message_type": "image",
    "media_url": "https://example.com/media/image.jpg"
  }'
```