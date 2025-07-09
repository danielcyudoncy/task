// views/tvc_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:task/widgets/news/news_card.dart';

class TVCCard extends StatelessWidget {
  const TVCCard({super.key});

  void _launchURL() async {
    final uri = Uri.parse('https://www.tvcnews.tv');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch TVC News';
    }
  }

  @override
  Widget build(BuildContext context) {
    return NewsCarouselCard(
      imagePath: 'assets/images/tv-logos/tvcnews.jpg',
      source: 'TVC News',
      headline: 'TVC News: Breaking stories from Nigeria and beyond',
      timeAgo: '7 hours ago',
      onTap: _launchURL,
    );
  }
}
