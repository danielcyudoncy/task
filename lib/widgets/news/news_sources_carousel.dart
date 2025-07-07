// widgets/news/news_sources_carousel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/views/africanews_card.dart';
import 'package:task/views/aljazeera_card.dart';
import 'package:task/views/bbc_card.dart';
import 'package:task/views/channels_card.dart';
import 'package:task/views/cnn_card.dart';
import 'package:task/views/reuter_card.dart';
import 'package:task/views/tvc_card.dart';


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

  final List<Widget> _cards = [
    const BBCNewsCard(),
    const CNNCard(),
    const AlJazeeraCard(),
    const ChannelsCard(),
    const ReutersCard(),
    const AfricaNewsCard(),
    const TVCCard(),
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
        if (_currentIndex < _cards.length - 1) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(Icons.trending_up,
                  size: 20.sp, color: AppColors.primaryColor),
              SizedBox(width: 8.w),
              Text(
                'Major News Sources',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Tap to Visit',
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.white,
                      fontWeight: FontWeight.w500),
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
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _cards.length,
            itemBuilder: (_, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: _cards[index],
              );
            },
          ),
        ),
        // Indicators
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _cards.length,
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
