# Melbet Manager Backend

## Setup

### 1. Prerequisites
- Node.js 18+
- MongoDB Atlas account (or local MongoDB)

### 2. Install dependencies
```bash
cd backend
npm install
```

### 3. Configure environment
```bash
cp .env.example .env
# Edit .env with your MongoDB URI and JWT secret
```

### 4. Seed the database (creates default admin account)
```bash
npm run seed
```

### 5. Start the server
```bash
# Development (auto-reload)
npm run dev

# Production
npm start
```

Server runs on `http://localhost:3000` by default.

---

## API Endpoints

### Auth
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/auth/login` | No | Login, returns JWT |
| POST | `/api/auth/register` | No | Register new user (pending approval) |
| POST | `/api/auth/forgot-password` | No | Lookup account by email |
| GET | `/api/auth/me` | JWT | Get current user |

### Users (Admin only)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/users` | List all users |
| GET | `/api/users/pending` | Pending approvals |
| PATCH | `/api/users/:id/approve` | Approve user |
| PATCH | `/api/users/:id/reject` | Reject / delete user |
| PATCH | `/api/users/:id/active` | Enable/disable user |

### Reports
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/reports` | JWT | All reports (admin) or own (employee) |
| GET | `/api/reports/employees` | Admin | Get employees list |
| POST | `/api/reports` | Employee | Submit new report |
| PATCH | `/api/reports/:id` | Employee | Update own report |
| PATCH | `/api/reports/:id/status` | Admin | Update report status |
| DELETE | `/api/reports/:id` | Admin | Delete report |

---

## Default Credentials
After seeding:
- **Admin**: `admin` / `admin123`
- **Employee**: `alem` / `emp123`
- **Employee**: `biruk` / `emp123`
