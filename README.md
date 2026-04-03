# Quick Chat 💬

Quick Chat is a full-stack, real-time messaging platform inspired by the core chat experience of apps like WhatsApp: secure account onboarding, instant direct and group messaging, online presence, typing indicators, read receipts, profile management, and media-ready message structures.

This repository contains:

- **Backend**: Node.js + Express REST API, MongoDB (Mongoose), and Socket.IO for real-time transport.
- **Frontend**: Flutter client app using `provider` for state, `dio/http` for API communication, and `socket_io_client` for live updates.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Current Capabilities](#current-capabilities)
3. [Repository Structure](#repository-structure)
4. [Architecture Deep Dive](#architecture-deep-dive)
5. [Tech Stack](#tech-stack)
6. [Data Model](#data-model)
7. [REST API Reference](#rest-api-reference)
8. [Socket.IO Event Reference](#socketio-event-reference)
9. [Environment Variables](#environment-variables)
10. [Local Development Setup](#local-development-setup)
11. [Backend Walkthrough](#backend-walkthrough)
12. [Frontend Walkthrough](#frontend-walkthrough)
13. [Common Workflows](#common-workflows)
14. [Troubleshooting](#troubleshooting)
15. [Security Notes](#security-notes)
16. [Performance & Scaling Notes](#performance--scaling-notes)
17. [Roadmap Ideas](#roadmap-ideas)
18. [License](#license)

---

## Project Overview

Quick Chat is designed as a modular chat product with a clean separation of concerns:

- **Authentication & account lifecycle**:
  - Email signup/login
  - OTP verification
  - OTP resend
  - Forgot/reset password flows
- **User layer**:
  - Profile view/edit
  - Avatar upload
  - User search by username
  - Block/unblock user
- **Messaging layer**:
  - One-to-one conversations
  - Group messaging
  - Message editing/deletion/read receipts
  - Pagination-ready message retrieval
- **Realtime layer**:
  - Room-based Socket.IO delivery
  - Typing start/stop events
  - Presence online/offline events

The backend exposes predictable REST endpoints under `/api/*` and a Socket.IO endpoint on the same host/port. The Flutter client centralizes endpoint constants and swaps the backend base URL depending on emulator/device setup.

---

## Current Capabilities

### Authentication

- Signup with OTP send
- Verify OTP to complete account activation
- Resend OTP
- Login for verified users
- Logout (protected route)
- Forgot password via OTP
- Reset password using OTP

### User Profiles

- Fetch your own profile
- Update username/bio/status
- Upload avatar image
- Delete account
- Search other users by username query
- View public profile by username
- Block and unblock users

### Conversations & Messages

- Create/get direct conversation
- Fetch all user conversations
- Fetch a conversation by ID
- Delete a conversation
- Send direct messages
- Send group messages
- Edit message content
- Soft-delete message metadata (`isDeleted`, `deletedAt`)
- Mark messages as read
- Fetch conversation/group messages with pagination intent

### Groups

- Create groups
- Retrieve groups for current user
- Get group details
- Update group metadata
- Delete groups
- Add/remove members
- Leave group
- Update group avatar

### Realtime Behavior

- Authenticated socket handshake (JWT)
- Join direct-conversation rooms (`conversation:<id>`)
- Join group rooms (`group:<id>`)
- Broadcast new DM and new group messages
- Typing indicators for DM/group contexts
- Presence updates when users connect/disconnect
- Read receipt broadcasts (`messages_read`)

---

## Repository Structure

```text
Quick_Chat/
├── README.md                    # Root project documentation
├── backend/
│   ├── server.js                # App bootstrap, middleware, routes, Socket.IO setup
│   ├── env.example              # Environment variable template
│   ├── config/
│   │   └── db.js                # MongoDB connection bootstrap
│   ├── controllers/             # Business logic per resource
│   ├── middleware/              # Auth, uploads, shared middleware
│   ├── models/                  # Mongoose schemas (User, Message, Conversation, Group)
│   ├── routes/                  # REST route registration
│   └── socket/
│       └── socketHandler.js     # Realtime event handlers
└── frontend/
    ├── lib/
    │   ├── main.dart            # App entry point + route map
    │   ├── config/              # Theme and API constants
    │   ├── services/            # HTTP/socket/storage service abstractions
    │   ├── providers/           # State management
    │   ├── models/              # Client data models
    │   ├── screens/             # Auth/home/chat/group/profile screens
    │   └── widgets/             # Shared UI components
    └── pubspec.yaml             # Flutter dependencies and assets
```

---

## Architecture Deep Dive

### High-level Flow

1. Flutter app starts and checks auth state.
2. If unauthenticated, user goes through login/signup/OTP flow.
3. Client stores JWT securely and sends it in REST auth headers.
4. Client opens Socket.IO with JWT in handshake auth.
5. User joins relevant conversation/group rooms.
6. Messages travel through REST and/or socket events, then fan out to subscribed rooms.

### Backend Composition

- **HTTP API**: Express routes and controllers for CRUD-style operations.
- **DB Layer**: Mongoose schemas with validation, indexes, and convenience methods.
- **Realtime Layer**: Socket.IO server bound to same HTTP server with JWT auth middleware.
- **Cross-cutting middleware**:
  - CORS
  - JSON/urlencoded body parsing
  - Route-level auth checks
  - Upload middleware (for avatar/group media routes)

### Frontend Composition

- **State**: `AuthProvider` + `ChatProvider` via `MultiProvider`.
- **Navigation**:
  - Static named routes (login/signup/home/profile/create-group)
  - Dynamic route generation for OTP/direct-chat/group-chat screens
- **Service abstraction**:
  - API requests
  - auth token persistence
  - socket lifecycle and event handlers

---

## Tech Stack

### Backend

- **Runtime**: Node.js
- **Framework**: Express 4
- **Database**: MongoDB via Mongoose 8
- **Realtime**: Socket.IO 4
- **Auth**: JWT + bcrypt password hashing
- **Validation**: express-validator
- **Email/OTP delivery**: nodemailer
- **Media uploads**: multer + Cloudinary storage adapter
- **Dev tooling**: nodemon

### Frontend

- **Framework**: Flutter (Dart SDK >= 3.0.0 < 4.0.0)
- **State**: provider
- **Networking**: dio + http
- **Realtime client**: socket_io_client
- **Secure token storage**: flutter_secure_storage
- **UI tooling**: google_fonts, flutter_spinkit, fluttertoast, cached_network_image, intl, timeago

---

## Data Model

### `User`

Key fields:

- `username` (3–20 chars, unique, alphanumeric/underscore)
- `email` (unique, validated)
- `password` (hashed by pre-save hook)
- `profileImage`, `bio`, `status`
- `isVerified`, `otp`, `otpExpiry`
- `isOnline`, `lastSeen`
- `blockedUsers[]`

Behavior:

- Pre-save bcrypt hashing (`saltRounds=12`)
- `comparePassword` helper
- Sensitive fields removed from serialized JSON (`password`, OTP fields)

### `Conversation`

- `participants[]` (User refs)
- `lastMessage` (Message ref)
- `isGroup` flag (default false)
- `unreadCount` map for per-user counters
- Index on `participants` to help enforce/retrieve 1:1 threads

### `Message`

- One of `conversationId` or `groupId`
- `sender`, `content`, `type`, `mediaUrl`
- `readBy[]` with `readAt`
- Edit/delete metadata (`editedAt`, `isDeleted`, `deletedAt`)
- Compound indexes for message retrieval by conversation/group + time

### `Group`

- `name`, `description`, `groupImage`
- `admin` (User ref)
- `members[]` with role (`admin`/`member`) + joined timestamp
- `lastMessage`, `isActive`

---

## REST API Reference

> Base URL (local default): `http://localhost:5000`

### Health

- `GET /health` → API status payload with timestamp.

### Auth (`/api/auth`)

| Method | Route | Auth | Description |
|---|---|---|---|
| POST | `/signup` | No | Register account and trigger OTP |
| POST | `/verify-otp` | No | Verify OTP and complete activation |
| POST | `/resend-otp` | No | Resend verification OTP |
| POST | `/login` | No | Authenticate and receive JWT |
| POST | `/forgot-password` | No | Send password reset OTP |
| POST | `/reset-password` | No | Reset password with OTP |
| POST | `/logout` | Yes | Invalidate session/logout flow |

### Users (`/api/users`) — protected

| Method | Route | Description |
|---|---|---|
| GET | `/me` | Get current user profile |
| PUT | `/me` | Update profile fields |
| PUT | `/me/avatar` | Upload/replace avatar |
| DELETE | `/me` | Delete account |
| GET | `/search?q=<query>` | Search users by username |
| GET | `/:username` | Fetch public profile |
| POST | `/block/:userId` | Block user |
| DELETE | `/block/:userId` | Unblock user |

### Conversations (`/api/conversations`) — protected

| Method | Route | Description |
|---|---|---|
| GET | `/` | List my conversations |
| POST | `/` | Create/find DM conversation |
| GET | `/:id` | Conversation details |
| DELETE | `/:id` | Delete conversation |

### Messages (`/api/messages`) — protected

| Method | Route | Description |
|---|---|---|
| GET | `/conversation/:id` | Fetch conversation messages |
| GET | `/group/:id` | Fetch group messages |
| POST | `/conversation/:id` | Send DM |
| POST | `/group/:id` | Send group message |
| PUT | `/:id` | Edit message |
| DELETE | `/:id` | Delete message |
| PUT | `/:id/read` | Mark as read |

### Groups (`/api/groups`) — protected

| Method | Route | Description |
|---|---|---|
| GET | `/` | My groups |
| POST | `/` | Create group |
| GET | `/:id` | Group details |
| PUT | `/:id` | Update group metadata |
| DELETE | `/:id` | Delete group |
| POST | `/:id/members` | Add members |
| DELETE | `/:id/members/:userId` | Remove member |
| POST | `/:id/leave` | Leave group |
| PUT | `/:id/avatar` | Update group avatar |

### Auth Header Format

For protected endpoints:

```http
Authorization: Bearer <jwt_token>
```

---

## Socket.IO Event Reference

### Client → Server

- `join_conversation` `{ conversationId }`
- `join_group` `{ groupId }`
- `send_message` `{ conversationId, content, type?, mediaUrl? }`
- `send_group_message` `{ groupId, content, type?, mediaUrl? }`
- `typing_start` `{ conversationId? , groupId? }`
- `typing_stop` `{ conversationId? , groupId? }`
- `message_read` `{ conversationId }`

### Server → Client

- `new_message` `{ conversationId, message }`
- `new_group_message` `{ groupId, message }`
- `typing_start` / `typing_stop` with user context
- `messages_read` `{ conversationId, userId }`
- `user_online` `{ userId }`
- `user_offline` `{ userId, lastSeen }`
- `error` `{ message }` (socket-level failure feedback)

### Room Naming Convention

- Direct messages: `conversation:<conversationId>`
- Group messages: `group:<groupId>`

---

## Environment Variables

Create `backend/.env` (or copy `backend/env.example`) and set:

| Variable | Required | Description | Example |
|---|---|---|---|
| `PORT` | No | API server port | `5000` |
| `MONGODB_URI` | Yes | MongoDB connection string | `mongodb+srv://...` |
| `JWT_SECRET` | Yes | Secret used to sign JWTs | `super_long_random_secret` |
| `JWT_EXPIRES_IN` | No | JWT lifetime | `7d` |
| `EMAIL_HOST` | Yes | SMTP host for OTP/password mail | `smtp.gmail.com` |
| `EMAIL_PORT` | Yes | SMTP port | `587` |
| `EMAIL_USER` | Yes | SMTP username/email | `you@example.com` |
| `EMAIL_PASS` | Yes | SMTP password/app password | `********` |
| `CLOUDINARY_CLOUD_NAME` | Optional* | Cloudinary account cloud name | `my-cloud` |
| `CLOUDINARY_API_KEY` | Optional* | Cloudinary key | `123456...` |
| `CLOUDINARY_API_SECRET` | Optional* | Cloudinary secret | `******` |
| `CLIENT_URL` | No | Frontend URL allowlist helper | `http://localhost:3000` |
| `NODE_ENV` | No | Runtime environment | `development` |

\* Required if using avatar/media upload features.

---

## Local Development Setup

## 1) Prerequisites

Install:

- Node.js 18+ and npm
- Flutter SDK (matching Dart constraints in `pubspec.yaml`)
- MongoDB instance (local or Atlas)
- A mail provider account (SMTP) for OTP
- (Optional) Cloudinary account for image hosting

## 2) Clone & install dependencies

```bash
git clone <your-fork-or-repo-url>
cd Quick_Chat

cd backend
npm install

cd ../frontend
flutter pub get
```

## 3) Configure backend env

```bash
cd backend
cp env.example .env
# edit .env with your values
```

## 4) Start backend

```bash
cd backend
npm run dev
```

Expected startup behavior:

- MongoDB connection established
- Express server starts (default `5000`)
- Socket.IO server attached to same port

## 5) Configure Flutter API base URL

Edit `frontend/lib/config/api_config.dart`:

- Android emulator: `http://10.0.2.2:5000` (or your LAN IP if needed)
- iOS simulator: `http://localhost:5000`
- Physical device: `http://<your-machine-lan-ip>:5000`

> The current repository value is set to a LAN IP; update it to your environment before running.

## 6) Run Flutter app

```bash
cd frontend
flutter run
```

---

## Backend Walkthrough

### Server bootstrap (`backend/server.js`)

- Loads env via `dotenv`.
- Connects DB early via `connectDB()`.
- Creates HTTP server and attaches Socket.IO instance.
- Enables permissive CORS (`origin: '*'`) and JSON/urlencoded payload limits (`10mb`).
- Registers all route modules under `/api` namespace.
- Exposes `/health` for liveness checks.
- Includes 404 and global error middleware.

### Route/controller pattern

Each resource has:

- `routes/<resource>.js`: URL map + middleware
- `controllers/<resource>Controller.js`: business logic and DB operations
- `models/<resource>.js`: schema/validation/indexes

### Socket handler (`backend/socket/socketHandler.js`)

- Validates JWT from `socket.handshake.auth.token`.
- Tracks online users in-memory map (`userId -> socketId`).
- Persists `isOnline`/`lastSeen` updates in DB.
- Uses room-based fanout to isolate DM/group events.
- Writes messages to DB before broadcasting message events.

---

## Frontend Walkthrough

### App startup (`frontend/lib/main.dart`)

- Initializes `MultiProvider` for auth/chat global state.
- Uses dark theme (`AppTheme.dark`) and disables debug banner.
- Chooses startup screen based on `AuthStatus`:
  - Unknown → splash-like loading view
  - Authenticated → Home
  - Unauthenticated → Login
- Registers static and dynamic routes for auth, profile, chats, and groups.

### API config (`frontend/lib/config/api_config.dart`)

- Centralizes all REST endpoint constants.
- Uses `baseUrl` + route constants to avoid hard-coded strings spread across app.
- Reuses `baseUrl` as socket URL.

### Service/provider layering

- Service files encapsulate HTTP, token storage, socket wiring.
- Provider files expose reactive state for screens/widgets.
- UI screens consume provider state and trigger service actions.

---

## Common Workflows

### Create account and verify OTP

1. Open signup screen.
2. Submit username/email/password.
3. Receive OTP via configured email provider.
4. Verify OTP in app.
5. User receives token and lands in app flow.

### Start direct conversation

1. Search user by username.
2. Create/get conversation via conversation endpoint.
3. Join socket room for that conversation.
4. Send/receive instant messages and typing events.

### Create and manage group

1. Create group with name/description.
2. Add members.
3. Enter group chat screen and join group room.
4. Broadcast group messages to room participants.

---

## Troubleshooting

### App cannot connect to backend

- Confirm backend is running on expected port.
- Verify `ApiConfig.baseUrl` matches emulator/device networking rules.
- Check firewall and LAN connectivity for physical-device testing.

### OTP emails not received

- Validate SMTP credentials and sender policy.
- Check spam/promotions folders.
- Confirm provider allows the configured auth method (e.g., app password).

### Socket events not arriving

- Ensure JWT is passed in socket handshake auth.
- Confirm client emits `join_conversation` / `join_group` before expecting messages.
- Check backend logs for authentication errors on socket connect.

### Image uploads failing

- Verify Cloudinary env vars are set correctly.
- Ensure upload routes/middleware receive multipart form-data.

---

## Security Notes

- Passwords are hashed before storage.
- JWT protects private API routes and socket connections.
- Sensitive user fields are omitted from serialized responses.
- You should still harden for production by:
  - Restricting CORS to known origins
  - Adding rate limiting/brute-force protection
  - Adding request validation everywhere
  - Rotating secrets and isolating environments
  - Enforcing HTTPS and secure cookie/token practices

---

## Performance & Scaling Notes

Current design is suitable for small-to-medium projects and prototypes. For larger scale:

- Move socket presence map to shared infra (Redis) for multi-instance deployments.
- Add message delivery acknowledgements and retry strategies.
- Add background job queue for email/push notifications.
- Introduce pagination cursors and indexed query tuning based on production metrics.
- Add CDN + image transformations for media-heavy usage.

---

## Roadmap Ideas

- Push notifications (FCM/APNs)
- End-to-end encryption primitives
- Voice notes and richer media messages
- Message reactions and replies
- Admin moderation tools for groups
- Advanced search (message content, date ranges)
- Multi-device sync and delivery state guarantees

---

## License

No license file is currently included in this repository. Add a `LICENSE` file (for example MIT/Apache-2.0) before public distribution.
