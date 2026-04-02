# Quick Chat 💬

A **WhatsApp-like real-time messaging app** built with Flutter (frontend) and Express.js (backend).

---

## Project Structure

```
Quick_Chat/
├── backend/       → Express.js REST API + Socket.IO server
└── frontend/      → Flutter mobile app
```

---

## Backend Setup

### 1. Fill in `.env`

```env
PORT=5000
MONGODB_URI=               # ← paste your MongoDB connection string
JWT_SECRET=your_secret
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=                # ← your Gmail address
EMAIL_PASS=                # ← Gmail app password
CLOUDINARY_CLOUD_NAME=     # ← Cloudinary credentials (for image uploads)
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
```

### 2. Install & Run

```bash
cd backend
npm install
npm run dev        # development (nodemon)
# or
npm start          # production
```

Server starts on `http://localhost:5000`

---

## Frontend Setup

### 1. Update Base URL

Edit `frontend/lib/config/api_config.dart`:

```dart
// Android emulator → points to your machine's localhost
static const String baseUrl = 'http://10.0.2.2:5000';

// iOS simulator
// static const String baseUrl = 'http://localhost:5000';

// Physical device → use your machine's local IP
// static const String baseUrl = 'http://192.168.x.x:5000';
```

### 2. Install & Run

```bash
cd frontend
flutter pub get
flutter run
```

---

## API Endpoints

### Auth — `/api/auth`
| Method | Route | Description |
|--------|-------|-------------|
| POST | `/signup` | Register (sends OTP) |
| POST | `/verify-otp` | Verify OTP → JWT |
| POST | `/resend-otp` | Resend OTP |
| POST | `/login` | Login → JWT |
| POST | `/logout` | Logout (protected) |
| POST | `/forgot-password` | Send reset OTP |
| POST | `/reset-password` | Reset with OTP |

### Users — `/api/users` (all protected)
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/me` | My profile |
| PUT | `/me` | Update bio/username/status |
| PUT | `/me/avatar` | Upload profile photo |
| DELETE | `/me` | Delete account |
| GET | `/search?q=` | Search by username |
| GET | `/:username` | Public profile |
| POST | `/block/:userId` | Block user |
| DELETE | `/block/:userId` | Unblock user |

### Conversations — `/api/conversations` (all protected)
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/` | All my conversations |
| POST | `/` | Start/get DM |
| GET | `/:id` | Single conversation |
| DELETE | `/:id` | Delete conversation |

### Messages — `/api/messages` (all protected)
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/conversation/:id` | Fetch DM messages (paginated) |
| GET | `/group/:id` | Fetch group messages (paginated) |
| POST | `/conversation/:id` | Send DM message |
| POST | `/group/:id` | Send group message |
| PUT | `/:id` | Edit message |
| DELETE | `/:id` | Delete message |
| PUT | `/:id/read` | Mark as read |

### Groups — `/api/groups` (all protected)
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/` | My groups |
| POST | `/` | Create group |
| GET | `/:id` | Group details |
| PUT | `/:id` | Update group info |
| DELETE | `/:id` | Delete group |
| POST | `/:id/members` | Add members |
| DELETE | `/:id/members/:userId` | Remove member |
| POST | `/:id/leave` | Leave group |
| PUT | `/:id/avatar` | Update group image |

---

## Socket.IO Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `join_conversation` | Client→Server | Join DM room |
| `join_group` | Client→Server | Join group room |
| `send_message` | Client→Server | Send DM |
| `send_group_message` | Client→Server | Send group message |
| `new_message` | Server→Client | Receive DM |
| `new_group_message` | Server→Client | Receive group message |
| `typing_start` | Client→Server | Typing started |
| `typing_stop` | Client→Server | Typing stopped |
| `message_read` | Client→Server | Mark read |
| `messages_read` | Server→Client | Read receipt |
| `user_online` | Server→Client | User came online |
| `user_offline` | Server→Client | User went offline |

---

## Features

- ✅ Email + OTP signup/verification
- ✅ JWT authentication (stored securely)
- ✅ Real-time messaging via Socket.IO / WebSockets
- ✅ 1:1 DM conversations
- ✅ Group chats with admin roles
- ✅ Typing indicators
- ✅ Read receipts
- ✅ Online/offline status
- ✅ Profile with avatar upload (Cloudinary)
- ✅ Username search
- ✅ Message edit & delete
- ✅ Paginated message history
- ✅ Dark mode UI
