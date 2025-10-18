// routes/app_routes.dart
import 'package:get/get.dart';
import 'package:task/routes/middleware.dart';
import 'package:task/routes/profile_complete_middleware.dart';
import 'package:task/screens/admin_dashboard_screen.dart';
import 'package:task/screens/all_task_screen.dart';
import 'package:task/screens/chat_list_screen.dart';
import 'package:task/screens/forget_password_screen.dart';
import 'package:task/screens/home_screen.dart';
import 'package:task/features/librarian/screens/librarian_dashboard_screen.dart';
import 'package:task/screens/login_screen.dart';
import 'package:task/screens/manage_users_screen.dart';
import 'package:task/screens/notification_screen.dart';
import 'package:task/screens/privacy_screen.dart';
import 'package:task/screens/privacy_policy_screen.dart';
import 'package:task/screens/profile_screen.dart';
import 'package:task/screens/profile_update_screen.dart';
import 'package:task/screens/settings_screen.dart';
import 'package:task/screens/signup_screen.dart';
import 'package:task/screens/splash_screen.dart';
import 'package:task/screens/task_assignment_screen.dart';
import 'package:task/screens/task_creation_screen.dart';
import 'package:task/screens/task_list_screen.dart';
import 'package:task/screens/onboarding_screen.dart';
import 'package:task/screens/user_list_screen.dart';
import 'package:task/screens/news_screen.dart';
import 'package:task/screens/all_users_chat_screen.dart';
import 'package:task/screens/notification_fix_screen.dart';
import 'package:task/screens/email_link_signin_screen.dart';
import 'package:task/screens/app_lock_screen.dart';
import 'package:task/widgets/save_success_screen.dart';
import 'package:task/screens/performance/performance_screen.dart';
import 'package:task/screens/route_handler_screen.dart';

class AppRoutes {
  static final routes = [
    // Public routes
    GetPage(
      name: "/",
      page: () => const SplashScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/onboarding",
      page: () => OnboardingScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/login",
      page: () => const LoginScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/signup",
      page: () => SignUpScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/email-link-signin",
      page: () => const EmailLinkSignInScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/app-lock",
      page: () => const AppLockScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/route-handler",
      page: () => const RouteHandlerScreen(),
      middlewares: [AuthMiddleware()],
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 100),
    ),
    // Protected routes
    GetPage(
      name: "/home",
      page: () => const HomeScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/profile-update",
      page: () => ProfileUpdateScreen(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/admin-dashboard",
      page: () => const AdminDashboardScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: "/profile",
      page: () => ProfileScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/settings",
      page: () => SettingsScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    GetPage(
      name: "/privacy",
      page: () => const PrivacyScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/privacy-policy",
      page: () => const PrivacyPolicyScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/all-tasks",
      page: () => const AllTaskScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/forgot-password",
      page: () => ForgotPasswordScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/manage-users",
      page: () => ManageUsersScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/tasks",
      page: () => TaskListScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/task-assignment",
      page: () => TaskAssignmentScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/chat-list",
      page: () => const ChatListScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/user-list",
      page: () => const UserListScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/create-task",
      page: () => const TaskCreationScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    GetPage(
      name: "/notifications",
      page: () => NotificationScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/notification-fix",
      page: () => const NotificationFixScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/all-users-chat",
      page: () => const AllUsersChatScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: "/news",
      page: () => const NewsScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/save-success",
      page: () => const SaveSuccessScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/librarian-dashboard",
      page: () => const LibrarianDashboardScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: "/performance",
      page: () => const PerformanceScreen(),
      middlewares: [
        AuthMiddleware(),
        ProfileCompleteMiddleware(),
      ],
      transition: Transition.fadeIn,
    ),
  ];
}
