// widgets/save_success_screen.dart
// views/save_success_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/utils/constants/app_icons.dart';

class SaveSuccessScreen extends StatefulWidget {
  const SaveSuccessScreen({super.key});

  @override
  State<SaveSuccessScreen> createState() => _SaveSuccessScreenState();
}

class _SaveSuccessScreenState extends State<SaveSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Removed timer-based auto-navigation. Navigation is now only via the home button.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).canvasColor
              : Theme.of(context).colorScheme.primary,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back arrow if needed
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: colorScheme.onPrimary,
                  onPressed: () {
                    Get.find<SettingsController>().triggerFeedback();
                    Get.back();
                  },
                ),
              ),
              const SizedBox(height: 16),
              // App logo
              Image.asset(
                AppIcons.logo,
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 24),
              // Success card
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (!isDark)
                          const BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 100,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Changes Saved\nsuccessfully',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'Raleway',
                            color: textTheme.headlineMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Add Go to Home button
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: colorScheme.onPrimary,
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final auth = Get.find<AuthController>();
                      final role = auth.userRole.value;
                      if (["Admin", "Assignment Editor", "Head of Department"].contains(role)) {
                        Get.offAllNamed("/admin-dashboard");
                      } else if (["Reporter", "Cameraman"].contains(role)) {
                        Get.offAllNamed("/home");
                      } else {
                        Get.offAllNamed("/login");
                      }
                    });
                  },
                  child: Text(
                    "Go to Home",
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Raleway',
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
