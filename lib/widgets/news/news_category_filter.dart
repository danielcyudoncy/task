// widgets/news/news_category_filter.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/service/news_service.dart';
import 'package:task/utils/constants/news_config.dart';

class NewsCategoryFilter extends StatelessWidget {
  final NewsService newsService;
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const NewsCategoryFilter({
    super.key,
    required this.newsService,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6.w,
        runSpacing: 8.h,
        children: NewsConfig.categories.map((category) {
          final isSelected = category == selectedCategory;
          String displayName = category;
          String tooltipMessage = 'Filter by $category';
          if (category == 'All') {
            displayName = 'All Categories';
            tooltipMessage = 'Show all available news categories';
          } else if (category == 'All News') {
            tooltipMessage = 'Show all recent news articles';
          }
          return Tooltip(
            message: tooltipMessage,
            child: FilterChip(
              label: Text(
                displayName,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
              ),
              selected: isSelected,
              onSelected: (selected) {
                onCategoryChanged(category);
              },
              backgroundColor: isSelected 
                ? colorScheme.primaryContainer
                : colorScheme.surfaceVariant,
              selectedColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected 
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
                fontSize: 12.sp,
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
} 