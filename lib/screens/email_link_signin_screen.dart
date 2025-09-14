// views/email_link_signin_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/utils/constants/app_icons.dart';
import 'package:task/utils/snackbar_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmailLinkSignInScreen extends StatefulWidget {
  const EmailLinkSignInScreen({super.key});

  @override
  State<EmailLinkSignInScreen> createState() => _EmailLinkSignInScreenState();
}

class _EmailLinkSignInScreenState extends State<EmailLinkSignInScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    _handleEmailLink();
  }

  Future<void> _loadSavedEmail() async {
    final savedEmail = await _authController.getSavedEmailForSignIn();
    if (savedEmail != null) {
      _emailController.text = savedEmail;
    }
  }

  Future<void> _handleEmailLink() async {
    // Get the email link from various sources
    String? emailLink;
    
    // Check for link in route parameters
    emailLink = Get.parameters['link'];
    
    // Check for link in arguments
    if (emailLink == null) {
      final args = Get.arguments;
      if (args is String) {
        emailLink = args;
      } else if (args is Map && args.containsKey('link')) {
        emailLink = args['link'];
      }
    }
    
    // Check for link in current URI (for web/deep links)
    if (emailLink == null) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('link')) {
        emailLink = uri.queryParameters['link'];
      } else if (uri.toString().contains('__/auth/links')) {
        emailLink = uri.toString();
      }
    }
    
    if (emailLink != null && _emailController.text.isNotEmpty) {
      await _signInWithEmailLink(emailLink);
    }
  }

  Future<void> _signInWithEmailLink(String emailLink) async {
    if (_emailController.text.trim().isEmpty) {
      _safeSnackbar('Error', 'Please enter your email address.');
      return;
    }

    if (!GetUtils.isEmail(_emailController.text.trim())) {
      _safeSnackbar('Error', 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _authController.signInWithEmailLink(
        _emailController.text.trim(),
        emailLink,
      );
    } catch (e) {
      _safeSnackbar('Error', 'Failed to sign in with email link. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _safeSnackbar(String title, String message) {
    if (mounted) {
      SnackbarUtils.showSnackbar(title, message);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
                        const SizedBox(height: 60),
                        
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
                        const SizedBox(height: 30),

                        // Main container
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
                                  'Complete Sign In',
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
                                  'Please confirm your email address to complete the sign-in process.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 14.sp,
                                    color: textTheme.bodyMedium?.color?.withAlpha(7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),

                                // Email Input Field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'Enter your email address',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: colorScheme.primary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colorScheme.outline.withAlpha(5),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surface,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email address';
                                    }
                                    if (!GetUtils.isEmail(value.trim())) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Complete Sign In Button
                                Obx(() => ElevatedButton(
                                  onPressed: _isProcessing || _authController.isLoading.value
                                      ? null
                                      : () async {
                                          if (_formKey.currentState!.validate()) {
                                            final String? emailLink = Get.parameters['link'] ?? Get.arguments as String?;
                                            if (emailLink != null) {
                                              await _signInWithEmailLink(emailLink);
                                            } else {
                                              _safeSnackbar('Error', 'Invalid email link. Please try again.');
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: _isProcessing || _authController.isLoading.value
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              colorScheme.onPrimary,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Complete Sign In',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                )),
                                const SizedBox(height: 16),

                                // Back to Login Button
                                TextButton(
                                  onPressed: () {
                                    Get.offAllNamed('/login');
                                  },
                                  child: Text(
                                    'Back to Login',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
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