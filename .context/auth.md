# Authentication Architecture

This document describes the authentication system for the Jiki API and its integration with the frontend.

## Implementation Todo List

### Backend (API) Tasks
- [x] Add Devise and devise-jwt gems to Gemfile
- [x] Configure Devise for API-only mode
- [x] Generate User model with Devise
- [x] Add OAuth-ready fields to User model
- [x] Configure JWT token handling
- [x] Create custom Devise controllers for JSON responses
- [x] Configure CORS for frontend
- [x] Set up API routes under `/api/v1/auth`
- [x] Configure mailer for frontend URLs
- [x] Create User factory for testing
- [x] Write unit tests for User model
- [x] Write API controller tests for auth endpoints

### Frontend (React/Next.js) Tasks
- [ ] Install auth dependencies (@tanstack/react-query, zustand)
- [ ] Create auth store/context for state management
- [ ] Build login form component
- [ ] Build registration form component
- [ ] Build password reset request form
- [ ] Build password reset form (with token)
- [ ] Create API client with JWT interceptor
- [ ] Add protected route wrapper
- [ ] Handle token storage (localStorage/memory)
- [ ] Implement auto-refresh for expiring tokens
- [ ] Add logout functionality
- [ ] Create auth hooks (useAuth, useCurrentUser, etc.)

### OAuth Integration (Future)
- [ ] Frontend: Add @react-oauth/google package
- [ ] Frontend: Implement Google OAuth button
- [ ] Backend: Add google-id-token gem for verification
- [ ] Backend: Add OAuth endpoint to accept Google tokens
- [ ] Backend: Find or create user from Google profile
- [ ] Test OAuth flow end-to-end

## Architecture Overview

### Technology Stack
- **Backend**: Devise + devise-jwt for Rails API
- **Frontend**: React Query + Zustand for state management
- **Token Format**: JWT (JSON Web Tokens)
- **Token Storage**: localStorage (with XSS considerations)
- **OAuth Ready**: Database schema includes provider ID fields

### Authentication Flow

#### Registration
1. User fills registration form on frontend
2. Frontend POSTs to `/api/v1/auth/signup`
3. API creates user, generates JWT
4. API returns JWT + user data
5. Frontend stores JWT, updates auth state

#### Login
1. User enters credentials on frontend
2. Frontend POSTs to `/api/v1/auth/login`
3. API validates credentials, generates JWT
4. API returns JWT + user data
5. Frontend stores JWT, updates auth state

#### Password Reset
1. User requests reset on frontend
2. Frontend POSTs email to `/api/v1/auth/password`
3. API sends email with frontend reset URL + token
4. User clicks link, lands on frontend reset form
5. Frontend PATCHes new password + token to `/api/v1/auth/password`
6. API validates token, updates password
7. Frontend can auto-login or redirect to login

#### JWT Token Lifecycle
- **Generation**: On login/registration
- **Expiry**: 30 days (configurable)
- **Revocation**: On logout (using JTIMatcher strategy)
- **Refresh**: Not implemented (tokens are long-lived)

## API Endpoints

### Authentication Endpoints

#### POST /api/v1/auth/signup
Register a new user account.

**Request:**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "secure_password123",
    "password_confirmation": "secure_password123",
    "name": "John Doe"
  }
}
```

**Success Response (201):**
```json
{
  "user": {
    "id": 123,
    "email": "user@example.com",
    "name": "John Doe",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```
**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Error Response (422):**
```json
{
  "error": {
    "type": "validation_error",
    "message": "Validation failed",
    "errors": {
      "email": ["has already been taken"],
      "password": ["is too short (minimum is 6 characters)"]
    }
  }
}
```

#### POST /api/v1/auth/login
Authenticate and receive JWT token.

**Request:**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "secure_password123"
  }
}
```

**Success Response (200):**
```json
{
  "user": {
    "id": 123,
    "email": "user@example.com",
    "name": "John Doe",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```
**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Error Response (401):**
```json
{
  "error": {
    "type": "invalid_credentials",
    "message": "Invalid email or password"
  }
}
```

#### DELETE /api/v1/auth/logout
Revoke the current JWT token.

**Headers Required:**
```
Authorization: Bearer <jwt_token>
```

**Success Response (204):**
No content

#### POST /api/v1/auth/password
Request password reset email.

**Request:**
```json
{
  "user": {
    "email": "user@example.com"
  }
}
```

**Success Response (200):**
```json
{
  "message": "Reset instructions sent to user@example.com"
}
```

#### PATCH /api/v1/auth/password
Reset password with token.

**Request:**
```json
{
  "user": {
    "reset_password_token": "abc123...",
    "password": "new_secure_password",
    "password_confirmation": "new_secure_password"
  }
}
```

**Success Response (200):**
```json
{
  "message": "Password has been reset successfully"
}
```

**Error Response (422):**
```json
{
  "error": {
    "type": "invalid_token",
    "message": "Reset token is invalid or has expired"
  }
}
```

### Future OAuth Endpoints

#### POST /api/v1/auth/google
Authenticate with Google OAuth token.

**Request:**
```json
{
  "token": "google_jwt_token_here"
}
```

**Success Response (200):**
```json
{
  "user": {
    "id": 123,
    "email": "user@gmail.com",
    "name": "John Doe",
    "provider": "google"
  }
}
```
**Headers:**
```
Authorization: Bearer <jwt_token>
```

## Frontend Integration

### Required Packages
```json
{
  "dependencies": {
    "@tanstack/react-query": "^5.0.0",
    "zustand": "^4.4.0",
    "axios": "^1.6.0"
  }
}
```

### Auth Store Example (Zustand)
```jsx
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

const useAuthStore = create(
  persist(
    (set, get) => ({
      token: null,
      user: null,

      setAuth: (token, user) => set({ token, user }),

      clearAuth: () => set({ token: null, user: null }),

      isAuthenticated: () => !!get().token,
    }),
    {
      name: 'auth-storage',
    }
  )
);
```

### API Client Setup
```jsx
import axios from 'axios';

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
apiClient.interceptors.request.use(
  (config) => {
    const token = useAuthStore.getState().token;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor to extract token
apiClient.interceptors.response.use(
  (response) => {
    const token = response.headers.authorization?.replace('Bearer ', '');
    if (token) {
      const user = response.data.user;
      useAuthStore.getState().setAuth(token, user);
    }
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().clearAuth();
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);
```

### Auth Hooks
```jsx
// useAuth hook
export const useAuth = () => {
  const { token, user, isAuthenticated, clearAuth } = useAuthStore();

  const login = useMutation({
    mutationFn: async ({ email, password }) => {
      const response = await apiClient.post('/api/v1/auth/login', {
        user: { email, password }
      });
      return response.data;
    },
  });

  const register = useMutation({
    mutationFn: async ({ email, password, name }) => {
      const response = await apiClient.post('/api/v1/auth/signup', {
        user: { email, password, password_confirmation: password, name }
      });
      return response.data;
    },
  });

  const logout = useMutation({
    mutationFn: async () => {
      await apiClient.delete('/api/v1/auth/logout');
      clearAuth();
    },
  });

  return {
    user,
    token,
    isAuthenticated: isAuthenticated(),
    login,
    register,
    logout,
  };
};
```

### Protected Route Component
```jsx
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';

export const ProtectedRoute = ({ children }) => {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return children;
};
```

## Database Schema

### User Model
```ruby
create_table :users do |t|
  # Devise fields
  t.string :email,              null: false, default: ""
  t.string :encrypted_password, null: false, default: ""

  # User profile
  t.string :name

  # Devise recoverable
  t.string   :reset_password_token
  t.datetime :reset_password_sent_at

  # Devise rememberable
  t.datetime :remember_created_at

  # Devise trackable
  t.integer  :sign_in_count, default: 0, null: false
  t.datetime :current_sign_in_at
  t.datetime :last_sign_in_at
  t.string   :current_sign_in_ip
  t.string   :last_sign_in_ip

  # OAuth ready fields (for future)
  t.string :google_id
  t.string :github_id
  t.string :provider

  # JWT revocation
  t.string :jti, null: false

  t.timestamps
end

add_index :users, :email, unique: true
add_index :users, :reset_password_token, unique: true
add_index :users, :jti, unique: true
add_index :users, :google_id, unique: true
add_index :users, :github_id, unique: true
```

## Security Considerations

### JWT Token Security
- Tokens are signed with Rails secret key
- JTI (JWT ID) used for revocation tracking
- Tokens expire after 30 days
- Revoked tokens are blacklisted via JTIMatcher

### Password Security
- Minimum 6 characters required
- Encrypted using bcrypt
- Reset tokens expire after 2 hours
- Reset tokens are single-use

### Frontend Security
- XSS Protection: Sanitize all user input
- Token Storage: Consider memory-only storage for high security
- HTTPS Required: Always use HTTPS in production
- CORS: Restrict to known frontend domains

### API Security
- Rate limiting on auth endpoints (implement with rack-attack)
- Strong parameter filtering
- SQL injection prevention via Active Record
- Timing attack prevention in password comparison

## Testing Strategy

### Unit Tests (User Model)
- Validation tests (email format, password length)
- Authentication tests (password verification)
- Token generation tests
- Password reset flow tests

### Controller Tests (API Endpoints)
- Registration with valid/invalid params
- Login with correct/incorrect credentials
- Password reset request
- Password reset with valid/invalid token
- Logout and token revocation
- Authentication required for protected endpoints

### Integration Tests
- Full registration → login → logout flow
- Complete password reset flow
- Token expiration handling
- OAuth flow (when implemented)

## Configuration Files

### Devise Initializer
Key settings for API-only mode:
- `config.navigational_formats = []` (disable redirects)
- `config.jwt` configuration block
- JWT secret from Rails credentials
- Token expiration settings

### CORS Configuration
Allow frontend domain with credentials:
```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins Jiki.config.frontend_base_url
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization'],
      credentials: true
  end
end
```

**Note**: Uses `Jiki.config.frontend_base_url` from `../config/settings/*.yml` files.

## Monitoring & Debugging

### Logging
- Log all authentication attempts
- Track failed login attempts
- Monitor password reset requests
- Log token revocations

### Metrics to Track
- Registration conversion rate
- Login success/failure ratio
- Password reset completion rate
- Average session duration
- Token refresh patterns

### Common Issues & Solutions
1. **CORS errors**: Check origins in cors.rb
2. **Token not sent**: Verify Authorization header
3. **Token expired**: Implement refresh or longer expiry
4. **Password reset not working**: Check mailer configuration
5. **OAuth failing**: Verify provider credentials

## Future Enhancements

### Short Term
- [ ] Email verification on registration
- [ ] Account lockout after failed attempts
- [ ] Two-factor authentication
- [ ] Remember me functionality
- [ ] Session management UI

### Long Term
- [ ] OAuth providers (Google, GitHub, Apple)
- [ ] Magic link authentication
- [ ] Biometric authentication (mobile)
- [ ] Single Sign-On (SSO)
- [ ] Multi-device session management