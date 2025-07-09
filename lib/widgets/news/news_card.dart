// widgets/news/news_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NewsCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final bool isDark;
  final VoidCallback onTap;

  const NewsCard({
    super.key,
    required this.article,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and date
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      article['category'],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    article['date'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Title
              Text(
                article['title'],
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),
              // Summary
              Text(
                article['summary'],
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12.h),
              // Author
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16.sp,
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    article['source'] ?? article['author'] ?? 'Unknown Source',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Read more',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsCarouselCard extends StatelessWidget {
  final String imagePath;
  final String source;
  final String headline;
  final String timeAgo;
  final VoidCallback onTap;

  const NewsCarouselCard({
    super.key,
    required this.imagePath,
    required this.source,
    required this.headline,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imagePath.startsWith('http')) {
      imageWidget = Image.network(
        imagePath,
        width: 350.w,
        height: 246.h,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/png/logo.png',
          width: 350.w,
          height: 246.h,
          fit: BoxFit.cover,
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 350.w,
            height: 246.h,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    } else {
      imageWidget = Image.asset(
        imagePath.isNotEmpty ? imagePath : 'assets/png/logo.png',
        width: 350.w,
        height: 246.h,
        fit: BoxFit.cover,
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 350.w,
        height: 246.h, // Increased size
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            children: [
              // News image (network or asset)
              imageWidget,
              // Gradient overlay at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80.h, // Adjusted for new height
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // Overlaid text
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 18.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      headline,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17.sp,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 