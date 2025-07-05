// widgets/news/news_sources_carousel.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'dart:async';

class NewsSourcesCarousel extends StatefulWidget {
  final ColorScheme colorScheme;
  
  const NewsSourcesCarousel({super.key, required this.colorScheme});
  
  @override
  State<NewsSourcesCarousel> createState() => _NewsSourcesCarouselState();
}

class _NewsSourcesCarouselState extends State<NewsSourcesCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _newsSources = [
    {
      'name': 'BBC News',
      'url': 'https://www.bbc.com/news',
      'logo': 'BBC',
      'color': const Color(0xFFBB1919),
      'description': 'British Broadcasting Corporation',
      'imagePath': 'assets/images/tv-logos/BBC News-01.png',
    },
    {
      'name': 'CNN',
      'url': 'https://www.cnn.com',
      'logo': 'CNN',
      'color': const Color(0xFFCC0000),
      'description': 'Cable News Network',
      'imagePath': 'assets/images/tv-logos/cnn.png',
    },
    {
      'name': 'Al Jazeera',
      'url': 'https://www.aljazeera.com',
      'logo': 'AJ',
      'color': const Color(0xFF005F56),
      'description': 'Al Jazeera English',
      'imagePath': 'assets/images/tv-logos/aljazeera.png',
    },
    {
      'name': 'Reuters',
      'url': 'https://www.reuters.com',
      'logo': 'R',
      'color': const Color(0xFFD32F2F),
      'description': 'Reuters News Agency',
      'imagePath': 'assets/images/tv-logos/reuters.png',
    },
    {
      'name': 'Newsroom Africa',
      'url': 'https://www.newsroomafrica.com',
      'logo': 'NA',
      'color': const Color(0xFF1976D2),
      'description': 'African News Network',
      'imagePath': 'assets/images/tv-logos/newsroom_africa.png',
    },
    {
      'name': 'TVC News',
      'url': 'https://www.tvcnews.tv',
      'logo': 'TVC',
      'color': const Color(0xFFE65100),
      'description': 'Television Continental',
      'imagePath': 'assets/images/tv-logos/tvcnews.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        if (_currentIndex < _newsSources.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
        }
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onSourceTap(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening news source: $e');
      Get.snackbar(
        'Error',
        'Could not open the news source',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 20.sp,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                'Major News Sources',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tap to Visit',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // Carousel
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _newsSources.length,
            itemBuilder: (context, index) {
              final source = _newsSources[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: MediaQuery.of(context).size.width - 32.w,
                child: NewsSourceCard(
                  source: source,
                  isActive: index == _currentIndex,
                  onTap: () => _onSourceTap(source['url']),
                ),
              );
            },
          ),
        ),
        // Page indicators
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _newsSources.length,
            (index) => Container(
              width: 8.w,
              height: 8.h,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentIndex
                    ? AppColors.primaryColor
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NewsSourceCard extends StatelessWidget {
  final Map<String, dynamic> source;
  final bool isActive;
  final VoidCallback onTap;

  const NewsSourceCard({
    super.key,
    required this.source,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              source['color'],
              source['color'].withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: source['color'].withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Container(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Logo
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    source['imagePath'] as String,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          source['logo'] as String,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      source['name'],
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      source['description'],
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.white.withOpacity(0.8),
                          size: 12.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Tap to visit',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.open_in_new,
                color: Colors.white.withOpacity(0.8),
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 