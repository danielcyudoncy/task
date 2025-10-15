// views/channels_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:task/widgets/news/news_card.dart';

class ChannelsCard extends StatelessWidget {
  const ChannelsCard({super.key});

  void _launchURL() async {
    final uri = Uri.parse('https://www.channelstv.com');
    if (!await launchUrl(uri,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(
          showTitle: true,
        ))) {
      throw 'Could not launch Channels TV News';
    }
  }

  @override
  Widget build(BuildContext context) {
    return NewsCarouselCard(
      imagePath: 'assets/images/tv-logos/CHANNELS.png',
      source: 'Channels TV',
      headline: 'Channels TV launches new investigative series',
      timeAgo: '4 hours ago',
      onTap: _launchURL,
    );
  }
}
