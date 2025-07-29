# Task Management Application

A comprehensive task management and collaboration platform built with Flutter and Firebase, designed to streamline workflow and enhance productivity across different roles including Admin, Assignment Editors, Librarians, Reporters, and more.

## 📱 Features

### 🔐 Authentication & User Management
- Secure email/password authentication with Firebase Auth
- Role-based access control (Admin, Librarian, Reporter, etc.)
- User profile management
- Admin user management

### 📋 Task Management
- Create, assign, and track tasks
- Task categorization and prioritization
- Due date tracking with calendar view
- Task status updates

### 📚 Library Management (For Librarians)
- Book and resource management
- Check-in/Check-out system
- Resource categorization

### 📊 Admin Dashboard
- User management
- Role assignment
- System analytics and reports
- Activity monitoring

### 🔔 Real-time Notifications
- Task assignments and updates
- Due date reminders
- System announcements

### 🌐 Offline Support
- Local data persistence with Isar database
- Sync when back online
- Offline task creation and editing

### 🎨 Customization
- Theme support (light/dark mode)
- Customizable dashboard
- User preferences

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter
- **State Management**: GetX
- **UI Components**: Material Design with custom theming
- **Local Database**: Isar
- **PDF Generation**: pdf package

### Backend
- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore
- **File Storage**: Firebase Storage
- **Hosting**: Firebase Hosting
- **Functions**: Firebase Cloud Functions

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
   - Add Android/iOS apps to your Firebase project
   - Download the configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS
   - Place these files in their respective platform directories

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── controllers/      # Business logic and state management
├── core/            # Core functionality and utilities
├── features/        # Feature modules
│   ├── admin/       # Admin-specific features
│   ├── auth/        # Authentication flows
│   ├── home/        # Main app screens
│   ├── librarian/   # Librarian features
│   └── tasks/       # Task management
├── models/          # Data models
├── routes/          # App navigation routes
├── service/         # Services and APIs
├── theme/           # App theming
├── utils/           # Helper functions and constants
├── views/           # UI components
└── widgets/         # Reusable widgets
```

## 🔧 Environment Setup

1. Create a `.env` file in the root directory with the following variables:
   ```
   FIREBASE_API_KEY=your_api_key
   FIREBASE_AUTH_DOMAIN=your_auth_domain
   FIREBASE_PROJECT_ID=your_project_id
   FIREBASE_STORAGE_BUCKET=your_storage_bucket
   FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   FIREBASE_APP_ID=your_app_id
   ```

2. For local development with Firebase Emulator, set:
   ```
   USE_FIREBASE_EMULATOR=true
   FIREBASE_EMULATOR_HOST=your_emulator_host
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

## 📧 Contact

[Your Name] - [Your Email]
Project Link: [https://github.com/yourusername/task](https://github.com/yourusername/task)
