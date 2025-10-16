// routes/global_bindings.dart

import 'package:get/get.dart';

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    // This method is now empty.
    // All global, permanent controllers are initialized once in bootstrap.dart.
    // This file can still be used for screen-specific bindings if needed later.
    // Removed IsarTaskService registration; now handled globally in bootstrapApp.
  }
}
