import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/widgets/app_bar.dart';
import 'package:task/widgets/empty_state_widget.dart';
import 'package:task/widgets/error_state_widget.dart';
import 'package:task/widgets/filter_bar.dart';
import 'package:task/widgets/task_card.dart';
import 'package:task/widgets/task_detail_sheet.dart';
import 'package:task/widgets/task_skeleton_list.dart';
import 'package:task/widgets/user_nav_bar.dart';


class AllTaskScreen extends StatefulWidget {
  AllTaskScreen({super.key});

  @override
  State<AllTaskScreen> createState() => _AllTaskScreenState();
}

class _AllTaskScreenState extends State<AllTaskScreen> {
  final TaskController taskController = Get.put(TaskController());
  final AuthController authController = Get.find<AuthController>();

  final int pageSize = 10;
  String searchTerm = '';
  String filterStatus = 'All';
  String sortBy = 'Newest';
  DocumentSnapshot? lastDocument;
  bool isLoadingMore = false;
  bool hasMore = true;
  List<DocumentSnapshot> loadedTasks = [];
  final Map<String, Map<String, dynamic>> userCache = {};

  @override
  void initState() {
    super.initState();
    _loadInitialTasks();
  }

  Future<void> _loadInitialTasks() async {
    setState(() {
      loadedTasks = [];
      lastDocument = null;
      hasMore = true;
      isLoadingMore = false;
    });
    await _loadMoreTasks();
  }

  Future<void> _loadMoreTasks() async {
    if (!hasMore || isLoadingMore) return;
    setState(() => isLoadingMore = true);
    Query query = FirebaseFirestore.instance
        .collection('tasks')
        .orderBy('timestamp', descending: sortBy == "Newest")
        .limit(pageSize);
    if (lastDocument != null) query = query.startAfterDocument(lastDocument!);
    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      loadedTasks.addAll(snapshot.docs);
      lastDocument = snapshot.docs.last;
      if (snapshot.docs.length < pageSize) hasMore = false;
    } else {
      hasMore = false;
    }
    setState(() => isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLargeScreen = media.size.width > 600;
    final textScale = media.textScaleFactor;
    final basePadding = isLargeScreen ? 32.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/create_task'),
        backgroundColor: const Color(0xFF171FA0),
        tooltip: "Create New Task",
        child: const Icon(Icons.add, color: Colors.white, semanticLabel: 'Add Task'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                AppBarWidget(basePadding: basePadding),
                FilterBarWidget(
                  basePadding: basePadding,
                  textScale: textScale,
                  filterStatus: filterStatus,
                  sortBy: sortBy,
                  onSearch: (val) => setState(() => searchTerm = val.trim()),
                  onFilter: (val) => setState(() {
                    filterStatus = val!;
                    _loadInitialTasks();
                  }),
                  onSort: (val) => setState(() {
                    sortBy = val!;
                    _loadInitialTasks();
                  }),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF171FA0),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 32 : 8, vertical: 20),
                    child: RefreshIndicator(
                      onRefresh: _loadInitialTasks,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (!isLoadingMore && hasMore && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
                            _loadMoreTasks();
                          }
                          return false;
                        },
                        child: loadedTasks.isEmpty
                            ? TaskSkeletonList(isLargeScreen: isLargeScreen, textScale: textScale)
                            : FutureBuilder<List<Map<String, dynamic>>>(
                                future: _addCreatorNames(loadedTasks),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return TaskSkeletonList(isLargeScreen: isLargeScreen, textScale: textScale);
                                  }
                                  if (snapshot.hasError) {
                                    return const ErrorStateWidget(message: "Something went wrong loading users.");
                                  }
                                  var filteredTasks = snapshot.data!
                                      .where((task) =>
                                          (searchTerm.isEmpty ||
                                            task['creatorName']
                                                .toString()
                                                .toLowerCase()
                                                .contains(searchTerm.toLowerCase())) &&
                                          (filterStatus == "All" ||
                                            (task['status']?.toString().toLowerCase() == filterStatus.toLowerCase())))
                                      .toList();
                                  if (sortBy == "Oldest") {
                                    filteredTasks = filteredTasks.reversed.toList();
                                  }
                                  if (filteredTasks.isEmpty) {
                                    return const EmptyStateWidget();
                                  }
                                  return ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: filteredTasks.length + (hasMore ? 1 : 0),
                                    separatorBuilder: (_, __) => const Divider(
                                      color: Colors.black12,
                                      thickness: 1,
                                      indent: 16,
                                      endIndent: 16,
                                    ),
                                    itemBuilder: (context, index) {
                                      if (index >= filteredTasks.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      final data = filteredTasks[index];
                                      return TaskCard(
                                        data: data,
                                        isLargeScreen: isLargeScreen,
                                        textScale: textScale,
                                        onTap: () => showModalBottomSheet(
                                          context: context,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                          ),
                                          builder: (_) => TaskDetailSheet(data: data, textScale: textScale),
                                        ),
                                        onAction: (choice) => _handleTaskAction(choice, data, context),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const UserNavBar(currentIndex: 1),
    );
  }

  Future<List<Map<String, dynamic>>> _addCreatorNames(List<DocumentSnapshot> tasks) async {
    List<Map<String, dynamic>> enrichedTasks = [];
    for (var task in tasks) {
      final data = task.data() as Map<String, dynamic>;
      final createdBy = data['createdBy'] ?? '';
      String creatorName = createdBy;
      String? creatorAvatar;
      if (createdBy.isNotEmpty) {
        if (userCache.containsKey(createdBy)) {
          creatorName = userCache[createdBy]!['name'];
          creatorAvatar = userCache[createdBy]!['avatar'];
        } else {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(createdBy).get();
          final userData = userDoc.data();
          if (userData != null) {
            creatorName = userData['name'] ?? userData['displayName'] ?? userData['fullName'] ?? createdBy;
            creatorAvatar = userData['photoURL'] ?? userData['avatarUrl'];
            userCache[createdBy] = {'name': creatorName, 'avatar': creatorAvatar};
          }
        }
      }
      enrichedTasks.add({...data, 'creatorName': creatorName, 'creatorAvatar': creatorAvatar});
    }
    return enrichedTasks;
  }

  Future<void> _handleTaskAction(String choice, Map<String, dynamic> taskData, BuildContext context) async {
    if (choice == 'Edit') {
      Get.toNamed('/edit_task', arguments: taskData);
    } else if (choice == 'Delete') {
      bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete Task"),
          content: const Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
          ],
        ),
      );
      if (confirm == true) {
        await FirebaseFirestore.instance.collection('tasks').doc(taskData['taskId']).delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task deleted")));
      }
    } else if (choice == 'Mark as Completed') {
      await FirebaseFirestore.instance.collection('tasks').doc(taskData['taskId']).update({"status": "Completed"});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task marked as completed")));
    }
  }
}