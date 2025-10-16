// views/africanews_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:task/widgets/news/news_card.dart';

class AfricaNewsCard extends StatelessWidget {
  const AfricaNewsCard({super.key});

  void _launchURL() async {
    final uri = Uri.parse('https://www.africanews.com');
    if (!await launchUrl(uri,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(
          showTitle: true,
        ))) {
      throw 'Could not launch BBC News';
    }
  }

  @override
  Widget build(BuildContext context) {
    return NewsCarouselCard(
      imagePath: 'assets/images/tv-logos/newsroom_africa.png',
      source: 'africanews',
      headline: 'Africanews covers major continental summit',
      timeAgo: '6 hours ago',
      onTap: _launchURL,
    );
  }
}
