import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TaskSkeletonList extends StatelessWidget {
  final bool isLargeScreen;
  final double textScale;
  const TaskSkeletonList({required this.isLargeScreen, required this.textScale, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(
        color: Colors.black12,
        thickness: 1,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 16 : 8.0, vertical: 4.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: isLargeScreen ? 120 : 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}