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
- **Generation**: On login/registration (dual-token system)
- **Access Token Expiry**: 1 hour (short-lived for security)
- **Refresh Token Expiry**: 30 days (long-lived for UX)
- **Revocation**: On logout (using Allowlist strategy)
- **Refresh**: POST /v1/auth/refresh with refresh token to get new access token
- **Multi-Device Support**: Users can have multiple active sessions across devices

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
  },
  "refresh_token": "long_lived_refresh_token_here"
}
```
**Headers:**
```
Authorization: Bearer <short_lived_access_token>
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
  },
  "refresh_token": "long_lived_refresh_token_here"
}
```
**Headers:**
```
Authorization: Bearer <short_lived_access_token>
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
Revoke all refresh tokens for the user (logs out from all devices).

**Headers Required:**
```
Authorization: Bearer <jwt_token>
```

**Success Response (204):**
No content

#### POST /v1/auth/refresh
Refresh an expired access token using a refresh token.

**Request:**
```json
{
  "refresh_token": "long_lived_refresh_token_here"
}
```

**Success Response (200):**
```json
{
  "message": "Access token refreshed successfully"
}
```
**Headers:**
```
Authorization: Bearer <new_short_lived_access_token>
```

**Error Response (401 - Invalid):**
```json
{
  "error": {
    "type": "invalid_token",
    "message": "Invalid refresh token"
  }
}
```

**Error Response (401 - Expired):**
```json
{
  "error": {
    "type": "expired_token",
    "message": "Refresh token has expired"
  }
}
```

**Error Response (400 - Missing):**
```json
{
  "error": {
    "type": "invalid_request",
    "message": "Refresh token is required"
  }
}
```

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
      accessToken: null,      // Short-lived (1 hour), stored in memory/sessionStorage
      refreshToken: null,     // Long-lived (30 days), stored in localStorage
      user: null,

      setAuth: (accessToken, refreshToken, user) => set({
        accessToken,
        refreshToken,
        user
      }),

      setAccessToken: (accessToken) => set({ accessToken }),

      clearAuth: () => set({
        accessToken: null,
        refreshToken: null,
        user: null
      }),

      isAuthenticated: () => !!get().accessToken,
    }),
    {
      name: 'auth-storage',
      // Only persist refreshToken and user, not accessToken
      partialize: (state) => ({
        refreshToken: state.refreshToken,
        user: state.user
      }),
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

let isRefreshing = false;
let failedQueue = [];

const processQueue = (error, token = null) => {
  failedQueue.forEach(prom => {
    if (error) {
      prom.reject(error);
    } else {
      prom.resolve(token);
    }
  });
  failedQueue = [];
};

// Request interceptor to add access token
apiClient.interceptors.request.use(
  (config) => {
    const accessToken = useAuthStore.getState().accessToken;
    if (accessToken) {
      config.headers.Authorization = `Bearer ${accessToken}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor to handle token refresh
apiClient.interceptors.response.use(
  (response) => {
    // Extract access token from login/signup responses
    const accessToken = response.headers.authorization?.replace('Bearer ', '');
    if (accessToken && response.data.user) {
      const { user, refresh_token } = response.data;
      useAuthStore.getState().setAuth(accessToken, refresh_token, user);
    }
    return response;
  },
  async (error) => {
    const originalRequest = error.config;

    // If 401 and we haven't tried to refresh yet
    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        // Queue this request to retry after refresh completes
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        }).then(token => {
          originalRequest.headers.Authorization = `Bearer ${token}`;
          return apiClient(originalRequest);
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      const refreshToken = useAuthStore.getState().refreshToken;
      if (!refreshToken) {
        useAuthStore.getState().clearAuth();
        window.location.href = '/login';
        return Promise.reject(error);
      }

      try {
        const response = await apiClient.post('/v1/auth/refresh', {
          refresh_token: refreshToken
        });

        const newAccessToken = response.headers.authorization?.replace('Bearer ', '');
        useAuthStore.getState().setAccessToken(newAccessToken);

        processQueue(null, newAccessToken);

        originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
        return apiClient(originalRequest);
      } catch (refreshError) {
        processQueue(refreshError, null);
        useAuthStore.getState().clearAuth();
        window.location.href = '/login';
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
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

  # User profile
  t.string :locale, null: false, default: "en"

  # OAuth ready fields (for future)
  t.string :google_id
  t.string :github_id
  t.string :provider

  t.timestamps
end

add_index :users, :email, unique: true
add_index :users, :reset_password_token, unique: true
add_index :users, :google_id, unique: true
add_index :users, :github_id, unique: true

# JWT Allowlist - stores active access tokens (1 hour expiry)
create_table :user_jwt_tokens do |t|
  t.references :user, null: false, foreign_key: true
  t.string :jti, null: false         # JWT ID from token payload
  t.string :aud                      # Device identifier (User-Agent)
  t.datetime :exp, null: false       # Expiration time
  t.timestamps
end

add_index :user_jwt_tokens, :jti, unique: true

# Refresh Tokens - stores long-lived refresh tokens (30 days)
create_table :user_refresh_tokens do |t|
  t.references :user, null: false, foreign_key: true
  t.string :crypted_token, null: false  # SHA256 hash of refresh token
  t.string :aud                         # Device identifier (User-Agent)
  t.datetime :exp, null: false          # Expiration time
  t.timestamps
end

add_index :user_refresh_tokens, :crypted_token, unique: true
```

## Security Considerations

### JWT Token Security
- **Dual-Token System**: Access tokens (1hr) + Refresh tokens (30 days)
- **Access Tokens**: Signed with Rails secret key, stored in Allowlist table
- **Refresh Tokens**: SHA256 hashed before storage (like passwords)
- **JTI (JWT ID)**: Used for tracking and revoking individual access tokens
- **Multi-Device Support**: Users can have multiple active sessions
- **Revocation**: Allowlist strategy - tokens must exist in db to be valid
- **Device Tracking**: User-Agent stored in `aud` field for session management
- **Expired Token Cleanup**: Expired refresh tokens automatically destroyed on use

### Password Security
- Minimum 6 characters required
- Encrypted using bcrypt
- Reset tokens expire after 2 hours
- Reset tokens are single-use

### Frontend Security
- **XSS Protection**: Sanitize all user input
- **Token Storage Strategy**:
  - Access tokens: sessionStorage or memory (short-lived, less critical)
  - Refresh tokens: localStorage (long-lived, enables persistence)
- **HTTPS Required**: Always use HTTPS in production
- **CORS**: Restrict to known frontend domains
- **Token Refresh**: Automatic refresh on 401 minimizes exposure window
- **Request Queueing**: Multiple concurrent 401s handled gracefully

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
    origins ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization'],
      credentials: true
  end
end
```

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
- [x] Multi-device session management (✅ Implemented with Allowlist strategy)