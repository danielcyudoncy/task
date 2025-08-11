// views/cnn_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:task/widgets/news/news_card.dart';

class CNNCard extends StatelessWidget {
  const CNNCard({super.key});

  void _launchURL() async {
    final uri = Uri.parse('https://www.cnn.com');
    if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(
          showTitle: true,
        ))) {
      throw 'Could not launch CNN News';
    }
  }

  @override
  Widget build(BuildContext context) {
    return NewsCarouselCard(
      imagePath: 'assets/images/tv-logos/cnn.png',
      source: 'CNN',
      headline: 'Is WiseTech Global (ASX:WTC) the ASX’s next CBA?',
      timeAgo: '3 hours ago',
      onTap: _launchURL,
    );
  }
}
