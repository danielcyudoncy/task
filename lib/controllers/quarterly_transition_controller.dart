// controllers/quarterly_transition_controller.dart
import 'package:get/get.dart';
import '../service/quarterly_transition_service.dart';

class QuarterlyTransitionController extends GetxService {
  final QuarterlyTransitionService _quarterlyService = QuarterlyTransitionService();
  
  final RxBool isProcessing = false.obs;
  final RxString _currentQuarterYear = ''.obs;
  
  String get currentQuarterYear => _currentQuarterYear.value;
  
  @override
  void onInit() {
    super.onInit();
    _initQuarterlyCheck();
  }
  
  // Initialize and check for quarterly transition
  Future<void> _initQuarterlyCheck() async {
    try {
      isProcessing.value = true;
      _currentQuarterYear.value = _quarterlyService.getCurrentQuarterYearString();
      
      // Check for quarter transition (will process if needed)
      final didTransition = await _quarterlyService.checkForQuarterTransition();
      
      if (didTransition) {
        _currentQuarterYear.value = _quarterlyService.getCurrentQuarterYearString();
        // You could show a notification or update UI here if needed
      }
    } catch (e) {
      // Handle error appropriately
    } finally {
      isProcessing.value = false;
    }
  }
  
  // Get current quarter (1-4)
  int getCurrentQuarter() {
    return _quarterlyService.getCurrentQuarter();
  }
  
  // Get quarter string for a specific date
  String getQuarterYearForDate(DateTime date) {
    return _quarterlyService.getQuarterYearString(date);
  }
  
  // Manually trigger quarter transition (for testing)
  Future<bool> forceQuarterTransition() async {
    try {
      isProcessing.value = true;
      await _quarterlyService.checkForQuarterTransition();
      _currentQuarterYear.value = _quarterlyService.getCurrentQuarterYearString();
      return true;
    } catch (e) {
      return false;
    } finally {
      isProcessing.value = false;
    }
  }
}
