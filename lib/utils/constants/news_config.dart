// utils/constants/news_config.dart

class NewsConfig {
  // News API keys - Get free keys from:
  // https://newsapi.org/ (1000 requests/day free)
  // https://newsdata.io/ (200 requests/day free)
  
  static const String newsApiKey = '59687-77f75-853d8-ae97b-26297'; // NewsAPI.org key
  static const String newsDataApiKey = 'pub_9c30bbbf59794381aaf93dc01fa8c126'; // NewsData.io key
  
  // RSS feed URLs for fallback (no API key required)
  static const List<String> rssFeeds = [
    'https://feeds.bbci.co.uk/news/world/rss.xml', // BBC World News
    'https://rss.cnn.com/rss/edition_world.rss', // CNN World
    'https://www.aljazeera.com/xml/rss/all.xml', // Al Jazeera
    'https://feeds.reuters.com/Reuters/worldNews', // Reuters World
    'https://feeds.npr.org/1004/rss.xml', // NPR News
    'https://feeds.feedburner.com/TechCrunch', // TechCrunch
  ];
  
  // News categories
  static const List<String> categories = [
    'All News',
    'Latest News',
    'Business',
    'Technology',
    'Sports',
    'Entertainment',
    'Health',
    'Science',
    'All',
  ];
  
  // Cache duration for news (in minutes)
  static const int cacheDurationMinutes = 15;
  
  // Maximum number of articles to fetch
  static const int maxArticles = 50;
} 