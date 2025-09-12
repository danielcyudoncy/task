// service/loading_state_service.dart
import 'package:get/get.dart';

enum LoadingState {
  idle,
  loading,
  success,
  error,
  empty
}

class LoadingStateController extends GetxController {
  final Rx<LoadingState> _state = LoadingState.idle.obs;
  final RxString _message = ''.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isRefreshing = false.obs;
  
  LoadingState get state => _state.value;
  String get message => _message.value;
  String get errorMessage => _errorMessage.value;
  bool get isRefreshing => _isRefreshing.value;
  
  bool get isLoading => _state.value == LoadingState.loading;
  bool get isSuccess => _state.value == LoadingState.success;
  bool get isError => _state.value == LoadingState.error;
  bool get isEmpty => _state.value == LoadingState.empty;
  bool get isIdle => _state.value == LoadingState.idle;
  
  void setLoading([String? message]) {
    _state.value = LoadingState.loading;
    _message.value = message ?? 'Loading...';
    _errorMessage.value = '';
  }
  
  void setSuccess([String? message]) {
    _state.value = LoadingState.success;
    _message.value = message ?? '';
    _errorMessage.value = '';
  }
  
  void setError(String errorMessage) {
    _state.value = LoadingState.error;
    _errorMessage.value = errorMessage;
    _message.value = '';
  }
  
  void setEmpty([String? message]) {
    _state.value = LoadingState.empty;
    _message.value = message ?? 'No data available';
    _errorMessage.value = '';
  }
  
  void setIdle() {
    _state.value = LoadingState.idle;
    _message.value = '';
    _errorMessage.value = '';
  }
  
  void setRefreshing(bool refreshing) {
    _isRefreshing.value = refreshing;
  }
  
  void reset() {
    _state.value = LoadingState.idle;
    _message.value = '';
    _errorMessage.value = '';
    _isRefreshing.value = false;
  }
}

class LoadingStateService extends GetxService {
  final Map<String, LoadingStateController> _controllers = {};
  
  LoadingStateController getController(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = LoadingStateController();
    }
    return _controllers[key]!;
  }
  
  void removeController(String key) {
    _controllers.remove(key);
  }
  
  void clearAll() {
    _controllers.clear();
  }
  
  // Convenience methods for common operations
  Future<T> executeWithLoading<T>(
    String key,
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    bool Function(T)? isEmpty,
    String? emptyMessage,
  }) async {
    final controller = getController(key);
    
    try {
      controller.setLoading(loadingMessage);
      
      final result = await operation();
      
      // Check if result is empty
      if (isEmpty?.call(result) == true) {
        controller.setEmpty(emptyMessage);
      } else {
        controller.setSuccess(successMessage);
      }
      
      return result;
    } catch (error) {
      controller.setError(error.toString());
      rethrow;
    }
  }
  
  Future<void> executeRefresh(
    String key,
    Future<void> Function() operation,
  ) async {
    final controller = getController(key);
    
    try {
      controller.setRefreshing(true);
      await operation();
    } finally {
      controller.setRefreshing(false);
    }
  }
}

// Mixin for easy loading state management in controllers
mixin LoadingStateMixin on GetxController {
  late final LoadingStateController loadingState;
  
  @override
  void onInit() {
    super.onInit();
    loadingState = LoadingStateController();
  }
  
  Future<T> executeWithLoading<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    bool Function(T)? isEmpty,
    String? emptyMessage,
  }) async {
    try {
      loadingState.setLoading(loadingMessage);
      
      final result = await operation();
      
      if (isEmpty?.call(result) == true) {
        loadingState.setEmpty(emptyMessage);
      } else {
        loadingState.setSuccess(successMessage);
      }
      
      return result;
    } catch (error) {
      loadingState.setError(error.toString());
      rethrow;
    }
  }
  
  Future<void> executeRefresh(Future<void> Function() operation) async {
    try {
      loadingState.setRefreshing(true);
      await operation();
    } finally {
      loadingState.setRefreshing(false);
    }
  }
}