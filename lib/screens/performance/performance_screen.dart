// screens/performance/performance_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:task/screens/performance/user_performance_details_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final ThemeController _themeController = Get.find<ThemeController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current quarter
  int get currentQuarter => (DateTime.now().month - 1) ~/ 3 + 1;

  // Method to refresh images by clearing cache
  void _refreshImages() {
    // Clear cached network images
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Clear CachedNetworkImage cache
    DefaultCacheManager().emptyCache();

    // Force rebuild to reload images
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // Ensure user is authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_authController.currentUser == null) {
        // Redirect to login if not authenticated
        Get.offAllNamed('/login');
      }
    });
  }

  Future<void> _signOut() async {
    try {
      await _authController.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Performance'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          // Refresh button to clear image cache
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshImages,
            tooltip: 'Refresh Images',
          ),
          // Show user email and sign out button
          if (_authController.currentUser != null)
            PopupMenuButton<String>(
              icon: Obx(() => _buildCachedAvatar(
                    imageUrl: _authController.currentUser?.photoURL,
                    fallbackText:
                        _authController.currentUser?.email?[0].toUpperCase() ??
                            'U',
                    backgroundColor: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                  )),
              onSelected: (value) {
                if (value == 'logout') {
                  _signOut();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  enabled: false,
                  child: Text(
                      'Signed in as ${_authController.currentUser?.email ?? 'User'}'),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Sign out'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').where('role', whereNotIn: [
          'admin',
          'reporter',
          'cameraman',
          'driver',
          'librarian'
        ]).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: _getTitleTextColor(context)),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No users found',
                style: TextStyle(color: _getTitleTextColor(context)),
              ),
            );
          }

          final users = snapshot.data!.docs;

          // Add a welcome message at the top of the list
          return Column(
            children: [
              if (_authController.currentUser != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Welcome, ${_authController.currentUser?.email ?? 'User'},',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _getTitleTextColor(context),
                        ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userData = user.data() as Map<String, dynamic>;
                    final fullName =
                        userData['fullName'] as String? ?? 'No Name';
                    final role = userData['role'] as String? ?? 'No Role';
                    final photoUrl = userData['photoUrl'] as String?;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: _getCardBackgroundColor(context),
                      child: ListTile(
                        leading: _buildCachedAvatar(
                          imageUrl: photoUrl,
                          fallbackText: fullName.isNotEmpty
                              ? fullName[0].toUpperCase()
                              : '?',
                          backgroundColor: _getAvatarBackgroundColor(context),
                          textColor: _getAvatarTextColor(context),
                        ),
                        title: Text(
                          fullName,
                          style: TextStyle(
                            color: _getTitleTextColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          role,
                          style: TextStyle(
                            color: _getSubtitleTextColor(context),
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: _getIconColor(context),
                        ),
                        onTap: () =>
                            _showPerformanceDetails(context, user.id, fullName),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getCardBackgroundColor(BuildContext context) {
    return _themeController.isDarkMode.value
        ? const Color(0xFF2D2D2D) // Gradient grey for dark mode
        : const Color(0xFF002060); // Specific dark blue for light mode
  }

  Color _getAvatarBackgroundColor(BuildContext context) {
    return _themeController.isDarkMode.value
        ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.2);
  }

  Color _getAvatarTextColor(BuildContext context) {
    return _themeController.isDarkMode.value
        ? Colors.white
        : const Color(0xFF002060);
  }

  Color _getTitleTextColor(BuildContext context) {
    return _themeController.isDarkMode.value ? Colors.white : Colors.white;
  }

  Color _getSubtitleTextColor(BuildContext context) {
    return _themeController.isDarkMode.value ? Colors.white70 : Colors.white70;
  }

  Color _getIconColor(BuildContext context) {
    return _themeController.isDarkMode.value ? Colors.white70 : Colors.white70;
  }

  // Helper method to build cached network image avatar
  Widget _buildCachedAvatar({
    required String? imageUrl,
    required String fallbackText,
    required Color backgroundColor,
    required Color textColor,
    double radius = 20,
  }) {
    final bool hasValidUrl = imageUrl != null &&
        imageUrl.isNotEmpty &&
        Uri.tryParse(imageUrl)?.hasScheme == true;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: hasValidUrl
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (context, url) => CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
                errorWidget: (context, url, error) => Text(
                  fallbackText,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.8,
                  ),
                ),
              ),
            )
          : Text(
              fallbackText,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            ),
    );
  }

  void _showPerformanceDetails(
      BuildContext context, String userId, String userName) {
    final currentQuarter = (DateTime.now().month - 1) ~/ 3 + 1;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserPerformanceDetailsScreen(
          userId: userId,
          userName: userName,
          quarter: currentQuarter,
        ),
      ),
    );
  }
}

class PerformanceDetailsDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final int currentQuarter;

  const PerformanceDetailsDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.currentQuarter,
  });

  @override
  State<PerformanceDetailsDialog> createState() =>
      _PerformanceDetailsDialogState();
}

class _PerformanceDetailsDialogState extends State<PerformanceDetailsDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.userName}\'s Performance'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('user_performance')
              .doc(widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('No performance data available');
            }

            final performanceData =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final year = DateTime.now().year;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int quarter = 1; quarter <= 4; quarter++) ...[
                    ExpansionTile(
                      title: Text('Q$quarter $year'),
                      subtitle: Text(_getQuarterDateRange(year, quarter)),
                      initiallyExpanded: quarter == widget.currentQuarter,
                      children: [
                        _buildQuarterlyPerformance(
                          performanceData['$year-Q$quarter']
                                  is Map<String, dynamic>
                              ? performanceData['$year-Q$quarter']
                                  as Map<String, dynamic>
                              : <String, dynamic>{},
                          quarter == widget.currentQuarter,
                        ),
                      ],
                    ),
                    if (quarter < 4) const Divider(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildQuarterlyPerformance(
      Map<String, dynamic> data, bool isCurrentQuarter) {
    final tasksCompleted = data['tasks_completed'];
    final tasksAssigned = data['tasks_assigned'];
    final onTimeRate = data['on_time_rate'];
    final avgRating = data['avg_rating'];

    final metrics = {
      'Tasks Completed': tasksCompleted?.toString() ?? '0',
      'Tasks Assigned': tasksAssigned?.toString() ?? '0',
      'On Time Completion Rate': onTimeRate != null ? '$onTimeRate%' : '0%',
      'Average Rating': avgRating is num ? avgRating.toStringAsFixed(1) : 'N/A',
    };

    return Column(
      children: [
        if (isCurrentQuarter) ...[
          const Text('Performance will be updated at the end of the quarter',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          const SizedBox(height: 8),
        ],
        ...metrics.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key),
                  Text(e.value,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
      ],
    );
  }

  String _getQuarterDateRange(int year, int quarter) {
    final startMonth = (quarter - 1) * 3 + 1;
    final endMonth = startMonth + 2;

    final startDate = DateTime(year, startMonth, 1);
    final endDate = DateTime(year, endMonth + 1, 0);

    return '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}';
  }
}
