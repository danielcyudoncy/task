// screens/app_lock_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/app_lock_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/devices/app_devices.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final AppLockController _appLockController = Get.find<AppLockController>();
  final TextEditingController _pinController = TextEditingController();
  final RxString enteredPin = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    // Trigger biometric check on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_appLockController.canUseBiometric) {
        debugPrint('AppLockScreen: Automatically triggering biometric unlock.');
        _appLockController.unlockWithBiometric();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
  
  void _onNumberPressed(String number) {
    if (enteredPin.value.length < 4) {
      enteredPin.value += number;
      _pinController.text = enteredPin.value;
      
      // Auto-submit when 4 digits are entered
      if (enteredPin.value.length == 4) {
        _submitPin();
      }
    }
  }
  
  void _onBackspacePressed() {
    if (enteredPin.value.isNotEmpty) {
      enteredPin.value = enteredPin.value.substring(0, enteredPin.value.length - 1);
      _pinController.text = enteredPin.value;
    }
  }
  
  void _clearPin() {
    enteredPin.value = '';
    _pinController.text = '';
  }
  
  Future<void> _submitPin() async {
    if (enteredPin.value.length != 4) return;
    
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 300)); // Small delay for UX
    
    await _appLockController.unlockWithPin(enteredPin.value);
    
    // Clear pin if unlock failed
    if (_appLockController.isAppLocked.value) {
      _clearPin();
    }
    
    isLoading.value = false;
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTablet = AppDevices.isTablet(context);
    
    return Scaffold(
       backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? [Colors.grey[900]!, Colors.grey[800]!]
                      .reduce((value, element) => value)
                  : Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo and Title
              Icon(
                Icons.lock_outline,
                size: isTablet ? 80.sp : 60.sp,
                color: colorScheme.primary,
              ),
              SizedBox(height: isTablet ? 24 : 16),
              
              Text(
                'App Locked',
                style: TextStyle(
                  fontSize: isTablet ? 28.sp : 24.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontFamily: 'Raleway',
                ),
              ),
              
              SizedBox(height: isTablet ? 12 : 8),
              
              Obx(() => Column(
                children: [
                  Text(
                    'Enter your PIN to unlock',
                    style: TextStyle(
                      fontSize: isTablet ? 16.sp : 14.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontFamily: 'Raleway',
                    ),
                  ),
                  
                  // Show default PIN hint if user hasn't set a custom PIN
                   if (!_appLockController.hasSetPin.value) ...[
                     SizedBox(height: isTablet ? 12 : 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 12 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Default PIN: 0000',
                            style: TextStyle(
                              fontSize: isTablet ? 14.sp : 12.sp,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                              fontFamily: 'Raleway',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Please change this in Settings after unlocking',
                            style: TextStyle(
                              fontSize: isTablet ? 12.sp : 10.sp,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontFamily: 'Raleway',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              )),
              
              SizedBox(height: isTablet ? 48 : 32),
              
              // PIN Display
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isActive = index < enteredPin.value.length;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
                    width: isTablet ? 20 : 16,
                    height: isTablet ? 20 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive 
                        ? colorScheme.primary 
                        : colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  );
                }),
              )),
              
              SizedBox(height: isTablet ? 48 : 32),
              
              // Number Pad
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: isTablet ? 20 : 16,
                    mainAxisSpacing: isTablet ? 20 : 16,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      // Biometric button (if available)
                      return Obx(() => _appLockController.canUseBiometric
                        ? _buildBiometricButton(colorScheme, isTablet)
                        : const SizedBox.shrink());
                    } else if (index == 10) {
                      // Number 0
                      return _buildNumberButton(
                        '0',
                        colorScheme,
                        isTablet,
                      );
                    } else if (index == 11) {
                      // Backspace button
                      return _buildActionButton(
                        icon: Icons.backspace_outlined,
                        onPressed: isLoading.value ? null : _onBackspacePressed,
                        colorScheme: colorScheme,
                        isTablet: isTablet,
                      );
                    } else {
                      // Numbers 1-9
                      final number = (index + 1).toString();
                      return _buildNumberButton(
                        number,
                        colorScheme,
                        isTablet,
                      );
                    }
                  },
                ),
              ),
              
              SizedBox(height: isTablet ? 24 : 16),
              
              // Loading indicator
              Obx(() => isLoading.value
                ? const CircularProgressIndicator()
                : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNumberButton(
    String number,
    ColorScheme colorScheme,
    bool isTablet,
  ) {
    return Obx(() => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading.value ? null : () {
          Get.find<SettingsController>().triggerFeedback();
          _onNumberPressed(number);
        },
        borderRadius: BorderRadius.circular(isTablet ? 40 : 32),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: isTablet ? 24.sp : 20.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                fontFamily: 'Raleway',
              ),
            ),
          ),
        ),
      ),
    ));
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
    required bool isTablet,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed == null ? null : () {
          Get.find<SettingsController>().triggerFeedback();
          onPressed();
        },
        borderRadius: BorderRadius.circular(isTablet ? 40 : 32),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: isTablet ? 28.sp : 24.sp,
              color: onPressed == null 
                ? colorScheme.onSurface.withValues(alpha: 0.3)
                : colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBiometricButton(ColorScheme colorScheme, bool isTablet) {
    return Obx(() {
      final canUseBiometric = _appLockController.canUseBiometric;
      debugPrint('AppLockScreen: Building biometric button, canUseBiometric = $canUseBiometric');
      
      if (!canUseBiometric) {
        debugPrint('AppLockScreen: Biometric not available, showing empty container');
        return const SizedBox.shrink();
      }

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading.value ? null : () async {
            debugPrint('AppLockScreen: Biometric button tapped');
            Get.find<SettingsController>().triggerFeedback();
            await _appLockController.unlockWithBiometric();
          },
          borderRadius: BorderRadius.circular(isTablet ? 40 : 32),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Icon(
                _appLockController.biometricIcon,
                size: isTablet ? 28.sp : 24.sp,
                color: isLoading.value 
                  ? colorScheme.onSurface.withValues(alpha: 0.3)
                  : colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    });
  }
}