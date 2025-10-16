// utils/url_launcher_helper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class UrlLauncherHelper {
  static Future<void> openExternalLink(String? url) async {
    if (url == null || url.isEmpty) {
      Get.snackbar(
        'Error',
        'No link available for this article',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    try {
      // Clean and validate the URL
      String cleanUrl = url.trim();

      // Add https:// if no protocol is specified
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      debugPrint('UrlLauncherHelper: Attempting to open URL: $cleanUrl');

      final uri = Uri.parse(cleanUrl);

      // Try different launch modes
      bool launched = false;

      // First try: External application (browser) - skip canLaunchUrl check
      try {
        debugPrint('UrlLauncherHelper: Attempting external launch directly...');
        launched = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
          browserConfiguration: const BrowserConfiguration(
            showTitle: true,
          ),
        );
        debugPrint('UrlLauncherHelper: External launch result: $launched');
      } catch (e) {
        debugPrint('UrlLauncherHelper: External launch failed: $e');
      }

      // Second try: In-app browser if external failed
      if (!launched) {
        try {
          debugPrint('UrlLauncherHelper: Trying in-app WebView...');
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
          debugPrint('UrlLauncherHelper: In-app launch result: $launched');
        } catch (e) {
          debugPrint('UrlLauncherHelper: In-app launch failed: $e');
        }
      }

      // Third try: Platform default
      if (!launched) {
        try {
          debugPrint('UrlLauncherHelper: Trying platform default...');
          launched = await launchUrl(uri);
          debugPrint('UrlLauncherHelper: Default launch result: $launched');
        } catch (e) {
          debugPrint('UrlLauncherHelper: Default launch failed: $e');
        }
      }

      if (!launched) {
        debugPrint(
            'UrlLauncherHelper: All launch methods failed for URL: $cleanUrl');

        // Try one more approach - use a simpler URL format
        try {
          debugPrint(
              'UrlLauncherHelper: Trying with simplified URL approach...');
          final simpleUri = Uri.parse(cleanUrl.replaceAll(' ', '%20'));
          launched = await launchUrl(simpleUri,
              mode: LaunchMode.inAppBrowserView,
              browserConfiguration: const BrowserConfiguration(
                showTitle: true,
              ));
          debugPrint(
              'UrlLauncherHelper: Simplified URL launch result: $launched');
        } catch (e) {
          debugPrint('UrlLauncherHelper: Simplified URL launch failed: $e');
        }

        // Try platform-specific approach for Android
        if (!launched && Platform.isAndroid) {
          try {
            debugPrint(
                'UrlLauncherHelper: Trying Android-specific approach...');
            // Try with a different mode that might work better on Android
            launched = await launchUrl(
              uri,
              mode: LaunchMode.inAppBrowserView,
              browserConfiguration: const BrowserConfiguration(
                showTitle: true,
              ),
            );
            debugPrint(
                'UrlLauncherHelper: Android-specific launch result: $launched');
          } catch (e) {
            debugPrint('UrlLauncherHelper: Android-specific launch failed: $e');
          }
        }

        if (!launched) {
          Get.snackbar(
            'Error',
            'Could not open the link. Please try copying the URL and opening it manually in your browser.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            colorText: Colors.orange[700],
            duration: const Duration(seconds: 5),
            mainButton: TextButton(
              onPressed: () {
                // Copy URL to clipboard
                // You can add clipboard functionality here if needed
                Get.back(); // Close snackbar
              },
              child: const Text('Copy URL'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('UrlLauncherHelper: Error opening URL: $e');
      Get.snackbar(
        'Error',
        'Invalid link format: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
      );
    }
  }
}
