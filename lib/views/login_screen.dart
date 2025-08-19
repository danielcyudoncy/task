// views/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/constants/app_icons.dart';
import 'package:task/utils/devices/app_devices.dart';
import '../controllers/auth_controller.dart';
import '../utils/snackbar_utils.dart';
import 'package:task/service/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _auth = Get.find();
  final BiometricService _biometricService = BiometricService();

  // Safe snackbar method
  void _safeSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  @override
  void initState() {
    super.initState();
    // Reset loading state to ensure we're not stuck in loading
    _auth.resetLoadingState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    AppDevices.hideKeyboard(context);
    if (_formKey.currentState!.validate()) {
      _auth.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  void _biometricLogin() async {
    if (!await _biometricService.canCheckBiometrics()) {
      _safeSnackbar('Error', 'Biometric authentication is not available on this device.');
      return;
    }
    final authenticated = await _biometricService.authenticate(reason: 'Please authenticate to login');
    if (!mounted) return;
    
    if (authenticated) {
      _submit(context);
    } else {
      _safeSnackbar('Error', 'Biometric authentication failed.');
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).canvasColor
                  : Theme.of(context).colorScheme.primary,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        

                        // App Logo
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              AppIcons.logo,
                              height: 150,
                            ),
                          ),
                        ),
                        

                      

                        // Main box container
                        Container(
                          padding: const EdgeInsets.all(24),
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'welcome_back'.tr,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24.sp,
                                    fontFamily: 'Raleway',
                                    color: textTheme.headlineMedium?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'fill_info_below'.tr,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 14.sp,
                                    color: colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'email'.tr,
                                    labelStyle: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    hintStyle: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    prefixIcon: Icon(Icons.email,
                                        color: colorScheme.onSurfaceVariant),
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.light
                                        ? Colors.grey[200]
                                        : Colors.grey[800],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'please_enter_email'.tr;
                                    }
                                    if (!GetUtils.isEmail(value)) {
                                      return 'please_enter_valid_email'.tr;
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Password Field
                                Obx(() {
                                  if (!Get.isRegistered<AuthController>()) {
                                    return TextFormField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'password'.tr,
                                        labelStyle: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        hintStyle: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        prefixIcon: Icon(Icons.lock,
                                            color: colorScheme.onSurfaceVariant),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            Icons.visibility_off,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          onPressed: () {},
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).brightness == Brightness.light
                                            ? Colors.grey[200]
                                            : Colors.grey[800],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'please_enter_password'.tr;
                                        }
                                        if (value.length < 6) {
                                          return 'password_min_length'.tr;
                                        }
                                        return null;
                                      },
                                    );
                                  }
                                  
                                  return TextFormField(
                                    controller: _passwordController,
                                    obscureText: _auth.isLoginPasswordHidden.value,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'password'.tr,
                                      labelStyle: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      hintStyle: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      prefixIcon: Icon(Icons.lock,
                                          color: colorScheme.onSurfaceVariant),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _auth.isLoginPasswordHidden.value
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          Get.find<SettingsController>().triggerFeedback();
                                          _auth.isLoginPasswordHidden.value =
                                              !_auth.isLoginPasswordHidden.value;
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.light
                                          ? Colors.grey[200]
                                          : Colors.grey[800],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'please_enter_password'.tr;
                                      }
                                      if (value.length < 6) {
                                        return 'password_min_length'.tr;
                                      }
                                      return null;
                                    },
                                  );
                                }),

                                const SizedBox(height: 20),

                                // Sign In Button
                                Obx(() {
                                  if (!Get.isRegistered<AuthController>()) {
                                    return ElevatedButton(
                                        // Using theme's default button styling
                                        onPressed: () {
                                          Get.find<SettingsController>().triggerFeedback();
                                          _submit(context);
                                        },
                                        child: Text(
                                          'sign_in'.tr,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Raleway',
                                          ),
                                        )
                                      );
                                  }
                                  
                                  return _auth.isLoading.value
                                      ? const Center(child: CircularProgressIndicator())
                                      : ElevatedButton(
                                          // Using theme's default button styling
                                          onPressed: () {
                                            Get.find<SettingsController>().triggerFeedback();
                                            _submit(context);
                                          },
                                          child: Text(
                                            'sign_in'.tr,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Raleway',
                                            ),
                                          ),
                                        );
                                }),

                                const SizedBox(height: 20),

                                // Divider with text
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(
                                        'or_continue_with'.tr,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Animated Google & Apple Login Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Image.asset(AppIcons.google,
                                          width: 48.w, height: 48.h),
                                      onPressed: () async {
                                        Get.find<SettingsController>()
                                            .triggerFeedback();
                                        await _auth.signInWithGoogle();
                                      },
                                    ),
                                    SizedBox(width: 20.w),
                                    IconButton(
                                      icon: Image.asset(AppIcons.apple,
                                          width: 48.w, height: 48.h),
                                      onPressed: () {
                                        Get.find<SettingsController>()
                                            .triggerFeedback();
                                        Get.snackbar(
                                          'Coming Soon',
                                          'Apple Sign-In will be available soon!',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Get.theme.colorScheme.surface,
                                          colorText: Get.theme.colorScheme.onSurface,
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Bottom text
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'dont_have_account'.tr,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Get.find<SettingsController>()
                                            .triggerFeedback();
                                        Get.toNamed('/signup');
                                      },
                                      child: Text(
                                        'create_account'.tr,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                GestureDetector(
                                  onTap: () {
                                    Get.find<SettingsController>()
                                        .triggerFeedback();
                                    Get.toNamed('/forgot-password');
                                    },
                                  child: Text(
                                    'forget_password'.tr,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      decoration: TextDecoration.underline,
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Raleway',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                       
                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.fingerprint),
                          label: Text('login_with_fingerprint'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: isDark ? Colors.black : colorScheme.onSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          ),
                          onPressed: () async {
                            Get.find<SettingsController>().triggerFeedback();
                            _biometricLogin();
                          },
                        ),
                       
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

         
        ],
      ),
    );
  }
}
