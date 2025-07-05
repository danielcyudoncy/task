// widgets/news/news_category_filter.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/service/news_service.dart';

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
      height: 50.h,
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: newsService.getAvailableCategories().length,
        itemBuilder: (context, index) {
          final category = newsService.getAvailableCategories()[index];
          final isSelected = category == selectedCategory;
          
          // Customize display name for "All" category
          String displayName = category;
          String tooltipMessage = 'Filter by $category';
          
          if (category == 'All') {
            displayName = 'All Categories';
            tooltipMessage = 'Show all available news categories';
          } else if (category == 'All News') {
            tooltipMessage = 'Show all recent news articles';
          }
          
          return Container(
            margin: EdgeInsets.only(right: 8.w),
            child: Tooltip(
              message: tooltipMessage,
              child: FilterChip(
                label: Text(displayName),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 