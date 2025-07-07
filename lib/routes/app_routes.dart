// routes/app_routes.dart
import 'package:get/get.dart';
import 'package:task/routes/global_bindings.dart';
import 'package:task/routes/middleware.dart';
import 'package:task/routes/profile_complete_middleware.dart';
import 'package:task/views/admin_dashboard_screen.dart';
import 'package:task/views/all_task_screen.dart';
import 'package:task/views/chat_list_screen.dart';
import 'package:task/views/forget_password_screen.dart';
import 'package:task/views/home_screen.dart';
import 'package:task/views/login_screen.dart';
import 'package:task/views/manage_users_screen.dart';
import 'package:task/views/notification_screen.dart';
import 'package:task/views/privacy_screen.dart';
import 'package:task/views/profile_screen.dart';
import 'package:task/views/profile_update_screen.dart';
import 'package:task/views/settings_screen.dart';
import 'package:task/views/signup_screen.dart';
import 'package:task/views/splash_screen.dart';
import 'package:task/views/task_assignment_screen.dart';
import 'package:task/views/task_creation_screen.dart';
import 'package:task/views/task_list_screen.dart';
import 'package:task/views/onboarding_screen.dart';
import 'package:task/views/user_list_screen.dart';
import 'package:task/views/news_screen.dart';
import 'package:task/views/all_users_chat_screen.dart';
import 'package:task/widgets/save_success_screen.dart';

class AppRoutes {
  static final routes = [
    // Public routes
    GetPage(
      name: "/",
      page: () => const SplashScreen(),
      binding: GlobalBindings(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/onboarding",
      page: () => const OnboardingScreen(),
      binding: GlobalBindings(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/login",
      page: () => LoginScreen(),
      binding: GlobalBindings(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/signup",
      page: () => SignUpScreen(),
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    // Protected routes
    GetPage(
      name: "/home",
      page: () => const HomeScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/profile-update",
      page: () => ProfileUpdateScreen(),
      middlewares: [AuthMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/admin-dashboard",
      page: () => const AdminDashboardScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: "/profile",
      page: () => ProfileScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/settings",
      page: () => SettingsScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/privacy",
      page: () => const PrivacyScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/all-tasks",
      page: () => const AllTaskScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/forgot-password",
      page: () =>  ForgotPasswordScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/manage-users",
      page: () => ManageUsersScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/tasks",
      page: () => TaskListScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/task-assignment",
      page: () => TaskAssignmentScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/chat-list",
      page: () =>  const ChatListScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
     GetPage(
      name: "/user-list",
      page: () => const UserListScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/create-task",
      page: () => const TaskCreationScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    
    GetPage(
      name: "/notifications",
      page: () => NotificationScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/all-users-chat",
      page: () => const AllUsersChatScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: "/news",
      page: () => const NewsScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: "/save-success",
      page: () => const SaveSuccessScreen(),
      binding: GlobalBindings(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
  ];
}
