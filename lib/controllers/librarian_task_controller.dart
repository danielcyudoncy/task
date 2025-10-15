// controllers/librarian_task_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class LibrarianTaskController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables
  var completedTasks = <Map<String, dynamic>>[].obs;
  var uncompletedTasks = <Map<String, dynamic>>[].obs;
  var archivedTasks = <Map<String, dynamic>>[].obs;

  var searchResults = <Map<String, dynamic>>[].obs;
  var isSearching = false.obs;
  var searchQuery = ''.obs;

  var isLoading = false.obs;
  var filterTags = <String>[].obs;
  var filterCategories = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompletedTasks();
    fetchUncompletedTasks();
    fetchArchivedTasks();
  }

  /// Fetch tasks marked as completed
  Future<void> fetchCompletedTasks() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .get();

      completedTasks.value = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch tasks not yet completed
  Future<void> fetchUncompletedTasks() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .get();

      uncompletedTasks.value = snapshot.docs
          .where((doc) => doc.data()['status'] != 'completed')
          .map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch archived tasks
  Future<void> fetchArchivedTasks() async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('archived', isEqualTo: true)
          .orderBy('archivedAt', descending: true)
          .get();

      archivedTasks.value = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      debugPrint('LibrarianTaskController: Error fetching archived tasks: $e');
    }
  }

  /// Archive a task
  Future<void> markAsArchived(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'archived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'status': 'archived',
      });
      await fetchArchivedTasks();
      await fetchCompletedTasks(); // remove from active
    } catch (e) {
      debugPrint('LibrarianTaskController: Error archiving task $taskId: $e');
    }
  }

  /// Tag and categorize a task
  Future<void> updateTaskTagsAndCategories({
    required String taskId,
    List<String>? tags,
    String? category,
  }) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        if (tags != null) 'tags': tags,
        if (category != null) 'category': category,
      });
      await refreshAll();
    } catch (e) {
      debugPrint('LibrarianTaskController: Error updating task tags/categories for $taskId: $e');
    }
  }

  /// Full-text style search across titles, tags, descriptions
  Future<void> searchTasks(String query) async {
    isSearching.value = true;
    searchQuery.value = query;

    try {
      final snapshot = await _firestore.collection('tasks').get();
      final allTasks = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      });

      searchResults.value = allTasks.where((task) {
        final title = (task['title'] ?? '').toString().toLowerCase();
        final desc = (task['description'] ?? '').toString().toLowerCase();
        final tags = (task['tags'] ?? []).join(',').toLowerCase();
        final queryLower = query.toLowerCase();

        return title.contains(queryLower) ||
            desc.contains(queryLower) ||
            tags.contains(queryLower);
      }).toList();
    } finally {
      isSearching.value = false;
    }
  }

  /// Apply filters
  List<Map<String, dynamic>> applyFilters(List<Map<String, dynamic>> tasks) {
    return tasks.where((task) {
      final taskTags = List<String>.from(task['tags'] ?? []);
      final taskCategory = task['category'] ?? '';

      final matchesTags =
          filterTags.isEmpty || filterTags.any((tag) => taskTags.contains(tag));
      final matchesCategory =
          filterCategories.isEmpty || filterCategories.contains(taskCategory);

      return matchesTags && matchesCategory;
    }).toList();
  }

  /// Refresh all views
  Future<void> refreshAll() async {
    await fetchCompletedTasks();
    await fetchUncompletedTasks();
    await fetchArchivedTasks();
  }

  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
  }

  /// Get filtered & searched view
  List<Map<String, dynamic>> get visibleTasks {
    final baseList = searchQuery.isEmpty ? completedTasks : searchResults;
    return applyFilters(baseList);
  }
}
