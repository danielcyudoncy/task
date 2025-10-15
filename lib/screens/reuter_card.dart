// views/reuter_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:task/widgets/news/news_card.dart';

class ReutersCard extends StatelessWidget {
  const ReutersCard({super.key});

  void _launchURL() async {
    final uri = Uri.parse('https://www.reuters.com');
    if (!await launchUrl(uri,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(
          showTitle: true,
        ))) {
      throw 'Reuters News Agency';
    }
  }

  @override
  Widget build(BuildContext context) {
    return NewsCarouselCard(
      imagePath: 'assets/images/tv-logos/reuters.png',
      source: 'Reuters',
      headline: 'Global markets rally as inflation fears ease',
      timeAgo: '5 hours ago',
      onTap: _launchURL,
    );
  }
}
