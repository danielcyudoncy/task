// service/version_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VersionService {
  static const String _lastUpdateCheckKey = 'last_update_check';
  static const String _skipVersionKey = 'skip_version';
  static const String _versionCheckUrl = 'https://your-api.com/version-check';
  static const String _githubOwner = 'danielcyudoncy';
  static const String _githubRepo = 'delego';
  static const String _githubApiUrl =
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';
  static const String _githubReleaseUrl =
      'https://github.com/$_githubOwner/$_githubRepo/releases/latest';

  static String get githubReleaseUrl => _githubReleaseUrl;

  /// Get current app version
  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Get current build number
  static Future<String> getCurrentBuildNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }

  /// Check if update is available
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final currentVersion = await getCurrentVersion();
      final latestVersion = await _getLatestVersion();

      if (latestVersion != null &&
          _isVersionNewer(latestVersion, currentVersion)) {
        final prefs = await SharedPreferences.getInstance();
        final skippedVersion = prefs.getString(_skipVersionKey);

        if (skippedVersion == latestVersion) {
          return null;
        }

        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          isForced: _isForceUpdate(latestVersion, currentVersion),
          releaseNotes: await _getReleaseNotes(latestVersion),
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<UpdateInfo?> checkGitHubRelease() async {
    try {
      final currentVersion = await getCurrentVersion();
      final response = await http
          .get(Uri.parse(_githubApiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String?;
      final body = data['body'] as String?;

      if (tagName == null || tagName.isEmpty) {
        return null;
      }

      final latestVersion = _normalizeGitHubTag(tagName);
      if (!_isVersionNewer(latestVersion, currentVersion)) {
        return null;
      }

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        isForced: _isForceUpdate(latestVersion, currentVersion),
        releaseNotes: body,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get latest version from server/API
  static Future<String?> _getLatestVersion() async {
    try {
      // Option 1: Use your own API endpoint
      final response = await http.get(
        Uri.parse(_versionCheckUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['latest_version'] as String?;
      }

      // Option 2: Fallback to hardcoded version (for testing)
      return '1.1.0'; // Replace with actual logic
    } catch (e) {
      // Return null to indicate no update available
      return null;
    }
  }

  /// Get release notes for a specific version
  static Future<String?> _getReleaseNotes(String version) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_versionCheckUrl/release-notes/$version'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['release_notes'] as String?;
      }

      // Fallback release notes
      return 'Bug fixes and performance improvements.';
    } catch (e) {
      return 'Bug fixes and performance improvements.';
    }
  }

  static String _normalizeGitHubTag(String tag) {
    if (tag.isEmpty) {
      return tag;
    }
    for (var i = 0; i < tag.length; i++) {
      final code = tag.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        return tag.substring(i);
      }
    }
    return tag;
  }

  /// Compare version strings (e.g., "1.2.3" vs "1.2.4")
  static bool _isVersionNewer(String latestVersion, String currentVersion) {
    final latest = latestVersion.split('.').map(int.parse).toList();
    final current = currentVersion.split('.').map(int.parse).toList();

    // Ensure both versions have the same number of parts
    while (latest.length < current.length) {
      latest.add(0);
    }
    while (current.length < latest.length) {
      current.add(0);
    }

    for (int i = 0; i < latest.length; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }

    return false; // Versions are equal
  }

  /// Determine if update should be forced
  static bool _isForceUpdate(String latestVersion, String currentVersion) {
    // Example logic: Force update if major version is different
    final latestMajor = int.parse(latestVersion.split('.')[0]);
    final currentMajor = int.parse(currentVersion.split('.')[0]);

    return latestMajor > currentMajor;
  }

  /// Mark version as skipped
  static Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skipVersionKey, version);
  }

  /// Clear skipped version
  static Future<void> clearSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skipVersionKey);
  }

  /// Check if enough time has passed since last update check
  static Future<bool> shouldCheckForUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastUpdateCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check once per day (24 hours)
    const checkInterval = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

    return (now - lastCheck) > checkInterval;
  }

  /// Update last check timestamp
  static Future<void> updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _lastUpdateCheckKey, DateTime.now().millisecondsSinceEpoch);
  }
}

/// Update information model
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool isForced;
  final String? releaseNotes;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.isForced,
    this.releaseNotes,
  });

  @override
  String toString() {
    return 'UpdateInfo(current: $currentVersion, latest: $latestVersion, forced: $isForced)';
  }
}
