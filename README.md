# Task Management Application

A comprehensive task management and news application built with Flutter and Firebase, featuring real-time collaboration, integrated news feeds, multi-language support, and cross-platform compatibility. Designed to streamline workflow and enhance productivity across different roles including Admin, Assignment Editors, Librarians, Reporters, and more.

## 📱 Features

### 🔐 Authentication & User Management

- Secure email/password authentication with Firebase Auth
- Social authentication (Google Sign-In, Apple Sign-In)
- Biometric authentication (fingerprint/face recognition)
- Role-based access control (Admin, Librarian, Reporter, etc.)
- User profile management with photo upload
- Admin user management and role assignment

### 📋 Task Management

- Create, assign, and track tasks with real-time updates
- Task categorization and prioritization
- Due date tracking with interactive calendar view
- Task status updates with progress tracking
- File attachments and document sharing
- Task filtering and search functionality
- Collaborative task comments and discussions

### 📚 Library Management (For Librarians)

- Book and resource management
- Check-in/Check-out system
- Resource categorization

### 📊 Admin Dashboard

- User management
- Role assignment
- System analytics and reports
- Activity monitoring

### 📰 Integrated News Platform

- Multi-source news aggregation (BBC, CNN, Al Jazeera, Reuters, TVC News)
- Real-time news updates and notifications
- Customizable news feed preferences
- News sharing and collaboration features
- Offline news reading capability

### 🔔 Real-time Notifications

- Push notifications for task assignments and updates
- Due date reminders and alerts
- News breaking alerts
- System announcements
- Customizable notification preferences

### 🌐 Multi-language Support

- Support for 5 languages: English, French, Hausa, Yoruba, Igbo
- Dynamic language switching
- Localized content and UI elements
- Cultural adaptation for different regions

### 📱 In-App Updates

- Automatic update detection
- Manual update check in settings
- Android In-App Updates (immediate and flexible)
- iOS App Store integration
- Update notifications and prompts

### 🌐 Offline Support

- Local data persistence with SQLite database
- Sync when back online
- Offline task creation and editing
- Cached news articles for offline reading

### 🎨 Customization & Accessibility

- Theme support (light/dark mode)
- Customizable dashboard layouts
- User preferences and settings
- Responsive design for all screen sizes
- Accessibility features and screen reader support
- Custom wallpapers and personalization options

## 🛠️ Tech Stack

### Frontend

- **Framework**: Flutter (latest stable)
- **State Management**: GetX
- **UI Components**: Material Design with custom theming
- **Local Database**: SQLite with sqflite
- **PDF Generation**: pdf package
- **Image Handling**: image_picker, file_picker
- **Authentication**: local_auth (biometrics)
- **Internationalization**: flutter_localizations
- **Updates**: in_app_update, package_info_plus

### Backend

- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore with real-time sync
- **File Storage**: Firebase Storage
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Analytics**: Firebase Analytics
- **Hosting**: Firebase Hosting
- **Functions**: Firebase Cloud Functions
- **News APIs**: Multiple news source integrations

### Development Tools

- Flutter SDK
- Android Studio / VS Code
- Firebase CLI
- Flutter DevTools

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (as per Flutter version)
- Android Studio / Xcode (for mobile development)
- Firebase account and project setup

### Installation

1. **Clone the repository**

   ```bash
   git clone [your-repository-url]
   cd task
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a new Firebase project
   - Enable Authentication, Firestore, Storage, and FCM
   - Add Android/iOS apps to your Firebase project
   - Download the configuration files:
     - `google-services.json` for Android (place in `android/app/`)
     - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)
   - Configure Firebase rules for security

4. **Configure environment**
   - Copy `.env.example` to `.env` and fill in your configuration
   - Set up news API keys if using external news sources
   - Configure social authentication (Google, Apple)

5. **Run the app**

   ```bash
   flutter run
   ```

### 📱 Platform-specific Setup

#### Android

- Minimum SDK: 24 (Android 7.0)
- Target SDK: 35
- Supports ARM64 and ARMv7 architectures
- In-app updates require Google Play Console setup

#### iOS

- Minimum iOS version: 12.0
- Requires Xcode 14.0 or later
- App Store Connect configuration for updates
- Biometric authentication setup in Info.plist

## 📁 Project Structure

lib/
├── controllers/      # Business logic and state management
├── core/            # Core functionality and bootstrap
├── features/        # Feature modules
│   └── librarian/   # Librarian-specific features
├── models/          # Data models (Task, Chat, Filters)
├── routes/          # App navigation and middleware
├── service/         # Services and APIs
│   ├── fcm_service.dart        # Push notifications
│   ├── news_service.dart       # News aggregation
│   ├── task_service.dart       # Task management
│   ├── update_service.dart     # In-app updates
│   ├── android_update_service.dart
│   └── ios_update_service.dart
├── theme/           # App theming and durations
├── utils/           # Helper functions and utilities
│   ├── constants/   # App constants
│   ├── localization/ # Multi-language support
│   ├── themes/      # Theme configurations
│   └── validators/  # Input validation
├── views/           # UI screens
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── news_screen.dart
│   ├── chat_screen.dart
│   └── auth screens...
└── widgets/         # Reusable UI components
    ├── app_drawer.dart
    ├── task_card.dart
    ├── news/ # News-specific widgets
    └── navigation bars...

## 🔧 Environment Setup

1. Create a `.env` file in the `assets/` directory with the following variables:

   FIREBASE_API_KEY=your_api_key
   FIREBASE_AUTH_DOMAIN=your_auth_domain
   FIREBASE_PROJECT_ID=your_project_id
   FIREBASE_STORAGE_BUCKET=your_storage_bucket
   FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   FIREBASE_APP_ID=your_app_id
   NEWS_API_KEY=your_news_api_key

2. For local development with Firebase Emulator:

   USE_FIREBASE_EMULATOR=true
   FIREBASE_EMULATOR_HOST=localhost

3. Configure social authentication:
   - Google Sign-In: Add your OAuth client IDs
   - Apple Sign-In: Configure in Apple Developer Console

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run specific test file
flutter test test/update_service_test.dart
```

## 🚀 Building for Production

### Android ###.

<!-- bash -->
# Debug APK ###.

flutter build apk --debug

# Release APK

flutter build apk --release

# App Bundle for Play Store ###.

flutter build appbundle --release

### iOS ###.

<!-- bash -->
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- Firebase for the robust backend services
- All open-source contributors of the packages used

## 🔧 Troubleshooting

### Common Issues

1. **Build failures**: Run `flutter clean && flutter pub get`
2. **Firebase connection issues**: Verify configuration files are in correct locations
3. **News not loading**: Check API keys and network connectivity
4. **Update checks failing**: Ensure proper store configuration

### Performance Optimization

- Enable R8/ProGuard for Android release builds
- Use `flutter build` with `--split-per-abi` for smaller APKs
- Implement proper image caching and lazy loading
- Monitor app performance with Firebase Performance

## 📧 Support

For support and questions:

- Create an issue in the repository
- Check existing documentation files:
  - `APPLE_DEPLOYMENT.md` - iOS deployment guide
  - `FCM_MIGRATION_GUIDE.md` - Push notification setup
  - `NEWS_SETUP.md` - News integration guide
  - `SOCIAL_AUTH_SETUP.md` - Social authentication setup

Project Link: [https://github.com/yourusername/task](https://github.com/yourusername/task)
