// views/aljazeera_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:task/widgets/news/news_card.dart';

class AlJazeeraCard extends StatelessWidget {
  const AlJazeeraCard({super.key});

  void _launchURL() async {
    final uri = Uri.parse('https://www.aljazeera.com');
    if (!await launchUrl(uri,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(
          showTitle: true,
        ))) {
      throw 'Could not launch Aljazeera News';
    }
  }

  @override
  Widget build(BuildContext context) {
    return NewsCarouselCard(
      imagePath: 'assets/images/tv-logos/aljazeera.png',
      source: 'Al Jazeera',
      headline: 'Middle East peace talks resume amid tensions',
      timeAgo: '1 hour ago',
      onTap: _launchURL,
    );
  }
}
