// views/settings_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/app_lock_controller.dart';
import '../controllers/auth_controller.dart';
import '../utils/localization/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController settingsController = Get.find<SettingsController>();
  final ThemeController themeController = Get.find<ThemeController>();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'settings'.tr,
          style: TextStyle(
            fontFamily: 'raleway',
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 30.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          // Add safety check to ensure controllers are registered
          if (!Get.isRegistered<ThemeController>() || !Get.isRegistered<SettingsController>()) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 10),
                      child: Image.asset(
                        'assets/png/logo.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                  sectionTitle(context, "App Preferences"),
                  // App Preferences
                  // Only ThemeController manages dark mode. Do not use SettingsController for theme.
                  Obx(() {
                    // Add safety check to ensure controller is registered
                    if (!Get.isRegistered<ThemeController>()) {
                      return settingsSwitchTile(
                        context,
                        "Dark Mode",
                        "Activate dark background for app",
                        false,
                        (value) {},
                      );
                    }
                    
                    return settingsSwitchTile(
                      context,
                      "Dark Mode",
                      "Activate dark background for app",
                      themeController.isDarkMode.value,
                      (value) {
                        themeController.toggleTheme(value);
                      },
                    );
                  }),
                  sectionTitle(context, 'sound_and_vibration'.tr),
                  settingsSwitchTile(
                    context,
                    'sounds'.tr,
                    'enable_sound'.tr,
                    settingsController.isSoundEnabled.value,
                    (value) {
                      settingsController.toggleSound(value);
                      settingsController.saveSettings();
                    },
                  ),
                  settingsSwitchTile(
                    context,
                    'Enable Biometric Login',
                    'Use fingerprint or face to login',
                    settingsController.isBiometricEnabled.value,
                    (value) {
                      settingsController.toggleBiometric(value);
                    },
                  ),
                  sectionTitle(context, 'App Security'),
                  _buildAppLockSettings(context),
                  settingsSwitchTile(
                    context,
                    'vibration'.tr,
                    'enable_disable_vibration'.tr,
                    settingsController.isVibrationEnabled.value,
                    (value) {
                      settingsController.toggleVibration(value);
                      settingsController.saveSettings();
                    },
                  ),
                  sectionTitle(context, 'account_preferences'.tr),
                  settingsDropdownTile(
                    context,
                    'language'.tr,
                    settingsController.selectedLanguage.value,
                    [
                      'English (Default)',
                      'French',
                      'Hausa',
                      'Yoruba',
                      'Igbo'
                    ],
                    (lang) {
                      settingsController.setLanguage(lang);
                      settingsController.saveSettings();
                    },
                  ),
                  // Warning message for unsupported languages
                  if (!AppLocalizations.isLanguageFullySupported(settingsController.selectedLanguage.value))
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'unsupported_language_note'.trParams({'language': settingsController.selectedLanguage.value}),
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  sectionTitle(context, 'sync_settings'.tr),
                  settingsSwitchTile(
                    context,
                    'synchronize_data'.tr,
                    "",
                    settingsController.isSyncEnabled.value,
                    (value) {
                      settingsController.toggleSync(value);
                      settingsController.saveSettings();
                    },
                  ),
                  // Debug section for theme issues
                  if (kDebugMode) ...[
                    sectionTitle(context, "Debug Options"),
                    ListTile(
                      title: Text(
                        "Reset Theme to Light",
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        "Force reset theme to light mode",
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
                        onPressed: () {
                          themeController.resetToDefaultTheme();
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  saveButton(settingsController),
                  const SizedBox(height: 30),
                  nextPageButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget sectionTitle(BuildContext context, String title) => Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(top: 18, bottom: 6),
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );

  Widget settingsSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 0, right: 0),
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 13),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Theme.of(context).colorScheme.secondary,
          inactiveThumbColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
          inactiveTrackColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.24),
        ),
      ),
    );
  }

  Widget settingsDropdownTile(
    BuildContext context,
    String title,
    String selected,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 0, right: 0),
        title: Text(title,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500)),
        trailing: DropdownButton<String>(
          value: selected,
          dropdownColor: Theme.of(context).colorScheme.primary,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w400),
          underline: Container(),
          items: options
              .map((lang) => DropdownMenuItem(
                    value: lang,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(lang),
                        if (!AppLocalizations.isLanguageFullySupported(lang)) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.orange,
                          ),
                        ],
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (String? value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget saveButton(SettingsController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F80ED),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: () async {
          await controller.triggerFeedback();
          await controller.saveSettings();

          Get.snackbar(
            'settings_saved'.tr,
            'preferences_updated'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.grey[900],
            colorText: Colors.white,
          );
        },
        child: Text(
          'save'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
    );
  }

  Widget nextPageButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF2F80ED), width: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {
          Get.toNamed('/privacy');
        },
        child: Text('next_privacy_settings'.tr,
            style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildAppLockSettings(BuildContext context) {
    final AppLockController appLockController = Get.find<AppLockController>();
    
    return Obx(() => Column(
      children: [
        settingsSwitchTile(
          context,
          'Enable App Lock',
          'Require PIN or biometric to unlock app',
          appLockController.isAppLockEnabled.value,
          (value) async {
            if (value) {
              await _showSetPinDialog(context, appLockController);
            } else {
              await appLockController.toggleAppLock(false);
            }
          },
        ),
        if (appLockController.isAppLockEnabled.value) ...[
          ListTile(
            contentPadding: const EdgeInsets.only(left: 0, right: 0),
            title: Text(
              'Change PIN',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Update your app lock PIN',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 13,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 16,
            ),
            onTap: () => _showSetPinDialog(context, appLockController),
          ),
        ],
      ],
    ));
  }

  Future<void> _showSetPinDialog(BuildContext context, AppLockController appLockController) async {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();
    final RxString errorMessage = ''.obs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF23243A),
                      const Color(0xFF181B2A),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF8F9FA),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4A90E2),
                      const Color(0xFF357088),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Set App Lock PIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Obx(() => Column(
                  children: [
                    // PIN Input Field
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF2A2B3D),
                                  const Color(0xFF1E1F2E),
                                ]
                              : [
                                  const Color(0xFFF8F9FA),
                                  const Color(0xFFE9ECEF),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: pinController,
                        decoration: InputDecoration(
                          labelText: 'Enter 4-digit PIN',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterText: '',
                          prefixIcon: Icon(
                            Icons.pin,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        onChanged: (value) {
                          errorMessage.value = '';
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Confirm PIN Input Field
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF2A2B3D),
                                  const Color(0xFF1E1F2E),
                                ]
                              : [
                                  const Color(0xFFF8F9FA),
                                  const Color(0xFFE9ECEF),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: confirmPinController,
                        decoration: InputDecoration(
                          labelText: 'Confirm PIN',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterText: '',
                          prefixIcon: Icon(
                            Icons.verified_user,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        onChanged: (value) {
                          errorMessage.value = '';
                        },
                      ),
                    ),
                    // Error Message
                    if (errorMessage.value.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage.value,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey.withOpacity(0.2),
                                  Colors.grey.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () => Get.back(),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF4A90E2),
                                  Color(0xFF357088),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A90E2).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () async {
                                final pin = pinController.text;
                                final confirmPin = confirmPinController.text;
                                
                                if (pin.length != 4) {
                                  errorMessage.value = 'PIN must be 4 digits';
                                  return;
                                }
                                
                                if (pin != confirmPin) {
                                  errorMessage.value = 'PINs do not match';
                                  return;
                                }
                                
                                await appLockController.setPin(pin);
                                await appLockController.toggleAppLock(true);
                                
                                // Always close the dialog first
                                Get.back();
                                
                                // If the app is currently locked, unlock it after setting PIN
                                if (appLockController.isAppLocked.value) {
                                  appLockController.isAppLocked.value = false;
                                  // Navigate back to appropriate screen based on user role
                                  Get.find<AuthController>().navigateBasedOnRole();
                                }
                                
                                Get.snackbar(
                                  'Success',
                                  'App lock enabled successfully',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: const Color(0xFF2E7D32),
                                  colorText: Colors.white,
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Set PIN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
