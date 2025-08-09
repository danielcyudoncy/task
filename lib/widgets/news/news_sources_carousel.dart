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
import 'package:get/get.dart';
import 'package:task/service/news_service.dart';
import 'package:task/widgets/news/news_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';


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

  final List<Widget Function()> _cardBuilders = [
    () => const BBCNewsCard(),
    () => const CNNCard(),
    () => const AlJazeeraCard(),
    () => const ChannelsCard(),
    () => const ReutersCard(),
    () => const AfricaNewsCard(),
    () => const TVCCard(),
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
        if (_currentIndex < _cardBuilders.length - 1) {
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
    final NewsService newsService = Get.find<NewsService>();
    // Define the static logos and their corresponding sources
    final List<Map<String, String>> staticSources = [
      {
        'source': 'BBC News',
        'logo': 'assets/images/tv-logos/BBC News-01.png',
        'id': 'bbc-news',
        'rss': 'https://feeds.bbci.co.uk/news/world/rss.xml', // Updated to world news feed
      },
      {
        'source': 'CNN',
        'logo': 'assets/images/tv-logos/cnn.png',
        'id': 'cnn',
        'rss': 'http://rss.cnn.com/rss/edition.rss',
      },
      {
        'source': 'Al Jazeera',
        'logo': 'assets/images/tv-logos/aljazeera.png',
        'id': 'al-jazeera-english',
        'rss': 'https://www.aljazeera.com/xml/rss/all.xml',
      },
      {
        'source': 'Reuters',
        'logo': 'assets/images/tv-logos/reuters.png',
        'id': 'reuters',
        'rss': 'https://www.reuters.com/rssFeed/topNews', // Updated to new Reuters feed
      },
      {
        'source': 'Channels TV',
        'logo': 'assets/images/tv-logos/CHANNELS.png',
        'id': 'channelstv',
        'rss': 'https://www.channelstv.com/feed/',
      },
      {
        'source': 'Africanews',
        'logo': 'assets/images/tv-logos/newsroom_africa.png',
        'id': 'africanews',
        'rss': 'https://www.africanews.com/feed/rss',
      },
      {
        'source': 'TVC News',
        'logo': 'assets/images/tv-logos/tvcnews.jpg',
        'id': 'tvc-news',
        'rss': '', // Add correct RSS if available
      },
    ];

    Future<Map<String, String>?> fetchLatestRssHeadline(String rssUrl) async {
      try {
        final response = await http.get(Uri.parse(rssUrl));
        if (response.statusCode == 200) {
          final document = XmlDocument.parse(response.body);
          final item = document.findAllElements('item').first;
          final title = item.findElements('title').first.innerText;
          final link = item.findElements('link').first.innerText;
          return {'title': title, 'url': link};
        }
      } catch (e) {
        // ignore: avoid_print
      }
      return null;
    }
    return Column(
      children: [
        // (Removed header row with 'Major News Sources' and 'Tap to Visit')
        SizedBox(height: 12.h),
        // Carousel
        SizedBox(
          width: 350.w,
          height: 246.h,
          child: Obx(() {
            final articles = newsService.newsArticles;
            if (newsService.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (articles.isEmpty) {
              return Center(
                child: Text('No news available', style: TextStyle(fontSize: 16.sp)),
              );
            }
            // For each static source, find the latest article for that source
            final List<Widget> cards = staticSources.map((sourceInfo) {
              final sourceName = sourceInfo['source']!;
              final logoPath = sourceInfo['logo']!;
              final sourceId = sourceInfo['id']!;
              final rssUrl = sourceInfo['rss'] ?? '';
              final article = articles.firstWhereOrNull(
                (a) => (a['source']?.toString().toLowerCase() ?? '') == sourceId.toLowerCase(),
              );
              if (article != null) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: sourceName == 'Channels TV'
                      ? NewsCarouselCard(
                          imagePath: logoPath,
                          source: sourceName,
                          headline: article['title'] ?? '',
                          timeAgo: _formatTimeAgo(article['date']),
                          onTap: () {
                            final url = article['url'];
                            if (url != null && url.toString().isNotEmpty) {
                              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            }
                          },
                        )
                      : NewsCarouselCard(
                          imagePath: logoPath,
                          source: sourceName,
                          headline: article['title'] ?? '',
                          timeAgo: _formatTimeAgo(article['date']),
                          onTap: () {
                            final url = article['url'];
                            if (url != null && url.toString().isNotEmpty) {
                              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                );
              } else if (rssUrl.isNotEmpty) {
                // Fallback to RSS headline if no API article
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: FutureBuilder<Map<String, String>?>(
                    future: fetchLatestRssHeadline(rssUrl),
                    builder: (context, snapshot) {
                      final rssHeadline = snapshot.data?['title'] ?? 'No headline available';
                      final rssUrlLink = snapshot.data?['url'];
                      return NewsCarouselCard(
                        imagePath: logoPath,
                        source: sourceName,
                        headline: rssHeadline,
                        timeAgo: '',
                        onTap: () {
                          if (rssUrlLink != null) {
                            launchUrl(Uri.parse(rssUrlLink), mode: LaunchMode.externalApplication);
                          }
                        },
                      );
                    },
                  ),
                );
              } else {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: NewsCarouselCard(
                    imagePath: logoPath,
                    source: sourceName,
                    headline: 'No headline available',
                    timeAgo: '',
                    onTap: () {},
                  ),
                );
              }
            }).toList();
            return PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: cards.length,
              itemBuilder: (_, index) => cards[index],
            );
          }),
        ),
        // Indicators
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            staticSources.length,
            (index) => Container(
              width: 8.w,
              height: 8.h,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentIndex
                    ? AppColors.primaryColor
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(dynamic date) {
    if (date == null) return '';
    try {
      final parsed = DateTime.tryParse(date.toString());
      if (parsed == null) return '';
      final now = DateTime.now();
      final diff = now.difference(parsed);
      if (diff.inDays > 0) {
        return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return '';
    }
  }
}
