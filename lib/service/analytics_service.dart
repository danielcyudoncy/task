// service/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Track custom events with optional parameters
  static Future<void> trackEvent({
    required String name,
    Map<String, dynamic>? params,
  }) async {
    await _analytics.logEvent(
      name: 'event_name',
      parameters: {'key': 'value'},
    );
    debugPrint('Tracked event: $name');
  }

  /// Track screen views
  static Future<void> trackScreen({required String screenName}) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  /// Track authentication events (login/signup)
  static Future<void> trackAuthEvent(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Track errors
  static Future<void> trackError({
    required String location,
    required dynamic error,
  }) async {
    await _analytics.logEvent(
      name: 'error_occurred',
      parameters: {
        'location': location,
        'error': error.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
