// utils/constants/app_constants.dart

/// Application-wide constants for consistent configuration
class AppConstants {
  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;

  // Network & Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(minutes: 2);

  // Retry Logic
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Animation & UI
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Snackbar & Notifications
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration longSnackbarDuration = Duration(seconds: 5);

  // Cache & Storage
  static const Duration cacheExpiryDuration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'txt'
  ];

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;

  // Task Management
  static const int maxTaskTitleLength = 200;
  static const int maxTaskDescriptionLength = 2000;
  static const int maxCommentsPerTask = 100;
  static const int maxTagsPerTask = 10;

  // User Roles (for validation)
  static const List<String> validUserRoles = [
    'Reporter',
    'Cameraman',
    'Driver',
    'Librarian',
    'Assignment Editor',
    'Head of Department',
    'Head of Unit',
    'Admin',
    'News Director',
    'Assistant News Director',
    'Producer',
    'Anchor',
    'Business Reporter',
    'Political Reporter',
    'Digital Reporter',
    'Web Producer'
  ];

  // Task Status Values
  static const List<String> taskStatusValues = [
    'Pending',
    'In Progress',
    'Completed',
    'Cancelled',
    'Archived'
  ];

  // Task Priority Values
  static const List<String> taskPriorityValues = [
    'Low',
    'Normal',
    'High',
    'Urgent'
  ];

  // Approval Status Values
  static const List<String> approvalStatusValues = [
    'pending',
    'approved',
    'rejected'
  ];

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';
  static const String notificationsCollection = 'notifications';
  static const String adminsCollection = 'admins';

  // Shared Preferences Keys
  static const String themePreferenceKey = 'theme_preference';
  static const String languagePreferenceKey = 'language_preference';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String lastLoginKey = 'last_login';
  static const String cacheTimestampKey = 'cache_timestamp';

  // Environment Variables
  static const String firebaseProjectIdKey = 'FIREBASE_PROJECT_ID';
  static const String firebaseRtdbUrlKey = 'FIREBASE_RTDB_URL';
  static const String apiBaseUrlKey = 'API_BASE_URL';

  // Regular Expressions
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phoneRegex = r'^\+?[\d\s\-\(\)]{10,}$';

  // Default Values
  static const String defaultUserRole = 'Reporter';
  static const String defaultTaskStatus = 'Pending';
  static const String defaultTaskPriority = 'Normal';
  static const String defaultApprovalStatus = 'pending';

  // Layout & Responsive Design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Error Messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String timeoutErrorMessage =
      'Request timed out. Please try again.';
  static const String unauthorizedErrorMessage =
      'You do not have permission to perform this action.';
  static const String validationErrorMessage =
      'Please check your input and try again.';
}

/// Firebase configuration constants
class FirebaseConstants {
  static const String emulatorHost = '192.168.1.7';
  static const int firestorePort = 8003;
  static const int authPort = 8002;
  static const int functionsPort = 8001;
  static const int storagePort = 8005;

  // Default database URL (can be overridden by environment)
  static const String defaultDatabaseUrl =
      'https://task-e5a96-default-rtdb.firebaseio.com';
}

/// API Endpoints (for future use)
class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const String tasks = '/tasks';
  static const String users = '/users';
  static const String notifications = '/notifications';
  static const String reports = '/reports';
  static const String news = '/news';
  static const String weather = '/weather';
}

/// External URLs and Links
class ExternalUrls {
  // Firebase Realtime Database URL
  static const String firebaseRtdbUrl = 'https://task-e5a96-default-rtdb.firebaseio.com';

  // Privacy and Legal URLs (should be configured via environment in production)
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://your-company.com/privacy-policy',
  );
  static const String termsOfServiceUrl = String.fromEnvironment(
    'TERMS_OF_SERVICE_URL',
    defaultValue: 'https://your-company.com/terms-of-service',
  );
  static const String dataProtectionUrl = String.fromEnvironment(
    'DATA_PROTECTION_URL',
    defaultValue: 'https://your-company.com/data-protection',
  );

  // App Store URLs
  static const String appStoreBaseUrl = 'https://apps.apple.com/app/id';
  static const String appStoreReviewUrl = 'https://apps.apple.com/app/id%1?action=write-review';

  // Version Check URL
  static const String versionCheckUrl = String.fromEnvironment(
    'VERSION_CHECK_URL',
    defaultValue: 'https://your-api.com/version-check',
  );

  // Email Link Authentication URL
  static const String emailLinkAuthUrl = 'https://task-app.firebaseapp.com/email-link-signin';
}

/// Feature Flags (for A/B testing or gradual rollouts)
class FeatureFlags {
  static const bool enableAdvancedNotifications = true;
  static const bool enableOfflineMode = true;
  static const bool enableTaskTemplates = false;
  static const bool enableAnalytics = true;
  static const bool enablePerformanceMonitoring = true;
}

/// Layout & Responsive Design Constants
class LayoutConstants {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Common Border Radius Values
  static const double borderRadiusSmall = 4;
  static const double borderRadiusMedium = 8;
  static const double borderRadiusLarge = 12;
  static const double borderRadiusExtraLarge = 16;
  static const double borderRadiusDialog = 24;

  // Common Padding Values
  static const double paddingSmall = 4;
  static const double paddingMedium = 8;
  static const double paddingLarge = 16;
  static const double paddingExtraLarge = 24;

  // Common Margin Values
  static const double marginSmall = 4;
  static const double marginMedium = 8;
  static const double marginLarge = 16;
  static const double marginExtraLarge = 24;

  // Common Border Widths
  static const double borderWidthThin = 0.5;
  static const double borderWidthMedium = 1;
  static const double borderWidthThick = 2;
}

/// Animation & Duration Constants
class AnimationConstants {
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationExtraSlow = Duration(milliseconds: 1000);

  // Snackbar durations
  static const Duration snackbarShort = Duration(seconds: 3);
  static const Duration snackbarLong = Duration(seconds: 5);

  // Network timeouts
  static const Duration networkTimeoutShort = Duration(seconds: 10);
  static const Duration networkTimeoutMedium = Duration(seconds: 30);
  static const Duration networkTimeoutLong = Duration(minutes: 2);

  // Debounce delays
  static const Duration debounceShort = Duration(milliseconds: 300);
  static const Duration debounceMedium = Duration(milliseconds: 500);
  static const Duration debounceLong = Duration(seconds: 1);

  // Retry delays
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration retryDelayLong = Duration(seconds: 2);
}

/// UI Spacing Constants
class SpacingConstants {
  static const double spacingXS = 2;
  static const double spacingSM = 4;
  static const double spacingMD = 8;
  static const double spacingLG = 16;
  static const double spacingXL = 24;
  static const double spacingXXL = 32;

  // Icon sizes
  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 20;
  static const double iconSizeLarge = 24;
  static const double iconSizeExtraLarge = 32;

  // Text sizes (relative)
  static const double textScaleSmall = 0.875;
  static const double textScaleMedium = 1.0;
  static const double textScaleLarge = 1.125;
  static const double textScaleExtraLarge = 1.25;
}

/// Dialog & Modal Constants
class DialogConstants {
  static const double dialogWidthRatio = 0.9;
  static const double dialogHeightRatio = 0.8;
  static const double dialogMaxWidth = 500;
  static const double dialogBorderRadius = 24;

  // Bottom sheet ratios
  static const double bottomSheetInitialRatio = 0.5;
  static const double bottomSheetMinRatio = 0.3;
  static const double bottomSheetMaxRatio = 0.9;
}
