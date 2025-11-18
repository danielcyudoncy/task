// controllers/admin_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/models/task.dart';
import 'package:task/utils/snackbar_utils.dart';
import 'package:task/service/fcm_service.dart';
import 'package:task/service/enhanced_notification_service.dart';
import 'package:task/service/user_cache_service.dart';
import 'package:task/service/audit_service.dart';

class AdminController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Warning 1: Use const constructors for Rx variables
  final adminName = ''.obs;
  final adminEmail = ''.obs;
  final adminPhotoUrl = ''.obs;
  final adminCreationDate = ''.obs;
  final adminPrivileges = <String>[].obs;

  final totalUsers = 0.obs;
  final totalTasks = 0.obs;
  final completedTasks = 0.obs;
  final pendingTasks = 0.obs;
  final overdueTasks = 0.obs;
  final onlineUsers = 0.obs;
  final totalConversations = 0.obs;
  final newsCount = 0.obs;

  final userNames = <String>[].obs;
  final taskTitles = <String>[].obs;
  final completedTaskTitles = <String>[].obs;
  final pendingTaskTitles = <String>[].obs;
  final overdueTaskTitles = <String>[].obs;

  final isLoading = false.obs;
  final isProfileLoading = false.obs;
  final isStatsLoading = false.obs;
  final userList = <Map<String, String>>[].obs;

  final selectedUserName = ''.obs;
  final selectedTaskTitle = ''.obs;

  final taskSnapshotDocs = <Map<String, dynamic>>[].obs;

  // Warning 2: Use final for RxMap
  final RxMap<String, dynamic> statistics = <String, dynamic>{}.obs;

  // Warning 3: Proper nullable type annotation
  StreamSubscription<QuerySnapshot>? _dashboardMetricsSubscription;

  // Warning 4: Add const where applicable
  void _safeSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  // Remove the unused _safeFetchAdminProfile method
  @override
  void onInit() {
    super.onInit();

    // Warning 6: Use proper type annotations
    ever(AuthController.to.user, (User? user) {
      if (user != null) {
        fetchDashboardData();

        if (AuthController.to.isAdmin.value) {
          startRealtimeUpdates();
          initializeAdminData();
        } else {
          once(AuthController.to.userRole, (String role) {
            if (role == 'Admin') {
              startRealtimeUpdates();
              initializeAdminData();
            }
          });
        }
      } else {
        _dashboardMetricsSubscription?.cancel();
        _dashboardMetricsSubscription = null;
        clearAdminData();
      }
    });

    // Warning 7: Simplify conditional logic
    // Only initialize admin data when the currently signed-in user is an admin.
    if (_auth.currentUser != null) {
      fetchDashboardData();
      if (AuthController.to.isAdmin.value) {
        startRealtimeUpdates();
        // Initialize admin-specific data only for admins
        initializeAdminData();
      }
    }
  }

  void startRealtimeUpdates() {
    _dashboardMetricsSubscription?.cancel();

    _dashboardMetricsSubscription = _firestore
        .collection('dashboard_metrics')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      try {
        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data() as Map<String, dynamic>?;
          totalUsers.value = data?['totalUsers'] ?? totalUsers.value;
          totalTasks.value = data?['tasks']?['total'] ?? totalTasks.value;
          completedTasks.value =
              data?['tasks']?['completed'] ?? completedTasks.value;
          pendingTasks.value = data?['tasks']?['pending'] ?? pendingTasks.value;
          overdueTasks.value = data?['tasks']?['overdue'] ?? overdueTasks.value;

          statistics['users'] = totalUsers.value;
          statistics['tasks'] = totalTasks.value;
          statistics['completed'] = completedTasks.value;
          statistics['pending'] = pendingTasks.value;
          statistics['overdue'] = overdueTasks.value;
        }
      } catch (e) {
        debugPrint('Error processing dashboard metrics snapshot: $e');
      }
    }, onError: (Object e) {
      if (e.toString().contains('permission-denied')) {
        _safeSnackbar('Access Denied', "You don't have access to this data.");
      } else {
        debugPrint('Dashboard metrics stream error: $e');
      }
    });
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    try {
      final querySnapshot = await _firestore.collection('tasks').get();
      final allDocs = querySnapshot.docs.map((QueryDocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      try {
        final userCacheService = Get.find<UserCacheService>();
        for (final data in allDocs) {
          final creatorId =
              (data['createdById'] ?? data['createdBy'] ?? '').toString();
          if (creatorId.isNotEmpty) {
            final name = userCacheService.getUserNameSync(creatorId);
            if (name != 'Unknown User') {
              data['createdByName'] = name;
              data['creatorName'] = name;
            }
          }
        }
      } catch (e) {
        // If cache service not available, skip enrichment.
      }

      taskSnapshotDocs.assignAll(allDocs);
      pendingTaskTitles.clear();
      completedTaskTitles.clear();

      for (final doc in allDocs) {
        final title = doc['title'] ?? '';
        final status = (doc['status'] ?? '').toString().toLowerCase();

        bool isTaskCompleted = false;
        if (status == 'completed') {
          final completedByUserIds =
              List<String>.from(doc['completedByUserIds'] ?? []);
          final assignedUserIds = <String>[];

          if (doc['assignedReporterId'] != null &&
              doc['assignedReporterId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedReporterId'].toString());
          }
          if (doc['assignedCameramanId'] != null &&
              doc['assignedCameramanId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedCameramanId'].toString());
          }
          if (doc['assignedDriverId'] != null &&
              doc['assignedDriverId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedDriverId'].toString());
          }
          if (doc['assignedLibrarianId'] != null &&
              doc['assignedLibrarianId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedLibrarianId'].toString());
          }

          if (assignedUserIds.isEmpty) {
            isTaskCompleted = true;
          } else if (completedByUserIds.isEmpty) {
            isTaskCompleted = true;
          } else {
            isTaskCompleted = assignedUserIds
                .every((userId) => completedByUserIds.contains(userId));
          }
        }

        if (isTaskCompleted) {
          completedTaskTitles.add(title);
        } else {
          pendingTaskTitles.add(title);
        }
      }

      totalTasks.value = allDocs.length;
      completedTasks.value = completedTaskTitles.length;
      pendingTasks.value = pendingTaskTitles.length;

      statistics['tasks'] = totalTasks.value;
      statistics['completed'] = completedTasks.value;
      statistics['pending'] = pendingTasks.value;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        _safeSnackbar('Access Denied', "You don't have access to this data.");
      } else {
        _safeSnackbar('Error', 'Failed to load dashboard data: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initializeAdminData() async {
    try {
      isLoading(true);

      // Check admin status first and silently return for non-admin users.
      final isAdmin = await verifyAdminStatus();
      if (!isAdmin) {
        debugPrint(
            'initializeAdminData: current user is not an admin, skipping admin init');
        return;
      }

      // Ensure admin access and create admin doc if needed, then fetch admin data
      await _verifyAdminAccess();
      await Future.wait([
        fetchAdminProfile(),
        fetchStatistics(),
      ]);

      if (adminName.value.isNotEmpty) {
        Get.offAllNamed('/admin-dashboard');
      }
    } catch (e) {
      debugPrint("Admin initialization error: $e");
      // Don't forcibly log the user out on admin initialization errors.
      // Just surface a non-blocking message and continue; many admin
      // initialization failures are due to timing (role not yet set) or
      // permission-denied and should not sign the user out.
      // Suppress the snackbar for expected 'Not an admin user' errors
      final msg = e.toString();
      if (!msg.contains('Not an admin user')) {
        Future.delayed(Duration.zero, () {
          if (Get.context != null) {
            _safeSnackbar("Admin Error", "Failed to initialize admin data");
          }
        });
      } else {
        debugPrint(
            'initializeAdminData: non-admin - suppressing user-facing error');
      }
    } finally {
      isLoading(false);
    }
  }

  Future<void> _verifyAdminAccess() async {
    if (!(await verifyAdminStatus())) {
      throw Exception("Not an admin user");
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("No authenticated user");

    final adminDoc = await _firestore.collection('admins').doc(userId).get();
    if (!adminDoc.exists) {
      await _createAdminProfileFromUser(userId);
    }
  }

  Future<bool> verifyAdminStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final role = userData?['role']?.toString() ?? '';

        // Check if user has admin role
        final isAdmin =
            ['Admin', 'admin', 'superadmin', 'administrator'].contains(role);
        debugPrint('Admin verification: role=$role, isAdmin=$isAdmin');

        return isAdmin;
      }

      return false;
    } catch (e) {
      debugPrint('Error verifying admin status: $e');
      return false;
    }
  }

  Future<void> _createAdminProfileFromUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData == null) {
          throw Exception("User document data is null");
        }

        // First, call the Cloud Function to set admin custom claim (server-side)
        // This ensures the custom claim is set before we create the admin doc
        try {
          debugPrint('AdminController: Calling setAdminClaim Cloud Function');
          await FirebaseFunctions.instance.httpsCallable('setAdminClaim').call({
            'uid': userId,
          });
          debugPrint('AdminController: Admin custom claim set successfully');
        } catch (e) {
          debugPrint('AdminController: Error setting admin claim: $e');
          // Continue anyway - if rule check is sufficient, admin doc creation may still work
        }

        // Now create the admin profile
        await createAdminProfile(
          userId: userId,
          fullName: userData['fullName'] ?? "Administrator",
          email: userData['email'] ?? "",
          photoUrl: userData['photoUrl'] ?? "",
        );
      } else {
        throw Exception("User document not found");
      }
    } catch (e) {
      throw Exception("Failed to create admin profile: ${e.toString()}");
    }
  }

  // In AdminController, REPLACE your fetchStatistics function with this one

  Future<void> fetchStatistics() async {
    try {
      isStatsLoading(true);
      final now = DateTime.now();

      // First, get the user data since it's most critical
      final userSnapshot = await _firestore
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 10));

      // Update user counts immediately
      final userDocs = userSnapshot.docs;
      totalUsers.value = userDocs.where((doc) {
        final userData = doc.data();
        return userData['role'] != 'Librarian' && userData['role'] != 'Admin';
      }).length;

      // Then fetch tasks, online users, conversations and news sequentially
      final taskSnapshot = await _firestore.collection('tasks').get();
      final taskDocs = taskSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      taskSnapshotDocs.assignAll(taskDocs);

      // Assign statistics based on fetched data
      totalTasks.value = taskDocs.length;

      final onlineUsersSnapshot = await _firestore
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();
      onlineUsers.value = onlineUsersSnapshot.docs.length;

      final conversationsSnapshot =
          await _firestore.collection('conversations').get();
      totalConversations.value = conversationsSnapshot.docs.length;

      final newsSnapshot = await _firestore.collection('news').get();
      newsCount.value = newsSnapshot.docs.length;

      // Updated logic: Only count tasks as completed if ALL assigned users have completed them
      completedTasks.value = taskDocs.where((doc) {
        final status = (doc['status'] ?? '').toString().toLowerCase();
        if (status == 'completed') {
          // For backward compatibility, if it's marked as completed, check if it uses new logic
          final completedByUserIds =
              List<String>.from(doc['completedByUserIds'] ?? []);
          final assignedUserIds = <String>[];

          // Collect all assigned user IDs
          if (doc['assignedReporterId'] != null &&
              doc['assignedReporterId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedReporterId'].toString());
          }
          if (doc['assignedCameramanId'] != null &&
              doc['assignedCameramanId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedCameramanId'].toString());
          }
          if (doc['assignedDriverId'] != null &&
              doc['assignedDriverId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedDriverId'].toString());
          }
          if (doc['assignedLibrarianId'] != null &&
              doc['assignedLibrarianId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedLibrarianId'].toString());
          }

          // If no users are assigned, treat as completed (backward compatibility)
          if (assignedUserIds.isEmpty) return true;

          // If completedByUserIds is empty, it's using old logic, so count as completed
          if (completedByUserIds.isEmpty) return true;

          // Check if all assigned users have completed the task
          return assignedUserIds
              .every((userId) => completedByUserIds.contains(userId));
        }
        return false;
      }).length;

      pendingTasks.value = taskDocs
          .where((doc) =>
              (doc['status'] ?? '').toString().toLowerCase() != 'completed')
          .length;
      overdueTasks.value = taskDocs.where((doc) {
        final due = doc['dueDate'];
        return due is Timestamp &&
            due.toDate().isBefore(now) &&
            (doc['status'] ?? '').toString().toLowerCase() != 'completed';
      }).length;

      // ... your existing logic for userNames, taskTitles, etc. is fine ...
      userNames.value = userDocs
          .map((doc) => doc['fullName'] ?? "Unknown User")
          .cast<String>()
          .toList();
      taskTitles.value = taskDocs
          .map((doc) => doc['title'] ?? 'Untitled')
          .cast<String>()
          .toList();

      // --- MODIFIED: Update the statistics map with the new data ---
      statistics['users'] = totalUsers.value;
      statistics['online'] = onlineUsers.value; // NEW
      statistics['conversations'] = totalConversations.value; // NEW
      statistics['news'] = newsCount.value; // NEW
      statistics['tasks'] = totalTasks.value;
      statistics['completed'] = completedTasks.value;
      statistics['pending'] = pendingTasks.value;
      statistics['overdue'] = overdueTasks.value;
    } on TimeoutException {
      _safeSnackbar('Error', 'Fetching statistics timed out');
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        _safeSnackbar("Access Denied", "You don't have access to this data.");
      } else {
        _safeSnackbar('Error', 'Failed to fetch statistics: ${e.toString()}');
      }
    } finally {
      isStatsLoading(false);
    }
  }

  void filterTasksByUser(String fullName) {
    final userTasks = taskSnapshotDocs.where((doc) =>
        (doc['createdByName']?.toString().toLowerCase() ?? '') ==
        fullName.toLowerCase());

    final now = DateTime.now();

    completedTaskTitles.value = userTasks
        .where((doc) {
          final status = (doc['status'] ?? '').toString().toLowerCase();
          if (status == 'completed') {
            // Check if all assigned users have completed the task
            final completedByUserIds =
                List<String>.from(doc['completedByUserIds'] ?? []);
            final assignedUserIds = <String>[];

            // Collect all assigned user IDs
            if (doc['assignedReporterId'] != null &&
                doc['assignedReporterId'].toString().isNotEmpty) {
              assignedUserIds.add(doc['assignedReporterId'].toString());
            }
            if (doc['assignedCameramanId'] != null &&
                doc['assignedCameramanId'].toString().isNotEmpty) {
              assignedUserIds.add(doc['assignedCameramanId'].toString());
            }
            if (doc['assignedDriverId'] != null &&
                doc['assignedDriverId'].toString().isNotEmpty) {
              assignedUserIds.add(doc['assignedDriverId'].toString());
            }
            if (doc['assignedLibrarianId'] != null &&
                doc['assignedLibrarianId'].toString().isNotEmpty) {
              assignedUserIds.add(doc['assignedLibrarianId'].toString());
            }

            // If no users are assigned, treat as completed (backward compatibility)
            if (assignedUserIds.isEmpty) return true;

            // If completedByUserIds is empty, it's using old logic, so count as completed
            if (completedByUserIds.isEmpty) return true;

            // Check if all assigned users have completed the task
            return assignedUserIds
                .every((userId) => completedByUserIds.contains(userId));
          }
          return false;
        })
        .map((doc) => doc['title'] ?? '')
        .cast<String>()
        .toList();

    pendingTaskTitles.value = userTasks
        .where((doc) =>
            (doc['status'] ?? '').toString().toLowerCase() != 'completed')
        .map((doc) => doc['title'] ?? '')
        .cast<String>()
        .toList();

    overdueTaskTitles.value = userTasks
        .where((doc) {
          final due = doc['dueDate'];
          return due is Timestamp &&
              due.toDate().isBefore(now) &&
              (doc['status'] ?? '').toString().toLowerCase() != 'completed';
        })
        .map((doc) => doc['title'] ?? '')
        .cast<String>()
        .toList();

    completedTasks.value = completedTaskTitles.length;
    pendingTasks.value = pendingTaskTitles.length;
    overdueTasks.value = overdueTaskTitles.length;

    // Update statistics map
    statistics['completed'] = completedTasks.value;
    statistics['pending'] = pendingTasks.value;
    statistics['overdue'] = overdueTasks.value;
  }

  Future<void> createAdminProfile({
    required String userId,
    required String fullName,
    required String email,
    String photoUrl = "",
    List<String> privileges = const ["full_access"],
  }) async {
    try {
      isProfileLoading(true);
      await _firestore.collection('admins').doc(userId).set({
        "uid": userId,
        "fullName": fullName,
        "email": email,
        "photoUrl": photoUrl,
        "privileges": privileges,
        "createdAt": FieldValue.serverTimestamp(),
        "lastUpdated": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      adminName.value = fullName;
      adminEmail.value = email;
      adminPhotoUrl.value = photoUrl;
      adminPrivileges.value = privileges;
      adminCreationDate.value = DateFormat('MMMM d, y').format(DateTime.now());
    } catch (e) {
      _safeSnackbar("Error", "Failed to create admin profile: ${e.toString()}");
      rethrow;
    } finally {
      isProfileLoading(false);
    }
  }

  Future<void> fetchAdminProfile() async {
    try {
      isProfileLoading(true);
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("No authenticated user");

      final adminDoc = await _firestore.collection('admins').doc(userId).get();

      if (!adminDoc.exists) {
        throw Exception("Admin document not found");
      }

      final data = adminDoc.data();
      if (data == null) {
        throw Exception("Admin document data is null");
      }

      adminName.value = data['fullName'] ?? "Administrator";
      adminEmail.value = data['email'] ?? "";
      adminPhotoUrl.value = data['photoUrl'] ?? "";
      adminPrivileges.value = List<String>.from(data['privileges'] ?? []);

      if (data['createdAt'] != null) {
        final date = (data['createdAt'] as Timestamp).toDate();
        adminCreationDate.value = DateFormat('MMMM d, y').format(date);
      }
    } catch (e) {
      _safeSnackbar("Error", "Failed to fetch admin profile: ${e.toString()}");
      rethrow;
    } finally {
      isProfileLoading(false);
    }
  }

  /// Promote a user (by uid) to Admin.
  /// This will call a server-side Cloud Function to set the admin custom claim,
  /// update the users collection role field, and create an admins profile doc.
  Future<bool> promoteUserToAdmin(String targetUid) async {
    // Ensure caller is an admin
    if (!AuthController.to.isAdmin.value) {
      _safeSnackbar('Permission Denied', 'Only admins can promote users');
      return false;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(targetUid).get();
      final userData = userDoc.data() ?? {};
      final fullName =
          (userData['fullName'] ?? userData['fullname'] ?? 'Administrator')
              .toString();
      final email = (userData['email'] ?? '').toString();
      final photoUrl =
          (userData['photoUrl'] ?? userData['photoURL'] ?? '').toString();

      // 1) Call Cloud Function to set admin custom claim (server-side check required there)
      try {
        await FirebaseFunctions.instance
            .httpsCallable('setAdminClaim')
            .call({'uid': targetUid});
      } catch (e) {
        // Log but continue — claim may be set later by an admin process
        debugPrint('promoteUserToAdmin: setAdminClaim call failed: $e');
      }

      // 2) Update Firestore user role
      await _firestore.collection('users').doc(targetUid).update({
        'role': 'Admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3) Create admins profile document
      await createAdminProfile(
        userId: targetUid,
        fullName: fullName,
        email: email,
        photoUrl: photoUrl,
      );

      // Audit log (best-effort)
      try {
        await AuditService().logUserPromotion(
          userId: targetUid,
          userEmail: email,
          userName: fullName,
        );
      } catch (e) {
        debugPrint('promoteUserToAdmin: audit log failed: $e');
      }

      _safeSnackbar('Success', 'User promoted to admin');
      return true;
    } catch (e) {
      debugPrint('promoteUserToAdmin error: $e');
      _safeSnackbar('Error', 'Failed to promote user: ${e.toString()}');
      return false;
    }
  }

  /// Demote an admin user back to a regular role (Reporter by default).
  /// Calls a server-side Cloud Function to remove admin custom claims,
  /// deletes the admins/{uid} document, and updates users/{uid}.role.
  Future<bool> demoteUserFromAdmin(String targetUid,
      {String newRole = 'Reporter'}) async {
    if (!AuthController.to.isAdmin.value) {
      _safeSnackbar('Permission Denied', 'Only admins can demote users');
      return false;
    }

    try {
      // 1) Call Cloud Function to unset admin claim
      try {
        final res = await FirebaseFunctions.instance
            .httpsCallable('unsetAdminClaim')
            .call({'uid': targetUid});
        debugPrint('demoteUserFromAdmin: unsetAdminClaim result: ${res.data}');
      } catch (e) {
        debugPrint('demoteUserFromAdmin: unsetAdminClaim failed: $e');
        // Continue best-effort: we'll still attempt to update Firestore
      }

      // 2) Update users collection role
      await _firestore.collection('users').doc(targetUid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3) Remove admins document if exists
      try {
        final adminDoc =
            await _firestore.collection('admins').doc(targetUid).get();
        if (adminDoc.exists) {
          await _firestore.collection('admins').doc(targetUid).delete();
        }
      } catch (e) {
        debugPrint('demoteUserFromAdmin: failed to delete admin doc: $e');
      }

      // Audit log
      try {
        await AuditService().logUserPromotion(
          userId: targetUid,
          userEmail: '',
          userName: '',
          // You may want to add a dedicated demotion log method; reusing promotion log with note.
        );
      } catch (e) {
        debugPrint('demoteUserFromAdmin: audit log failed: $e');
      }

      _safeSnackbar('Success', 'User demoted from admin');
      return true;
    } catch (e) {
      debugPrint('demoteUserFromAdmin error: $e');
      _safeSnackbar('Error', 'Failed to demote user: ${e.toString()}');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading(true);
      // Suppress snackbars during admin-triggered logout to avoid
      // showing permission/listener errors that happen while listeners
      // are torn down.
      try {
        SnackbarUtils.setSuppress(true);
      } catch (_) {}

      await _auth.signOut();
      clearAdminData();
      Get.offAllNamed('/login');
    } catch (e) {
      _safeSnackbar("Error", "Logout failed: ${e.toString()}");
    } finally {
      // Restore snackbar behavior after logout
      try {
        SnackbarUtils.setSuppress(false);
      } catch (_) {}
      isLoading(false);
    }
  }

  void clearAdminData() {
    adminName.value = "";
    adminEmail.value = "";
    adminPhotoUrl.value = "";
    adminCreationDate.value = "";
    adminPrivileges.clear();

    totalUsers.value = 0;
    totalTasks.value = 0;
    completedTasks.value = 0;
    pendingTasks.value = 0;
    overdueTasks.value = 0;
    newsCount.value = 0;

    userNames.clear();
    taskTitles.clear();
    completedTaskTitles.clear();
    pendingTaskTitles.clear();
    overdueTaskTitles.clear();

    selectedUserName.value = '';
    selectedTaskTitle.value = '';
    taskSnapshotDocs.clear();

    statistics.clear();
  }

  Future<void> deleteUser(String userId) async {
    try {
      isLoading(true);
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw 'User not found';

      final userData = userDoc.data();
      if (userData == null) throw 'User data is null';

      await _firestore.runTransaction((transaction) async {
        transaction.delete(_firestore.collection('users').doc(userId));
        final tasks = await _firestore
            .collection('tasks')
            .where('createdBy', isEqualTo: userId)
            .get();
        for (final task in tasks.docs) {
          transaction.delete(task.reference);
        }
      });

      _safeSnackbar("Success", "User and their tasks deleted successfully");
      fetchStatistics();
    } catch (e) {
      _safeSnackbar("Error", "Delete failed: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTasks() async {
    try {
      var snapshot = await _firestore.collection('tasks').get();
      var tasks = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['taskId'] = doc.id;
            return Task.fromMap(data);
          })
          .whereType<Task>()
          .toList();

      pendingTasks.value =
          tasks.where((task) => task.status == 'Pending').length;
      completedTasks.value =
          tasks.where((task) => task.status == 'Completed').length;
    } catch (e) {
      _safeSnackbar("Error", "Failed to fetch tasks: ${e.toString()}");
    }
  }

  /// Assign a task to a user and also store assignedName for easy display
  Future<void> assignTaskToUser({
    required String userId,
    required String assignedName,
    required String taskTitle,
    required String taskDescription,
    required DateTime dueDate,
    required String taskId,
  }) async {
    try {
      // ✅ PERMISSION CHECK: Only users with assignment privileges can assign tasks
      if (!_canAssignTask()) {
        _safeSnackbar(
          'Permission Denied',
          'You do not have permission to assign tasks. Only Admins, Assignment Editors, News Directors, and Producers can assign tasks.',
        );
        return;
      }

      // Fetch the user's role
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userRole = userDoc.data()?['role'] ?? '';
      final updateData = <String, dynamic>{
        'assignedTo': userId,
        'assignedName': assignedName,
        'assignedAt': FieldValue.serverTimestamp(),
      };
      // Set role-specific fields for robust UI updates
      if (userRole == 'Reporter') {
        updateData['assignedReporterId'] = userId;
        updateData['assignedReporterName'] = assignedName;
      } else if (userRole == 'Cameraman') {
        updateData['assignedCameramanId'] = userId;
        updateData['assignedCameramanName'] = assignedName;
      } else if (userRole == 'Driver') {
        updateData['assignedDriverId'] = userId;
        updateData['assignedDriverName'] = assignedName;
      } else if (userRole == 'Librarian') {
        updateData['assignedLibrarianId'] = userId;
        updateData['assignedLibrarianName'] = assignedName;
      }
      await _firestore.collection('tasks').doc(taskId).update(updateData);

      // ✅ AUDIT LOG: Log the task assignment
      await AuditService().logTaskAssignment(
        taskId: taskId,
        assignedToUserId: userId,
        assignedName: assignedName,
        taskTitle: taskTitle,
      );

      // Format the due date
      final String formattedDate =
          DateFormat('yyyy-MM-dd – kk:mm').format(dueDate);

      // Add notification with message field
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'task_assignment',
        'taskId': taskId,
        'title': taskTitle,
        'message': 'Description: $taskDescription\nDue: $formattedDate',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Send push notification via FCM
      await sendTaskNotification(userId, taskTitle);

      // Show local in-app notification
      try {
        final enhancedNotificationService =
            Get.find<EnhancedNotificationService>();
        enhancedNotificationService.showInfo(
          title: 'Task Assigned',
          message:
              'Task "$taskTitle" has been assigned to $assignedName\nDue: ${DateFormat('yyyy-MM-dd – kk:mm').format(dueDate)}',
          duration: const Duration(seconds: 5),
        );
      } catch (e) {
        // Enhanced notification service might not be initialized
      }

      // Refresh dashboard/task data so UI updates
      await fetchDashboardData();
    } catch (e) {
      _safeSnackbar("Error", "Failed to assign task or notify user: $e");
    }
  }

  /// Get tasks pending approval
  List<Map<String, dynamic>> get pendingApprovalTasks {
    return taskSnapshotDocs.where((task) {
      final approvalStatus = task['approvalStatus']?.toString().toLowerCase();
      return approvalStatus == null || approvalStatus == 'pending';
    }).toList();
  }

  /// Helper method to check if current user can assign tasks
  /// ✅ Only Admins, Assignment Editors, News Directors, Producers, and Heads can assign
  bool _canAssignTask() {
    final role = AuthController.to.userRole.value;
    return role == 'Admin' ||
        role == 'Assignment Editor' ||
        role == 'Head of Department' ||
        role == 'Head of Unit' ||
        role == 'News Director' ||
        role == 'Assistant News Director' ||
        role == 'Producer';
  }

  Future<void> initializeAdmin() async {
    try {
      final isAdmin = await verifyAdminStatus();

      if (!isAdmin) {
        throw Exception('Not an admin user');
      }

      // Proceed with admin initialization
      await initializeAdminData();
    } catch (e) {
      debugPrint('Admin initialization error: $e');
      // Don't throw the exception — initialization may be attempted from
      // multiple places and non-admin users are an expected case. Log and
      // continue without bubbling the error up to callers.
    }
  }

  /// Approve a task (delegates to TaskController)
  Future<void> approveTask(String taskId, {String? reason}) async {
    try {
      final taskController = Get.find<TaskController>();
      await taskController.approveTask(taskId, reason: reason);
      // Refresh dashboard data to update UI
      await fetchDashboardData();
    } catch (e) {
      _safeSnackbar("Error", "Failed to approve task: ${e.toString()}");
    }
  }

  /// Reject a task (delegates to TaskController)
  Future<void> rejectTask(String taskId, {String? reason}) async {
    try {
      final taskController = Get.find<TaskController>();
      await taskController.rejectTask(taskId, reason: reason);
      // Refresh dashboard data to update UI
      await fetchDashboardData();
    } catch (e) {
      _safeSnackbar("Error", "Failed to reject task: ${e.toString()}");
    }
  }

  @override
  void onClose() {
    // Cancel stream subscriptions to prevent memory leaks
    _dashboardMetricsSubscription?.cancel();
    _dashboardMetricsSubscription = null;

    debugPrint('AdminController: Properly disposed');
    super.onClose();
  }
}
