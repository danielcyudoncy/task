// views/reuter_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class ReutersCard extends StatelessWidget {
  const ReutersCard({super.key});

  void _launchURL() async {
    final uri = Uri.parse('https://www.reuters.com');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Reuters News Agency';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launchURL,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFff5f0f),
              const Color(0xFFff5f0f).withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: const [
            BoxShadow(
              color: Colors.white,
              blurRadius: 4,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/images/tv-logos/reuters.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reuters',
                    style: TextStyle(
                      fontSize: 20.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Reuters News Agency',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: Colors.white.withOpacity(0.8),
              size: 20.sp,
            )
          ],
        ),
      ),
    );
  }
}
