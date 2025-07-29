---
description: Repository Information Overview
alwaysApply: true
---

# Task App Information

## Summary
A Flutter-based task management application with Firebase backend integration. The app provides task creation, assignment, and management features with real-time updates. It includes user authentication, chat functionality, news integration, and export capabilities.

## Structure
- **lib/**: Core application code with MVC architecture (controllers, models, views, services)
- **android/**, **ios/**, **web/**, **macos/**, **linux/**, **windows/**: Platform-specific code
- **assets/**: Application resources (images, fonts, sounds, environment variables)
- **functions/**: Firebase Cloud Functions for backend operations
- **test/**: Testing files

## Language & Runtime
**Language**: Dart/Flutter
**Version**: Flutter SDK ^3.5.4
**Build System**: Flutter build system
**Package Manager**: pub (Dart package manager)

## Dependencies
**Main Dependencies**:
- firebase_core: ^3.15.0 (Firebase integration)
- firebase_auth: ^5.0.0 (Authentication)
- cloud_firestore: ^5.0.0 (Database)
- firebase_storage: ^12.0.0 (File storage)
- get: ^4.7.2 (State management)
- isar: ^3.1.0+1 (Local database)
- flutter_dotenv: ^5.2.1 (Environment variables)
- share_plus: ^11.0.0 (Sharing functionality)

**Development Dependencies**:
- flutter_test (Testing framework)
- flutter_lints: ^6.0.0 (Code quality)
- build_runner: ^2.4.13 (Code generation)
- isar_generator: ^3.1.0+1 (Database schema generation)

## Build & Installation
```bash
# Install dependencies
flutter pub get

# Generate code (for Isar database)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the application
flutter run

# Build for specific platforms
flutter build apk  # Android
flutter build ios  # iOS
flutter build web  # Web
```

## Firebase Configuration
**Services**: Authentication, Firestore, Storage, Cloud Functions, Messaging, Realtime Database
**Functions**: Node.js v22 backend with admin user deletion functionality
**Deployment**:
```bash
# Deploy Firebase functions
cd functions
npm install
firebase deploy --only functions
```

## Testing
**Framework**: flutter_test
**Test Location**: test/
**Run Command**:
```bash
flutter test
```

## Application Structure
**Entry Point**: lib/main.dart → lib/core/bootstrap.dart → lib/my_app.dart
**State Management**: GetX (controllers in lib/controllers/)
**Data Models**: lib/models/ (with Isar integration)
**Services**: lib/service/ (Firebase, local storage, export, notifications)
**UI Components**: lib/widgets/ (Reusable UI components)
**Screens**: lib/views/ (Application screens)

## Export Functionality
**Service**: ExportService handles exporting tasks to CSV and JSON formats
**Sharing**: Integrated with share_plus for sharing exported files
**Formats**: Supports CSV and JSON exports
**Implementation**: Uses Task.toMap() for JSON serialization