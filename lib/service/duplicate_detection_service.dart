// service/duplicate_detection_service.dart
import 'package:get/get.dart';
import 'package:task/models/task_model.dart';
import 'package:task/service/isar_task_service.dart';

class DuplicateDetectionService extends GetxService {
  static DuplicateDetectionService get to => Get.find();
  
  final IsarTaskService _isarTaskService;
  bool _isInitialized = false;
  
  DuplicateDetectionService({
    IsarTaskService? isarTaskService,
  }) : _isarTaskService = isarTaskService ?? Get.find<IsarTaskService>();

  /// Initializes the duplicate detection service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      Get.log('DuplicateDetectionService: Initializing...');
      _isInitialized = true;
      Get.log('DuplicateDetectionService: Initialized successfully');
    } catch (e) {
      Get.log('DuplicateDetectionService: Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Checks for potential duplicates when creating a new task
  Future<List<Task>> findPotentialDuplicates({
    required String title,
    required String description,
    String? category,
    List<String>? tags,
    double similarityThreshold = 0.7,
  }) async {
    if (!_isInitialized) {
      throw Exception('DuplicateDetectionService not initialized');
    }

    try {
      // Get all tasks from local storage first (faster)
      final localTasks = await _isarTaskService.getAllTasks();
      final potentialDuplicates = <Task>[];

      for (final task in localTasks) {
        final similarity = _calculateTaskSimilarity(
          title: title,
          description: description,
          category: category,
          tags: tags ?? [],
          existingTask: task,
        );

        if (similarity >= similarityThreshold) {
          potentialDuplicates.add(task);
        }
      }

      // Sort by similarity score (highest first)
      potentialDuplicates.sort((a, b) {
        final similarityA = _calculateTaskSimilarity(
          title: title,
          description: description,
          category: category,
          tags: tags ?? [],
          existingTask: a,
        );
        final similarityB = _calculateTaskSimilarity(
          title: title,
          description: description,
          category: category,
          tags: tags ?? [],
          existingTask: b,
        );
        return similarityB.compareTo(similarityA);
      });

      return potentialDuplicates.take(5).toList(); // Return top 5 matches
    } catch (e) {
      Get.log('Error finding potential duplicates: $e');
      return [];
    }
  }

  /// Finds exact duplicates based on title and description
  Future<List<Task>> findExactDuplicates({
    required String title,
    required String description,
  }) async {
    if (!_isInitialized) {
      throw Exception('DuplicateDetectionService not initialized');
    }

    try {
      final normalizedTitle = _normalizeText(title);
      final normalizedDescription = _normalizeText(description);

      // Check local storage first
      final localTasks = await _isarTaskService.getAllTasks();
      final exactDuplicates = localTasks.where((task) {
        final taskTitle = _normalizeText(task.title);
        final taskDescription = _normalizeText(task.description);
        
        return taskTitle == normalizedTitle && 
               taskDescription == normalizedDescription;
      }).toList();

      return exactDuplicates;
    } catch (e) {
      Get.log('Error finding exact duplicates: $e');
      return [];
    }
  }

  /// Calculates similarity score between two tasks
  double _calculateTaskSimilarity({
    required String title,
    required String description,
    String? category,
    required List<String> tags,
    required Task existingTask,
  }) {
    double totalScore = 0.0;
    int factors = 0;

    // Title similarity (weight: 40%)
    final titleSimilarity = _calculateTextSimilarity(title, existingTask.title);
    totalScore += titleSimilarity * 0.4;
    factors++;

    // Description similarity (weight: 30%)
    final descriptionSimilarity = _calculateTextSimilarity(description, existingTask.description);
    totalScore += descriptionSimilarity * 0.3;
    factors++;

    // Category similarity (weight: 15%)
    if (category != null && existingTask.category != null) {
      final categorySimilarity = category.toLowerCase() == existingTask.category!.toLowerCase() ? 1.0 : 0.0;
      totalScore += categorySimilarity * 0.15;
      factors++;
    }

    // Tags similarity (weight: 15%)
    if (tags.isNotEmpty && existingTask.tags.isNotEmpty) {
      final tagsSimilarity = _calculateTagsSimilarity(tags, existingTask.tags);
      totalScore += tagsSimilarity * 0.15;
      factors++;
    }

    return factors > 0 ? totalScore : 0.0;
  }

  /// Calculates text similarity using Jaccard similarity
  double _calculateTextSimilarity(String text1, String text2) {
    if (text1.isEmpty && text2.isEmpty) return 1.0;
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    final words1 = _normalizeText(text1).split(' ').where((w) => w.isNotEmpty).toSet();
    final words2 = _normalizeText(text2).split(' ').where((w) => w.isNotEmpty).toSet();

    if (words1.isEmpty && words2.isEmpty) return 1.0;
    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    return intersection / union;
  }

  /// Calculates tags similarity
  double _calculateTagsSimilarity(List<String> tags1, List<String> tags2) {
    if (tags1.isEmpty && tags2.isEmpty) return 1.0;
    if (tags1.isEmpty || tags2.isEmpty) return 0.0;

    final normalizedTags1 = tags1.map((tag) => tag.toLowerCase().trim()).toSet();
    final normalizedTags2 = tags2.map((tag) => tag.toLowerCase().trim()).toSet();

    final intersection = normalizedTags1.intersection(normalizedTags2).length;
    final union = normalizedTags1.union(normalizedTags2).length;

    return intersection / union;
  }

  /// Normalizes text for comparison
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Checks if a task is a potential duplicate before saving
  Future<DuplicateCheckResult> checkForDuplicatesBeforeSave({
    required String title,
    required String description,
    String? category,
    List<String>? tags,
  }) async {
    try {
      // Check for exact duplicates first
      final exactDuplicates = await findExactDuplicates(
        title: title,
        description: description,
      );

      if (exactDuplicates.isNotEmpty) {
        return DuplicateCheckResult(
          hasExactDuplicates: true,
          exactDuplicates: exactDuplicates,
          potentialDuplicates: [],
          recommendation: DuplicateRecommendation.block,
        );
      }

      // Check for potential duplicates
      final potentialDuplicates = await findPotentialDuplicates(
        title: title,
        description: description,
        category: category,
        tags: tags,
        similarityThreshold: 0.7,
      );

      if (potentialDuplicates.isNotEmpty) {
        // Calculate highest similarity score
        double highestSimilarity = 0.0;
        for (final task in potentialDuplicates) {
          final similarity = _calculateTaskSimilarity(
            title: title,
            description: description,
            category: category,
            tags: tags ?? [],
            existingTask: task,
          );
          if (similarity > highestSimilarity) {
            highestSimilarity = similarity;
          }
        }

        DuplicateRecommendation recommendation;
        if (highestSimilarity >= 0.9) {
          recommendation = DuplicateRecommendation.block;
        } else if (highestSimilarity >= 0.8) {
          recommendation = DuplicateRecommendation.warn;
        } else {
          recommendation = DuplicateRecommendation.suggest;
        }

        return DuplicateCheckResult(
          hasExactDuplicates: false,
          exactDuplicates: [],
          potentialDuplicates: potentialDuplicates,
          recommendation: recommendation,
          highestSimilarityScore: highestSimilarity,
        );
      }

      return DuplicateCheckResult(
        hasExactDuplicates: false,
        exactDuplicates: [],
        potentialDuplicates: [],
        recommendation: DuplicateRecommendation.allow,
      );
    } catch (e) {
      Get.log('Error checking for duplicates: $e');
      // In case of error, allow the task to be created
      return DuplicateCheckResult(
        hasExactDuplicates: false,
        exactDuplicates: [],
        potentialDuplicates: [],
        recommendation: DuplicateRecommendation.allow,
      );
    }
  }

  /// Bulk duplicate detection for existing tasks
  Future<Map<String, List<Task>>> findAllDuplicateGroups() async {
    if (!_isInitialized) {
      throw Exception('DuplicateDetectionService not initialized');
    }

    try {
      final allTasks = await _isarTaskService.getAllTasks();
      final duplicateGroups = <String, List<Task>>{};
      final processedTasks = <String>{};

      for (int i = 0; i < allTasks.length; i++) {
        final task = allTasks[i];
        if (processedTasks.contains(task.taskId)) continue;

        final duplicates = <Task>[task];
        processedTasks.add(task.taskId);

        for (int j = i + 1; j < allTasks.length; j++) {
          final otherTask = allTasks[j];
          if (processedTasks.contains(otherTask.taskId)) continue;

          final similarity = _calculateTaskSimilarity(
            title: task.title,
            description: task.description,
            category: task.category,
            tags: task.tags,
            existingTask: otherTask,
          );

          if (similarity >= 0.8) {
            duplicates.add(otherTask);
            processedTasks.add(otherTask.taskId);
          }
        }

        if (duplicates.length > 1) {
          duplicateGroups[task.taskId] = duplicates;
        }
      }

      return duplicateGroups;
    } catch (e) {
      Get.log('Error finding duplicate groups: $e');
      return {};
    }
  }
}

/// Result of duplicate check
class DuplicateCheckResult {
  final bool hasExactDuplicates;
  final List<Task> exactDuplicates;
  final List<Task> potentialDuplicates;
  final DuplicateRecommendation recommendation;
  final double? highestSimilarityScore;

  DuplicateCheckResult({
    required this.hasExactDuplicates,
    required this.exactDuplicates,
    required this.potentialDuplicates,
    required this.recommendation,
    this.highestSimilarityScore,
  });

  bool get hasDuplicates => hasExactDuplicates || potentialDuplicates.isNotEmpty;
}

/// Recommendation for handling duplicates
enum DuplicateRecommendation {
  allow,    // No significant duplicates found
  suggest,  // Low similarity, suggest reviewing
  warn,     // Medium similarity, warn user
  block,    // High similarity, block creation
}