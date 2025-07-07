// views/channels_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class ChannelsCard extends StatelessWidget {
  const ChannelsCard({super.key});

  void _launchURL() async {
    final uri = Uri.parse('https://www.channelstv.com');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch Channels TV News';
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
              const Color(0xFF193380),
              const Color(0xFF193380).withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
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
                'assets/png/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Channels TV',
                    style: TextStyle(
                      fontSize: 20.sp,
                      color: const Color(0xFFd5dedc),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '…Your Home For The News',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFFd5dedc),
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
