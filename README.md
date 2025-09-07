# Task Management Application

A comprehensive task management and news application built with Flutter and Firebase, featuring real-time collaboration, integrated news feeds, multi-language support, and cross-platform compatibility. Designed to streamline workflow and enhance productivity across different roles including Admin, Assignment Editors, Librarians, Reporters, Cameramen, and Drivers.

## 📱 Features

### 🔐 Authentication & User Management

- **Multi-method Authentication**: Email/password, Google Sign-In, Apple Sign-In, and email link authentication
- **Biometric Security**: Fingerprint and face recognition with app lock functionality
- **Role-based Access Control**: Admin, Librarian, Reporter, Cameraman, Driver roles with specific permissions
- **Profile Management**: Complete user profiles with photo upload, contact information, and role assignment
- **Admin User Management**: Create, edit, delete users, assign roles, and manage user permissions
- **Presence System**: Real-time user online/offline status tracking
- **Account Security**: Password reset, email verification, and secure session management

### 📋 Advanced Task Management

- **Task Creation & Assignment**: Create detailed tasks with multiple assignee types (Reporter, Cameraman, Driver, Librarian)
- **Real-time Collaboration**: Live task updates, comments, and status changes across all users
- **Task Approval System**: Admin approval workflow for task creation and modifications
- **Advanced Filtering**: Filter by status, priority, category, assigned user, and date ranges
- **Task Categories**: 25+ predefined categories including Political, Sports, Breaking News, Feature Story, etc.
- **Priority Management**: Low, Medium, High, Normal priority levels with visual indicators
- **Due Date Tracking**: Interactive calendar with overdue task alerts and reminders
- **File Attachments**: Support for images, documents, videos with size and type tracking
- **Task Analytics**: Performance metrics, completion rates, and user productivity tracking
- **Bulk Operations**: Mass task operations for efficient management
- **Task Archiving**: Archive completed tasks with metadata and retrieval options
- **Search & Pagination**: Advanced search with pagination for large task datasets

### 📚 Specialized Library Management

- **Librarian Dashboard**: Dedicated interface for library-specific tasks
- **Resource Management**: Catalog and track library resources and materials
- **Task Detail Views**: Specialized task detail screens for librarian workflows
- **Integration**: Seamless integration with main task management system

### 📊 Comprehensive Admin Dashboard

- **Real-time Statistics**: Live dashboard with user counts, task metrics, and system health
- **User Management**: Complete user lifecycle management with role assignments
- **Task Oversight**: View all tasks, approve/reject submissions, and monitor progress
- **Performance Analytics**: User performance tracking with detailed metrics and reports
- **System Monitoring**: Online user tracking, conversation monitoring, and activity logs
- **Quarterly Transitions**: Automated quarterly data transitions and reporting
- **Export Capabilities**: PDF and Excel export for reports and data analysis

### 📰 Multi-Source News Integration

- **News Aggregation**: BBC, CNN, Al Jazeera, Reuters, TVC News, Africa News integration
- **Real-time Updates**: Live news feeds with automatic refresh and notifications
- **Category Filtering**: Filter news by categories and sources
- **Search Functionality**: Search across all news sources with keyword matching
- **Offline Reading**: Cached articles for offline access
- **News Cards**: Dedicated UI components for each news source with branding
- **URL Launching**: In-app browser for seamless news reading experience

### 🔔 Advanced Notification System

- **Firebase Cloud Messaging**: Push notifications for all platforms
- **Smart Notifications**: Context-aware notifications based on user role and tasks
- **Daily Task Reminders**: Automated daily task summary notifications
- **Real-time Alerts**: Instant notifications for task assignments, updates, and deadlines
- **Notification Management**: User-controlled notification preferences and settings
- **Background Processing**: Handle notifications even when app is closed

### 💬 Real-time Chat System

- **Direct Messaging**: One-on-one conversations between team members
- **Chat Lists**: Organized conversation management with recent activity
- **Real-time Sync**: Instant message delivery and read receipts
- **User Discovery**: Find and start conversations with team members
- **Message History**: Persistent chat history with Firestore integration

### 🌐 Comprehensive Multi-language Support

- **5 Languages**: English, French, Hausa, Yoruba, Igbo with complete translations
- **Dynamic Switching**: Change language without app restart
- **Localized UI**: All interface elements, messages, and content localized
- **Cultural Adaptation**: Region-specific formatting and cultural considerations
- **RTL Support**: Right-to-left text support where applicable

### 📱 Smart Update Management

- **Platform-specific Updates**: Android In-App Updates and iOS App Store integration
- **Update Detection**: Automatic version checking with manual override options
- **Flexible Updates**: User choice between immediate and flexible update modes
- **Update Notifications**: Smart prompts and notifications for available updates
- **Version Control**: Track app versions and update history

### 🔒 Security & Privacy

- **App Lock**: Biometric and PIN-based app locking with timeout settings
- **Privacy Controls**: Comprehensive privacy settings and data management
- **Secure Storage**: Encrypted local storage for sensitive data
- **Access Control**: Role-based permissions and feature restrictions
- **Data Protection**: GDPR-compliant data handling and user rights

### 🎨 Customization & User Experience

- **Dynamic Theming**: Light/dark mode with system preference detection
- **Custom Wallpapers**: Personalized backgrounds and visual customization
- **Responsive Design**: Optimized for all screen sizes and orientations
- **Accessibility**: Screen reader support, high contrast, and accessibility features
- **Performance Optimization**: Image caching, lazy loading, and memory management
- **Offline Capabilities**: Local data persistence with automatic sync when online

### 📈 Analytics & Performance

- **User Performance Tracking**: Detailed metrics on task completion and productivity
- **Team Analytics**: Quarter-based performance analysis and reporting
- **System Metrics**: App usage statistics, error tracking, and performance monitoring
- **Export Features**: Generate PDF reports and Excel exports for analysis
- **Real-time Dashboards**: Live performance indicators and system health metrics

## 🛠️ Tech Stack

### Frontend

- **Framework**: Flutter (latest stable) with Dart
- **State Management**: GetX for reactive state management
- **UI Framework**: Material Design with custom theming and ScreenUtil for responsive design
- **Local Database**: SQLite with sqflite for offline data persistence
- **Image Handling**: cached_network_image, image_picker, file_picker
- **Authentication**: local_auth for biometric authentication
- **Internationalization**: flutter_localizations with GetX translations
- **Updates**: in_app_update, package_info_plus for version management
- **PDF Generation**: pdf package for report generation
- **Audio**: audioplayers for audio functionality
- **Networking**: http, dio for API communications
- **Utilities**: intl for date formatting, shared_preferences for local storage
- **Reactive Programming**: rxdart for advanced stream operations

### Backend & Services

- **Authentication**: Firebase Authentication with multi-provider support
- **Database**: Cloud Firestore with real-time synchronization and offline support
- **File Storage**: Firebase Storage for user avatars and task attachments
- **Push Notifications**: Firebase Cloud Messaging (FCM) with background handling
- **Cloud Functions**: Firebase Cloud Functions for server-side operations
- **News Integration**: Multiple news APIs (BBC, CNN, Al Jazeera, Reuters, TVC, Africa News)
- **Analytics**: Firebase Analytics for user behavior tracking
- **Performance**: Firebase Performance Monitoring
- **Crashlytics**: Firebase Crashlytics for error reporting

### Key Services Architecture

- **Task Service**: Comprehensive task management with real-time updates
- **User Management**: Complete user lifecycle and role management
- **Notification Service**: Smart notification system with FCM integration
- **Export Service**: PDF and Excel export capabilities
- **Update Service**: Platform-specific update management (Android/iOS)
- **Presence Service**: Real-time user online/offline tracking
- **Archive Service**: Task archiving and data management
- **Bulk Operations**: Mass operations for administrative tasks
- **Analytics Service**: Performance tracking and reporting
- **Biometric Service**: Secure biometric authentication
- **Connectivity Service**: Network status monitoring
- **Version Control**: App version management and update detection

### Development Tools

- **Flutter SDK**: Latest stable version
- **Development IDEs**: Android Studio, VS Code, Xcode
- **Firebase CLI**: For backend management and deployment
- **Flutter DevTools**: For debugging and performance analysis
- **Git**: Version control with GitHub integration

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=2.17.0)
- Android Studio / VS Code with Flutter extensions
- Firebase account with billing enabled (for advanced features)
- iOS development setup (Xcode for iOS builds)
- Git for version control

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/danielcyudoncy/task
   cd task
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable the following services:
     - **Authentication** (Email/Password, Google, Apple Sign-In)
     - **Cloud Firestore** (for data storage)
     - **Cloud Messaging** (for push notifications)
     - **Cloud Storage** (for file uploads)
     - **Analytics** (for performance tracking)
   - Download configuration files:
     - `google-services.json` for Android → place in `android/app/`
     - `GoogleService-Info.plist` for iOS → place in `ios/Runner/`
   - Configure Firebase rules for security

4. **Environment Configuration**
   - Copy `.env.example` to `.env`
   - Configure your environment variables:
     FIREBASE_API_KEY=your_api_key
     NEWS_API_KEY=your_news_api_key
     ENCRYPTION_KEY=your_encryption_key
   - Set up news API keys for external news sources
   - Configure social authentication (Google, Apple)

5. **Platform-specific Setup**
   **Android:**
   - Ensure minimum SDK version 24 in `android/app/build.gradle`
   - Configure ProGuard rules for release builds

   **iOS:**
   - Set minimum deployment target to iOS 12.0
   - Configure App Transport Security in `Info.plist`
   - Add required permissions for biometric authentication

6. **Run the app**

   ```bash
   # Development mode
   flutter run
   
   # Release mode
   flutter run --release
   
   # Specific platform
   flutter run -d android
   flutter run -d ios
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
├── controllers/              # State management and business logic
│   ├── admin_controller.dart         # Admin dashboard and user management
│   ├── auth_controller.dart          # Authentication and user sessions
│   ├── chat_controller.dart          # Real-time messaging
│   ├── task_controller.dart          # Task management and operations
│   ├── performance_controller.dart   # User performance analytics
│   ├── notification_controller.dart  # Push notifications
│   ├── theme_controller.dart         # Theme and appearance
│   ├── settings_controller.dart      # App settings and preferences
│   └── manage_users_controller.dart  # User management operations
│
├── core/                     # Core app functionality
│   ├── bootstrap.dart               # App initialization and setup
│   └── app_config.dart             # Configuration management
│
├── features/                 # Feature-specific modules
│   └── librarian/                  # Librarian-specific functionality
│       ├── widgets/                # Librarian UI components
│       └── controllers/            # Librarian business logic
│
├── models/                   # Data models and entities
│   ├── task_model.dart             # Task entity with full lifecycle
│   ├── chat_model.dart             # Chat and messaging models
│   ├── task_filters.dart           # Task filtering options
│   ├── task_status_filter.dart     # Status filtering
│   └── report_completion_info.dart # Task completion tracking
│
├── routes/                   # Navigation and routing
│   ├── app_routes.dart             # Route definitions and middleware
│   └── middleware/                 # Authentication and access control
│
├── service/                  # Backend services and integrations
│   ├── firebase_service.dart       # Core Firebase operations
│   ├── fcm_service.dart            # Push notification service
│   ├── news_service.dart           # News aggregation service
│   ├── task_service.dart           # Task management service
│   ├── export_service.dart         # PDF/Excel export functionality
│   ├── update_service.dart         # App update management
│   ├── android_update_service.dart # Android-specific updates
│   ├── ios_update_service.dart     # iOS-specific updates
│   ├── presence_service.dart       # User presence tracking
│   ├── analytics_service.dart      # Performance analytics
│   ├── biometric_service.dart      # Biometric authentication
│   ├── archive_service.dart        # Task archiving
│   ├── bulk_operations_service.dart # Mass operations
│   ├── connectivity_service.dart   # Network monitoring
│   ├── version_service.dart        # Version management
│   └── user_deletion_service.dart  # User account deletion
│
├── utils/                    # Utilities and helpers
│   ├── constants/                  # App constants and configurations
│   ├── localization/              # Multi-language support
│   ├── themes/                     # Theme configurations
│   ├── validators/                 # Input validation
│   ├── snackbar_utils.dart        # Notification utilities
│   └── devices/                    # Device-specific utilities
│
├── views/                    # UI screens and pages
│   ├── home_screen.dart            # Main dashboard
│   ├── admin_dashboard_screen.dart # Admin control panel
│   ├── task_creation_screen.dart   # Task creation interface
│   ├── task_list_screen.dart       # Task listing and management
│   ├── chat_screen.dart            # Messaging interface
│   ├── chat_list_screen.dart       # Conversation list
│   ├── news_screen.dart            # News aggregation
│   ├── performance/                # Performance tracking screens
│   │   ├── performance_screen.dart
│   │   └── user_performance_details_screen.dart
│   ├── profile_screen.dart         # User profile management
│   ├── settings_screen.dart        # App settings
│   ├── privacy_screen.dart         # Privacy controls
│   ├── notification_screen.dart    # Notification management
│   ├── wallpaper_screen.dart       # Customization options
│   └── auth screens/               # Authentication flows
│
└── widgets/                  # Reusable UI components
    ├── app_drawer.dart             # Navigation drawer
    ├── task_section.dart           # Task display components
    ├── user_dashboard_cards_widget.dart # Dashboard cards
    ├── enhanced_dashboard_cards.dart # Advanced dashboard UI
    ├── news/                       # News-specific widgets
    │   ├── news_sources_carousel.dart
    │   └── news_category_filter.dart
    ├── dialogs/                    # Modal dialogs
    └── tabs/                       # Tab-based interfaces

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

Project Link: [https://github.com/danielcyudoncy/task](https://github.com/danielcyudoncy/task)
