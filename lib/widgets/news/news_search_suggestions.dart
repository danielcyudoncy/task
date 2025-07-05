// widgets/news/news_search_suggestions.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NewsSearchSuggestions extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onTopicSelected;

  const NewsSearchSuggestions({
    super.key,
    required this.searchController,
    required this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Topics:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              'Technology',
              'Business',
              'Sports',
              'Health',
              'Politics',
              'Climate',
              'AI',
              'Economy',
            ].map((topic) => GestureDetector(
              onTap: () {
                searchController.text = topic;
                onTopicSelected(topic);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  topic,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
} 