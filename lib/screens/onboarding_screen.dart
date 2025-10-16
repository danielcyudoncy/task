// screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({super.key});

  final OnboardingController controller = Get.put(OnboardingController());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? [Colors.grey[900]!, Colors.grey[800]!]
              .reduce((value, element) => value)
          : Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: TextButton(
                  onPressed: controller.skipOnboarding,
                  child: Text(
                    'skip'.tr,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.white70,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: controller.pages.length,
                itemBuilder: (context, index) {
                  final page = controller.pages[index];
                  return _buildPage(context, page, isDark, theme);
                },
              ),
            ),

            // Bottom navigation
            _buildBottomNavigation(context, isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
      BuildContext context, OnboardingPage page, bool isDark, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: page.color.withAlpha((0.1 * 255).round()),
              shape: BoxShape.circle,
              border: Border.all(
                color: page.color.withAlpha((0.3 * 255).round()),
                width: 2,
              ),
            ),
            child: Icon(
              page.icon,
              size: 60.sp,
              color: page.color,
            ),
          ),

          SizedBox(height: 40.h),

          // Title
          Text(
            page.title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Raleway',
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16.h),

          // Subtitle
          Text(
            page.subtitle,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.white70,
              fontSize: 16.sp,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 40.h),

          // CTA Button
          Obx(() => SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: controller.isLastPage.value
                      ? controller.completeOnboarding
                      : controller.nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: page.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    page.ctaText,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(
      BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page indicators
          Row(
            children: List.generate(
              controller.pages.length,
              (index) => Obx(() => Container(
                    width: 12.w,
                    height: 12.h,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.currentPage.value == index
                          ? (isDark
                              ? Colors.blue.shade300
                              : Colors.blue.shade600)
                          : (isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                  )),
            ),
          ),

          // Navigation buttons
          Row(
            children: [
              // Previous button
              Obx(() => controller.currentPage.value > 0
                  ? IconButton(
                      onPressed: controller.previousPage,
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        size: 20.sp,
                      ),
                    )
                  : SizedBox(width: 48.w)),

              SizedBox(width: 8.w),

              // Next button
              Obx(() => controller.currentPage.value <
                      controller.pages.length - 1
                  ? IconButton(
                      onPressed: controller.nextPage,
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        size: 20.sp,
                      ),
                    )
                  : SizedBox(width: 48.w)),
            ],
          ),
        ],
      ),
    );
  }
}
