// controllers/onboarding_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  final RxBool isLastPage = false.obs;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'welcome_to_tasky'.tr,
      subtitle: 'personal_assistant_subtitle'.tr,
      ctaText: 'organize_by_projects'.tr,
      icon: Icons.task_alt,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'organize_prioritize'.tr,
      subtitle: 'group_tasks_subtitle'.tr,
      ctaText: 'try_organizing_tasks'.tr,
      icon: Icons.category,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'you_ready'.tr,
      subtitle: 'start_managing_subtitle'.tr,
      ctaText: 'lets_get_started'.tr,
      icon: Icons.rocket_launch,
      color: Colors.orange,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    updateLastPageStatus();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int page) {
    currentPage.value = page;
    updateLastPageStatus();
  }

  void updateLastPageStatus() {
    isLastPage.value = currentPage.value == pages.length - 1;
  }

  void nextPage() {
    debugPrint(
        "OnboardingController: nextPage called, current page: ${currentPage.value}");
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    debugPrint(
        "OnboardingController: previousPage called, current page: ${currentPage.value}");
    if (currentPage.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipOnboarding() async {
    debugPrint("OnboardingController: skipOnboarding called");
    await _markOnboardingComplete();
    debugPrint("OnboardingController: Navigating to login");
    Get.offAllNamed('/login');
  }

  void completeOnboarding() async {
    debugPrint("OnboardingController: completeOnboarding called");
    await _markOnboardingComplete();
    debugPrint("OnboardingController: Navigating to login");
    Get.offAllNamed('/login');
  }

  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenOnboarding') ?? false;
  }

  // For testing purposes - reset onboarding state
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasSeenOnboarding');
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String ctaText;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.icon,
    required this.color,
  });
}
