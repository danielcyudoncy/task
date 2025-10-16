// service/quarterly_transition_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class QuarterlyTransitionService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current quarter (1-4)
  int getCurrentQuarter() {
    return (DateTime.now().month - 1) ~/ 3 + 1;
  }

  // Get current year
  int getCurrentYear() {
    return DateTime.now().year;
  }

  // Get quarter date range
  Map<String, DateTime> getQuarterDateRange(int year, int quarter) {
    final startMonth = (quarter - 1) * 3 + 1;
    final endMonth = startMonth + 2;

    return {
      'start': DateTime(year, startMonth, 1),
      'end': DateTime(year, endMonth + 1, 0), // Last day of the end month
    };
  }

  // Check if a new quarter has started
  Future<bool> checkForQuarterTransition() async {
    try {
      final docRef = _firestore.collection('system').doc('quarterly_status');
      final doc = await docRef.get();

      if (!doc.exists) {
        // Initialize if document doesn't exist
        await _initializeQuarterlyStatus();
        return false;
      }

      final data = doc.data()!;
      final lastQuarter = data['last_quarter'] as int;
      final lastYear = data['last_year'] as int;

      final currentQuarter = getCurrentQuarter();
      final currentYear = getCurrentYear();

      // Check if quarter or year has changed
      if (currentQuarter != lastQuarter || currentYear != lastYear) {
        await _processQuarterlyTransition(
            lastQuarter, lastYear, currentQuarter, currentYear);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Initialize quarterly status document
  Future<void> _initializeQuarterlyStatus() async {
    final docRef = _firestore.collection('system').doc('quarterly_status');
    final currentQuarter = getCurrentQuarter();
    final currentYear = getCurrentYear();

    await docRef.set({
      'last_quarter': currentQuarter,
      'last_year': currentYear,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  // Process quarterly transition
  Future<void> _processQuarterlyTransition(
    int lastQuarter,
    int lastYear,
    int currentQuarter,
    int currentYear,
  ) async {
    try {
      // 1. Finalize previous quarter's data
      await _finalizeQuarterData(lastQuarter, lastYear);

      // 2. Initialize new quarter's data
      await _initializeNewQuarter(currentQuarter, currentYear);

      // 3. Update quarterly status
      await _updateQuarterlyStatus(currentQuarter, currentYear);
    } catch (e) {
      rethrow;
    }
  }

  // Finalize data for the previous quarter
  Future<void> _finalizeQuarterData(int quarter, int year) async {
    final usersSnapshot = await _firestore.collection('users').get();
    final batch = _firestore.batch();

    for (final userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final performanceRef =
          _firestore.collection('user_performance').doc(userId);

      // Calculate and store final metrics for the quarter
      final metrics = await _calculateQuarterlyMetrics(userId, quarter, year);

      batch.set(
        performanceRef,
        {
          '$year-Q$quarter': metrics,
          'last_updated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  // Calculate metrics for a quarter
  Future<Map<String, dynamic>> _calculateQuarterlyMetrics(
      String userId, int quarter, int year) async {
    final dateRange = getQuarterDateRange(year, quarter);

    // Query tasks for the user in the quarter
    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .where('dueDate', isGreaterThanOrEqualTo: dateRange['start'])
        .where('dueDate', isLessThanOrEqualTo: dateRange['end']!)
        .get();

    final tasks = tasksSnapshot.docs;
    final completedTasks =
        tasks.where((t) => t['status'] == 'completed').toList();
    final onTimeTasks = completedTasks.where((t) {
      final dueDate = (t['dueDate'] as Timestamp).toDate();
      final completedAt = (t['completedAt'] as Timestamp?)?.toDate();
      return completedAt != null && !completedAt.isAfter(dueDate);
    }).toList();

    // Calculate metrics
    final totalTasks = tasks.length;
    final completedCount = completedTasks.length;
    final onTimeRate =
        totalTasks > 0 ? (onTimeTasks.length / totalTasks * 100).round() : 0;

    // Calculate average rating if applicable
    double avgRating = 0;
    if (completedTasks.isNotEmpty) {
      final ratings = completedTasks
          .where((t) => t['rating'] != null)
          .map((t) => (t['rating'] as num).toDouble())
          .toList();

      if (ratings.isNotEmpty) {
        avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }
    }

    return {
      'tasks_assigned': totalTasks,
      'tasks_completed': completedCount,
      'on_time_rate': onTimeRate,
      'avg_rating': avgRating,
      'quarter': quarter,
      'year': year,
      'calculated_at': FieldValue.serverTimestamp(),
    };
  }

  // Initialize data for a new quarter
  Future<void> _initializeNewQuarter(int quarter, int year) async {
    // Any initialization needed for the new quarter
    // For example, you might want to reset certain counters or statuses
  }

  // Update quarterly status in Firestore
  Future<void> _updateQuarterlyStatus(int quarter, int year) async {
    final docRef = _firestore.collection('system').doc('quarterly_status');

    await docRef.update({
      'last_quarter': quarter,
      'last_year': year,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  // Get current quarter and year as a formatted string (e.g., "Q1 2023")
  String getCurrentQuarterYearString() {
    final quarter = getCurrentQuarter();
    final year = getCurrentYear();
    return 'Q$quarter $year';
  }

  // Get quarter and year as a formatted string for a specific date
  String getQuarterYearString(DateTime date) {
    final quarter = (date.month - 1) ~/ 3 + 1;
    return 'Q$quarter ${date.year}';
  }
}
