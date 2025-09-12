import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../utils/snackbar_utils.dart';


enum NetworkStatus {
  online,
  offline,
  poor,
  unknown
}

enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  none,
  unknown
}

class NetworkService extends GetxService {
  static NetworkService get to => Get.find();
  
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _internetChecker = InternetConnectionChecker.createInstance();
  
  final Rx<NetworkStatus> _networkStatus = NetworkStatus.unknown.obs;
  final Rx<ConnectionType> _connectionType = ConnectionType.unknown.obs;
  final RxBool _isOnline = false.obs;
  final RxDouble _connectionQuality = 0.0.obs;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetConnectionStatus>? _internetSubscription;
  Timer? _qualityCheckTimer;
  
  // Getters
  NetworkStatus get networkStatus => _networkStatus.value;
  ConnectionType get connectionType => _connectionType.value;
  bool get isOnline => _isOnline.value;
  bool get isOffline => !_isOnline.value;
  double get connectionQuality => _connectionQuality.value;
  
  // Observables for reactive UI
  Rx<NetworkStatus> get networkStatusObs => _networkStatus;
  Rx<ConnectionType> get connectionTypeObs => _connectionType;
  RxBool get isOnlineObs => _isOnline;
  RxDouble get connectionQualityObs => _connectionQuality;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeNetworkMonitoring();
  }
  
  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    _qualityCheckTimer?.cancel();
    super.onClose();
  }
  
  Future<void> _initializeNetworkMonitoring() async {
    try {
      // Initial status check
      await _checkInitialStatus();
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          debugPrint('Connectivity stream error: $error');
        },
      );
      
      // Listen to internet connection status
      _internetSubscription = _internetChecker.onStatusChange.listen(
        _onInternetStatusChanged,
        onError: (error) {
          debugPrint('Internet checker stream error: $error');
        },
      );
      
      // Start periodic quality checks
      _startQualityMonitoring();
      
    } catch (e) {
      debugPrint('Error initializing network monitoring: $e');
      _networkStatus.value = NetworkStatus.unknown;
    }
  }
  
  Future<void> _checkInitialStatus() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasInternet = await _internetChecker.hasConnection;
      
      _updateConnectionType(connectivityResults);
      _isOnline.value = hasInternet;
      _updateNetworkStatus();
      
    } catch (e) {
      debugPrint('Error checking initial network status: $e');
    }
  }
  
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateConnectionType(results);
    _checkInternetConnection();
  }
  
  void _onInternetStatusChanged(InternetConnectionStatus status) {
    final wasOnline = _isOnline.value;
    _isOnline.value = status == InternetConnectionStatus.connected;
    _updateNetworkStatus();
    
    // Show user feedback for status changes
    if (wasOnline && !_isOnline.value) {
      _showOfflineNotification();
    } else if (!wasOnline && _isOnline.value) {
      _showOnlineNotification();
    }
  }
  
  void _updateConnectionType(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      _connectionType.value = ConnectionType.none;
      return;
    }
    
    final result = results.first;
    switch (result) {
      case ConnectivityResult.wifi:
        _connectionType.value = ConnectionType.wifi;
        break;
      case ConnectivityResult.mobile:
        _connectionType.value = ConnectionType.mobile;
        break;
      case ConnectivityResult.ethernet:
        _connectionType.value = ConnectionType.ethernet;
        break;
      case ConnectivityResult.none:
        _connectionType.value = ConnectionType.none;
        break;
      default:
        _connectionType.value = ConnectionType.unknown;
    }
  }
  
  void _updateNetworkStatus() {
    if (!_isOnline.value) {
      _networkStatus.value = NetworkStatus.offline;
    } else if (_connectionQuality.value < 0.3) {
      _networkStatus.value = NetworkStatus.poor;
    } else {
      _networkStatus.value = NetworkStatus.online;
    }
  }
  
  Future<void> _checkInternetConnection() async {
    try {
      final hasConnection = await _internetChecker.hasConnection;
      _isOnline.value = hasConnection;
      _updateNetworkStatus();
    } catch (e) {
      debugPrint('Error checking internet connection: $e');
    }
  }
  
  void _startQualityMonitoring() {
    _qualityCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectionQuality(),
    );
  }
  
  Future<void> _checkConnectionQuality() async {
    if (!_isOnline.value) {
      _connectionQuality.value = 0.0;
      return;
    }
    
    try {
      final stopwatch = Stopwatch()..start();
      
      // Simple ping test to measure response time
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      stopwatch.stop();
      
      if (result.isNotEmpty) {
        final responseTime = stopwatch.elapsedMilliseconds;
        
        // Calculate quality based on response time
        // < 100ms = excellent (1.0)
        // 100-300ms = good (0.7)
        // 300-1000ms = fair (0.4)
        // > 1000ms = poor (0.1)
        if (responseTime < 100) {
          _connectionQuality.value = 1.0;
        } else if (responseTime < 300) {
          _connectionQuality.value = 0.7;
        } else if (responseTime < 1000) {
          _connectionQuality.value = 0.4;
        } else {
          _connectionQuality.value = 0.1;
        }
      } else {
        _connectionQuality.value = 0.0;
      }
      
      _updateNetworkStatus();
      
    } catch (e) {
      _connectionQuality.value = 0.0;
      debugPrint('Error checking connection quality: $e');
    }
  }
  
  void _showOfflineNotification() {
    SnackbarUtils.showWarning(
      'network_offline_message'.tr,
    );
  }
  
  void _showOnlineNotification() {
    SnackbarUtils.showSuccess(
      'network_online_message'.tr,
    );
  }
  
  // Public methods for manual checks
  Future<bool> checkConnection() async {
    try {
      final hasConnection = await _internetChecker.hasConnection;
      _isOnline.value = hasConnection;
      _updateNetworkStatus();
      return hasConnection;
    } catch (e) {
      debugPrint('Error in manual connection check: $e');
      return false;
    }
  }
  
  Future<void> refreshNetworkStatus() async {
    await _checkInitialStatus();
    await _checkConnectionQuality();
  }
  
  // Helper methods for UI
  String getNetworkStatusText() {
    switch (_networkStatus.value) {
      case NetworkStatus.online:
        return 'network_status_online'.tr;
      case NetworkStatus.offline:
        return 'network_status_offline'.tr;
      case NetworkStatus.poor:
        return 'network_status_poor'.tr;
      case NetworkStatus.unknown:
        return 'network_status_unknown'.tr;
    }
  }
  
  String getConnectionTypeText() {
    switch (_connectionType.value) {
      case ConnectionType.wifi:
        return 'connection_type_wifi'.tr;
      case ConnectionType.mobile:
        return 'connection_type_mobile'.tr;
      case ConnectionType.ethernet:
        return 'connection_type_ethernet'.tr;
      case ConnectionType.none:
        return 'connection_type_none'.tr;
      case ConnectionType.unknown:
        return 'connection_type_unknown'.tr;
    }
  }
  
  // Retry mechanism for failed operations
  Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
    bool requiresNetwork = true,
  }) async {
    if (requiresNetwork && !_isOnline.value) {
      throw NetworkException('No internet connection available');
    }
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }
        
        // Wait before retry, with exponential backoff
        await Future.delayed(delay * (attempt + 1));
        
        // Check connection before retry
        if (requiresNetwork) {
          await checkConnection();
          if (!_isOnline.value) {
            throw NetworkException('Connection lost during retry');
          }
        }
      }
    }
    
    return null;
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

// Mixin for easy network-aware widgets
mixin NetworkAwareMixin {
  NetworkService get networkService => NetworkService.to;
  
  bool get isOnline => networkService.isOnline;
  bool get isOffline => networkService.isOffline;
  NetworkStatus get networkStatus => networkService.networkStatus;
  
  void showNetworkRequiredMessage() {
    SnackbarUtils.showError(
      'network_required_message'.tr,
    );
  }
}