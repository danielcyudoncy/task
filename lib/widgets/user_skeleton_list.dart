import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UserSkeletonList extends StatelessWidget {
  final bool isLargeScreen;
  final double textScale;
  const UserSkeletonList(
      {required this.isLargeScreen, required this.textScale, super.key});

  @override
  Widget build(BuildContext context) {
    final itemCount = isLargeScreen ? 8 : 5;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 32 : 16, vertical: 4.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: isLargeScreen ? 80 : 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
