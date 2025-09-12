// widgets/skeleton_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  
  const SkeletonWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!),
      highlightColor: highlightColor ?? (isDark ? Colors.grey[700]! : Colors.grey[100]!),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class SkeletonTaskCard extends StatelessWidget {
  const SkeletonTaskCard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title skeleton
            SkeletonWidget(
              width: double.infinity,
              height: 20.h,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 8.h),
            
            // Description skeleton
            SkeletonWidget(
              width: double.infinity,
              height: 16.h,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 4.h),
            SkeletonWidget(
              width: 200.w,
              height: 16.h,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 12.h),
            
            // Status and date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonWidget(
                  width: 80.w,
                  height: 24.h,
                  borderRadius: BorderRadius.circular(12),
                ),
                SkeletonWidget(
                  width: 100.w,
                  height: 16.h,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonUserCard extends StatelessWidget {
  const SkeletonUserCard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // Avatar skeleton
            SkeletonWidget(
              width: 50.w,
              height: 50.h,
              borderRadius: BorderRadius.circular(25),
            ),
            SizedBox(width: 16.w),
            
            // User info skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonWidget(
                    width: double.infinity,
                    height: 18.h,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SizedBox(height: 8.h),
                  SkeletonWidget(
                    width: 120.w,
                    height: 14.h,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            
            // Status indicator skeleton
            SkeletonWidget(
              width: 12.w,
              height: 12.h,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonNewsList extends StatelessWidget {
  final int itemCount;
  
  const SkeletonNewsList({super.key, this.itemCount = 5});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonNewsCard(),
    );
  }
}

class SkeletonNewsCard extends StatelessWidget {
  const SkeletonNewsCard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            SkeletonWidget(
              width: 80.w,
              height: 80.h,
              borderRadius: BorderRadius.circular(8),
            ),
            SizedBox(width: 16.w),
            
            // Content skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonWidget(
                    width: double.infinity,
                    height: 18.h,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SizedBox(height: 8.h),
                  SkeletonWidget(
                    width: double.infinity,
                    height: 14.h,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SizedBox(height: 4.h),
                  SkeletonWidget(
                    width: 150.w,
                    height: 14.h,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SizedBox(height: 12.h),
                  SkeletonWidget(
                    width: 100.w,
                    height: 12.h,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonTaskList extends StatelessWidget {
  final int itemCount;
  
  const SkeletonTaskList({super.key, this.itemCount = 5});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonTaskCard(),
    );
  }
}

class SkeletonUserList extends StatelessWidget {
  final int itemCount;
  
  const SkeletonUserList({super.key, this.itemCount = 5});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonUserCard(),
    );
  }
}

class SkeletonDashboardCard extends StatelessWidget {
  const SkeletonDashboardCard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonWidget(
              width: 100.w,
              height: 16.h,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 12.h),
            SkeletonWidget(
              width: 60.w,
              height: 32.h,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  
  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonDashboardCard(),
    );
  }
}

// Loading state wrapper widget
class LoadingStateWrapper extends StatelessWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final LoadingState state;
  final String? errorMessage;
  final VoidCallback? onRetry;
  
  const LoadingStateWrapper({
    super.key,
    required this.child,
    required this.state,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.errorMessage,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    switch (state) {
      case LoadingState.loading:
        return loadingWidget ?? const Center(child: CircularProgressIndicator());
      case LoadingState.error:
        return errorWidget ?? _buildErrorWidget();
      case LoadingState.empty:
        return emptyWidget ?? _buildEmptyWidget();
      case LoadingState.success:
      case LoadingState.idle:
        return child;
    }
  }
  
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp),
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ]
        ],
      ),
    );
  }
  
  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// Import this enum from loading_state_service.dart
enum LoadingState {
  idle,
  loading,
  success,
  error,
  empty
}