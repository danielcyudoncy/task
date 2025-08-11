// views/bbc_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:task/widgets/news/news_card.dart';

class BBCNewsCard extends StatelessWidget {
  const BBCNewsCard({super.key});

  void _launchURL() async {
    final uri = Uri.parse('https://www.bbc.com/news');
    if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(
          showTitle: true,
        ))) {
      throw 'Could not launch BBC News';
    }
  }

  @override
  Widget build(BuildContext context) {
    return NewsCarouselCard(
      imagePath: 'assets/images/tv-logos/BBC News-01.png',
      source: 'BBC News',
      headline: 'UK inflation falls to 3.2% in March as food prices ease',
      timeAgo: '2 hours ago',
      onTap: _launchURL,
    );
  }
}
