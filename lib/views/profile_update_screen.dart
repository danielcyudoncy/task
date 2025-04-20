// views/profile_update_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/image_picker_widget.dart'; // Import the widget

class ProfileUpdateScreen extends StatelessWidget {
  const ProfileUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              auth.completeProfile();
              auth.navigateBasedOnRole();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Obx(() => Text(
                  "Hi, ${auth.fullName.value}",
                  style: Theme.of(context).textTheme.headlineSmall,
                )),
            const SizedBox(height: 30),

            // Use the enhanced ImagePickerWidget
            ImagePickerWidget(controller: auth),

            const SizedBox(height: 40),
            Obx(() => auth.isLoading.value
                ? const CircularProgressIndicator()
                : FilledButton(
                    onPressed: () {
                      auth.completeProfile();
                      auth.navigateBasedOnRole();
                    },
                    child: const Text("Complete Profile"),
                  )),
          ],
        ),
      ),
    );
  }
}
