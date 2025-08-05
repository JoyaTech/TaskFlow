# MindFlow - Secure Task Management App

![Hebrew RTL Support](https://img.shields.io/badge/Hebrew-RTL%20Support-blue)
![Firebase](https://img.shields.io/badge/Firebase-Secure-orange)
![Flutter](https://img.shields.io/badge/Flutter-Latest-cyan)
![Security](https://img.shields.io/badge/Security-Enhanced-green)

A Hebrew-first task management and voice assistant app for users with ADHD, now with enterprise-grade security.

## 🚨 MAJOR SECURITY UPDATES (August 2025)

This repository contains **critical security fixes** that address multiple vulnerabilities:

### ✅ CRITICAL FIXES IMPLEMENTED

1. **🔒 Firebase Security Rules - FIXED**
   - **Issue**: Wide-open Firestore access with temporary expiration
   - **Fix**: Implemented user-specific authentication rules
   - **Impact**: Prevents unauthorized data access

2. **📱 Android Package Consistency - FIXED**
   - **Issue**: Inconsistent package naming (CounterApp vs mindflow)
   - **Fix**: Standardized to `com.mindflow.app`
   - **Impact**: Eliminates app store conflicts

3. **🔐 Authentication Validation - IMPLEMENTED**
   - **Issue**: Database operations lacked user authentication checks
   - **Fix**: All operations now require authentication
   - **Impact**: Prevents unauthorized data access across user boundaries

4. **🛡️ Secure Cloud Database - IMPLEMENTED**
   - **Issue**: Local SQLite with no user isolation
   - **Fix**: Migrated to Firebase Firestore with security rules
   - **Impact**: Scalable, secure, user-isolated data storage

5. **🔑 Configuration Security - ENHANCED**
   - **Issue**: Hardcoded Firebase configuration in public code
   - **Fix**: Environment variable placeholders
   - **Impact**: Prevents configuration tampering

## 🏗️ ARCHITECTURE IMPROVEMENTS

### Secure Data Layer
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   UI Layer      │    │  Repository     │    │ Cloud Database  │
│   (Widgets)     │───►│   Pattern       │───►│   (Firestore)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │ Authentication  │    │ Security Rules  │
                       │    Service      │    │  (User-based)   │
                       └─────────────────┘    └─────────────────┘
```

### Key Security Features
- **Authentication-First**: All operations require user authentication
- **User Data Isolation**: Firebase security rules enforce user-specific access
- **Input Validation**: All user inputs are sanitized and validated
- **Rate Limiting**: Authentication service includes rate limiting
- **Session Management**: Secure session handling with timeouts

## 🚀 FEATURES

### Task Management
- ✅ Create, edit, and delete tasks
- ✅ Voice note support
- ✅ Priority levels (Simple, Important, Later)
- ✅ Due date reminders
- ✅ Real-time synchronization

### Focus 6 Productivity
- ✅ Pomodoro timer with customizable sessions
- ✅ Break time management
- ✅ Focus statistics and analytics
- ✅ Habit tracking

### Hebrew-First Design
- ✅ Right-to-left (RTL) interface
- ✅ Hebrew date and time formatting
- ✅ Culturally appropriate UX patterns
- ✅ Hebrew voice command support

### Security 6 Privacy
- 🔒 End-to-end user authentication
- 🔒 User data isolation
- 🔒 Secure cloud storage
- 🔒 Input validation and sanitization
- 🔒 Rate limiting and session management

## 📱 PLATFORMS

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- ✅ Web (Progressive Web App)
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🛠️ DEVELOPMENT SETUP

### Prerequisites
- Flutter SDK (3.6.0+)
- Firebase CLI
- Android Studio / Xcode (for mobile development)

### Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/mindflow.git
cd mindflow

# Install dependencies
flutter pub get

# Configure Firebase (replace placeholders with actual values)
# Update firebase.json with your project configuration

# Run the app
flutter run
```

### Firebase Setup
1. Create a new Firebase project
2. Enable Authentication (Email/Password, Google)
3. Enable Firestore Database
4. Update `firebase.json` with your project ID
5. Download and place configuration files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

## 🏗️ PROJECT STRUCTURE

```
lib/
├── core/
│   └── router.dart              # App navigation
├── services/
│   ├── auth_service.dart        # Authentication with security
│   ├── cloud_database_service.dart  # Secure Firestore operations
│   ├── database_service.dart    # Database wrapper
│   └── validation_service.dart  # Input validation
├── providers/
│   └── task_providers.dart      # State management with DI
├── screens/
│   ├── auth_wrapper.dart        # Authentication flow
│   ├── login_screen.dart        # Login interface
│   └── registration_screen.dart # Registration interface
└── main.dart                    # App entry point
```

## 🔐 SECURITY CONSIDERATIONS

### Firebase Security Rules
The app implements strict Firestore security rules:

```javascript
// Users can only access their own data
match /tasks/{taskId} {
  allow read, write: if request.auth != null 6 
    request.auth.uid == resource.data.userId;
}
```

### Authentication Flow
1. User registers/logs in via Firebase Auth
2. User ID is verified on all database operations
3. All data is scoped to authenticated user only
4. Session management with automatic timeout

### Data Validation
- All inputs are sanitized before storage
- Task titles limited to 200 characters
- Voice notes are validated for content
- Date validation for due dates

## 🧪 TESTING

```bash
# Run all tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

## 📈 ANALYTICS 6 MONITORING

- Task completion rates
- Focus session statistics
- User engagement metrics
- Performance monitoring via Firebase

## 🌍 LOCALIZATION

Currently supported languages:
- Hebrew (he_IL) - Primary
- English (en_US) - Secondary

## 🤝 CONTRIBUTING

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Ensure security standards are met
5. Submit a pull request

### Security Guidelines
- Never commit sensitive data
- Use environment variables for configuration
- Implement input validation for all user inputs
- Follow Firebase security best practices
- Test authentication flows thoroughly

## 📄 LICENSE

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 SUPPORT

For support, please open an issue on GitHub or contact the development team.

## 📋 CHANGELOG

### v2.0.0 (August 2025) - SECURITY RELEASE
- 🔒 **CRITICAL**: Fixed Firebase security rules vulnerability
- 🔒 **CRITICAL**: Implemented user authentication enforcement
- 🔒 **CRITICAL**: Migrated to secure cloud database
- 📱 Fixed Android package naming consistency
- 🏗️ Implemented repository pattern with dependency injection
- ✅ Enhanced input validation and sanitization
- 🔐 Added rate limiting and session management
- 📊 Improved error handling and logging

### v1.0.0 (Previous)
- Initial release with basic task management
- Hebrew RTL support
- Voice commands
- Local database storage

---

**⚠️ IMPORTANT**: This release contains critical security fixes. All users should update immediately.
