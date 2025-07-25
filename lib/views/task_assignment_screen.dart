// views/task_assignment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';

class TaskAssignmentScreen extends StatelessWidget {
  final TaskController taskController = Get.find<TaskController>();
  final UserController userController = Get.find<UserController>();
  final AuthController authController = Get.find<AuthController>();

  TaskAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Use app theme's default background for the scaffold
    final scaffoldBg = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Tasks"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      backgroundColor: scaffoldBg,
      body: Obx(() {
        // Add safety check to ensure controllers are registered
        if (!Get.isRegistered<TaskController>() || !Get.isRegistered<AuthController>()) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (taskController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (taskController.tasks.isEmpty) {
          return Center(
            child: Text(
              "No tasks available",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          );
        }

        return Column(
          children: [
            if (authController.canAssignTask)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                  icon: const Icon(Icons.add_task),
                  label: const Text("Assign Task"),
                  onPressed: () => _showAssignmentDialog(
                      context, null, colorScheme, scaffoldBg),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: taskController.tasks.length,
                itemBuilder: (context, index) {
                  final task = taskController.tasks[index];

                  return Card(
                    color: colorScheme.surface,
                    elevation: 3,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        task.description,
                        style: TextStyle(
                            color: colorScheme.onSurface),
                      ),
                      trailing: authController.canAssignTask
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              onPressed: () => _showAssignmentDialog(context,
                                  task.taskId, colorScheme, scaffoldBg),
                              child: const Text("Assign"),
                            )
                          : Text(
                              "No Permission",
                              style: TextStyle(
                                  color: colorScheme.onSurface),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showAssignmentDialog(BuildContext context, String? taskId,
      ColorScheme colorScheme, Color scaffoldBg) {
    String? selectedTaskId = taskId;
    String? selectedReporterId;
    String? selectedReporterName;
    String? selectedCameramanId;
    String? selectedCameramanName;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        height: 480,
        decoration: BoxDecoration(
          color: scaffoldBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Assign Task",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),

            // Select Task (if not already picked)
            if (taskId == null)
              Obx(() {
                // Add safety check to ensure controller is registered
                if (!Get.isRegistered<TaskController>()) {
                  return Text("Loading tasks...",
                      style: TextStyle(color: colorScheme.onSurface));
                }
                
                final unassignedTasks = taskController.tasks
                    .where((task) =>
                                    (task.assignedReporterId == null ||
            task.assignedReporterId!.isEmpty) &&
            (task.assignedCameramanId == null ||
            task.assignedCameramanId!.isEmpty) &&
            (task.assignedDriverId == null ||
            task.assignedDriverId!.isEmpty) &&
            (task.assignedLibrarianId == null ||
            task.assignedLibrarianId!.isEmpty))
                    .toList();

                if (unassignedTasks.isEmpty) {
                  return Text("No unassigned tasks available",
                      style: TextStyle(color: colorScheme.onSurface));
                }
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Task",
                    labelStyle: TextStyle(color: colorScheme.primary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                  dropdownColor: scaffoldBg,
                  items: unassignedTasks
                      .map<DropdownMenuItem<String>>((task) => DropdownMenuItem(
                            value: task.taskId,
                            child: Text(task.title,
                                style: TextStyle(color: colorScheme.onSurface)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    selectedTaskId = value!;
                  },
                );
              }),

            const SizedBox(height: 10),

            // Assign to Reporter Dropdown
            Obx(() {
              // Add safety check to ensure controller is registered
              if (!Get.isRegistered<UserController>()) {
                return Text("Loading reporters...",
                    style: TextStyle(color: colorScheme.onSurface));
              }
              
              if (userController.reporters.isEmpty) {
                return Text("No reporters available",
                    style: TextStyle(color: colorScheme.onSurface));
              }
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Assign to Reporter",
                  labelStyle: TextStyle(color: colorScheme.primary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
                dropdownColor: scaffoldBg,
                items: userController.reporters
                    .map<DropdownMenuItem<String>>((reporter) {
                  return DropdownMenuItem<String>(
                    value: reporter["id"],
                    child: Text(reporter["name"],
                        style: TextStyle(color: colorScheme.onSurface)),
                  );
                }).toList(),
                onChanged: (value) {
                  final reporter = userController.reporters
                      .firstWhere((r) => r["id"] == value, orElse: () => {});
                  selectedReporterId = value;
                  selectedReporterName =
                      reporter.isNotEmpty ? reporter["name"] : null;
                },
              );
            }),

            const SizedBox(height: 10),

            // Assign to Cameraman Dropdown
            Obx(() {
              // Add safety check to ensure controller is registered
              if (!Get.isRegistered<UserController>()) {
                return Text("Loading cameramen...",
                    style: TextStyle(color: colorScheme.onSurface));
              }
              
              if (userController.cameramen.isEmpty) {
                return Text("No cameramen available",
                    style: TextStyle(color: colorScheme.onSurface));
              }
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Assign to Cameraman",
                  labelStyle: TextStyle(color: colorScheme.primary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
                dropdownColor: scaffoldBg,
                items: userController.cameramen
                    .map<DropdownMenuItem<String>>((cameraman) {
                  return DropdownMenuItem<String>(
                    value: cameraman["id"],
                    child: Text(cameraman["name"],
                        style: TextStyle(color: colorScheme.onSurface)),
                  );
                }).toList(),
                onChanged: (value) {
                  final cameraman = userController.cameramen
                      .firstWhere((c) => c["id"] == value, orElse: () => {});
                  selectedCameramanId = value;
                  selectedCameramanName =
                      cameraman.isNotEmpty ? cameraman["name"] : null;
                },
              );
            }),

            const SizedBox(height: 20),

            // Assign button
            Obx(() {
              // Add safety check to ensure controllers are registered
              if (!Get.isRegistered<TaskController>() || !Get.isRegistered<SettingsController>()) {
                return Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: () {},
                    child: const Text("Assign Task"),
                  ),
                );
              }
              
              return Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: () async {
                    Get.find<SettingsController>().triggerFeedback();

                    if (selectedTaskId == null ||
                        (selectedReporterId == null &&
                            selectedCameramanId == null)) {
                      Get.snackbar("Error",
                          "Please select a task and at least one assignee.");
                      return;
                    }

                    try {
                      // Close the dialog BEFORE calling the assignment
                      Get.back();

                      await taskController.assignTaskWithNames(
                        taskId: selectedTaskId!,
                        reporterId: selectedReporterId,
                        reporterName: selectedReporterName,
                        cameramanId: selectedCameramanId,
                        cameramanName: selectedCameramanName,
                      );

                      // Show success message
                      Get.snackbar("Success", "Task assigned successfully!");
                    } catch (e) {
                      Get.snackbar("Error", "Failed to assign task: $e");
                    }
                  },

                  child: const Text("Assign Task"),
                ),
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
