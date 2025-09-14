// views/profile_update_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
// import 'package:task/utils/constants/app_icons.dart';
import '../widgets/image_picker_widget.dart';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final AuthController auth = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Prefill form controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      auth.fullNameController.text = auth.fullName.value;
      auth.emailController.text = auth.auth.currentUser?.email ?? '';
      auth.phoneNumberController.text = auth.phoneNumberController.text;
      auth.selectedRole.value = auth.userRole.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
                  ? [Colors.grey[900]!, Colors.grey[800]!]
                      .reduce((value, element) => value)
                  : Theme.of(context).colorScheme.primary,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
                    color: Theme.of(context).colorScheme.onPrimary,
                    onPressed: () {Get.find<SettingsController>().triggerFeedback(); Get.back();},
                  ),
                ),
                SizedBox(height: 8.h),

                // // App logo
                // Image.asset(
                //   AppIcons.logo,
                //   width: 80.w,
                //   height: 80.h,
                // ),
                // SizedBox(height: 24.h),

                // Form Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'update_account'.tr,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'raleway',
                                color: isDark ? Colors.white : Colors.black,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),

                        Text(
                          'adjust_content_below'.tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontFamily: 'raleway',
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24.h),

                        ImagePickerWidget(controller: auth),
                        SizedBox(height: 24.h),

                        // Full Name
                        TextFormField(
                          controller: auth.fullNameController,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'full_name'.tr,
                            hintStyle: TextStyle(
                                color:
                                    isDark ? Colors.white54 : Colors.black54),
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[850] : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'please_enter_your_name'.tr
                              : null,
                        ),
                        SizedBox(height: 16.h),

                        // Phone Number
                        TextFormField(
                          controller: auth.phoneNumberController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'phone_number'.tr,
                            hintStyle: TextStyle(
                                color:
                                    isDark ? Colors.white54 : Colors.black54),
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[850] : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'please_enter_phone_number'.tr
                              : null,
                        ),
                        SizedBox(height: 16.h),

                        // Email Address
                        TextFormField(
                          controller: auth.emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'email_address'.tr,
                            hintStyle: TextStyle(
                                color:
                                    isDark ? Colors.white54 : Colors.black54),
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[850] : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v == null || !GetUtils.isEmail(v)
                              ? 'please_enter_a_valid_email'.tr
                              : null,
                        ),
                        SizedBox(height: 16.h),

                        // Role Dropdown
                        Obx(
                          () => DropdownButtonFormField<String>(
                            initialValue: auth.selectedRole.value.isEmpty
                                ? null
                                : auth.selectedRole.value,
                            items: auth.userRoles
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => auth.selectedRole.value = v!,
                            dropdownColor:
                                isDark ? Colors.grey[850] : Colors.white,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: 'role'.tr,
                              hintStyle: TextStyle(
                                  color:
                                      isDark ? Colors.white54 : Colors.black54),
                              filled: true,
                              fillColor:
                                  isDark ? Colors.grey[850] : Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'please_select_a_role'.tr
                                : null,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Save Changes button
                        Obx(
                          () => auth.isLoading.value
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  height: 48.h,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2F80ED),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                    ),
                                    onPressed: () async {
                                      Get.find<SettingsController>()
                                          .triggerFeedback();
                                      if (_formKey.currentState!.validate()) {
                                        await auth.completeProfile();
                                        // Profile completion will handle navigation automatically
                                      }
                                    },
                                    child:  Text(
                                      'save_changes'.tr,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
