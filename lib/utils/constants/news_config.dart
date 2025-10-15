// utils/constants/news_config.dart

class NewsConfig {
  // News API keys - Get free keys from:
  // https://newsapi.org/ (1000 requests/day free)
  // https://newsdata.io/ (200 requests/day free)

  static const String newsApiKey =
      '59687-77f75-853d8-ae97b-26297'; // NewsAPI.org key
  static const String newsDataApiKey =
      'pub_9c30bbbf59794381aaf93dc01fa8c126'; // NewsData.io key

  // RSS feed URLs for fallback (no API key required)
  static const List<String> rssFeeds = [
    // Google News Top Headlines (English only):
    'https://news.google.com/rss?hl=en&gl=US&ceid=US:en', // Top headlines (US, English)
    // Google News Nigeria (English):
    'https://news.google.com/rss?hl=en&gl=NG&ceid=NG:en', // Top headlines (Nigeria, English)
    // Nigerian news RSS feeds:
    'https://www.premiumtimesng.com/feed',
    'https://www.vanguardngr.com/feed',
    'https://www.thecable.ng/feed',
    'https://guardian.ng/feed',
    'https://www.channelstv.com/feed',
  ];

  // News categories
  static const List<String> categories = [
    'All News',
    'Latest News',
    'Business',
    'Technology',
    'Sports',
    'Entertainment',
    'Science',
    'Nigeria', // Added Nigeria category
    'All',
  ];

  // Cache duration for news (in minutes)
  static const int cacheDurationMinutes = 15;

  // Maximum number of articles to fetch
  static const int maxArticles = 50;
}
