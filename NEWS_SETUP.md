# News Feature Setup Guide

This guide will help you set up real-time news from major sources like BBC, CNN, Al Jazeera, and Newsroom Africa.

## 🚀 Quick Start

The news feature is now integrated into your app! It will work immediately with RSS feeds (no API key required), but for better coverage and more articles, you can add API keys.

## 📰 News Sources

The app fetches news from:
- **BBC News** (UK)
- **CNN** (US)
- **Al Jazeera** (International)
- **News24** (South Africa)
- **Reuters** (International)

## 🔑 API Keys (Optional but Recommended)

### Option 1: NewsAPI.org (Recommended)
1. Go to [https://newsapi.org/](https://newsapi.org/)
2. Sign up for a free account
3. Get your API key (1000 requests/day free)
4. Update `lib/utils/constants/news_config.dart`:
   ```dart
   static const String newsApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

### Option 2: NewsData.io (Alternative)
1. Go to [https://newsdata.io/](https://newsdata.io/)
2. Sign up for a free account
3. Get your API key (200 requests/day free)
4. Update `lib/utils/constants/news_config.dart`:
   ```dart
   static const String newsDataApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

## 🔧 Configuration

Edit `lib/utils/constants/news_config.dart` to customize:

```dart
class NewsConfig {
  // Your API keys here
  static const String newsApiKey = 'YOUR_NEWS_API_KEY';
  static const String newsDataApiKey = 'YOUR_NEWSDATA_API_KEY';
  
  // RSS feeds (no API key needed)
  static const List<String> rssFeeds = [
    'https://feeds.bbci.co.uk/news/rss.xml',
    'https://rss.cnn.com/rss/edition.rss',
    'https://www.aljazeera.com/xml/rss/all.xml',
    'https://www.news24.com/rss',
    'https://www.reuters.com/rssfeed/world',
  ];
  
  // Categories
  static const List<String> categories = [
    'All',
    'Latest News',
    'Business',
    'Technology',
    'Sports',
    'Entertainment',
    'Health',
    'Science',
  ];
  
  // Cache duration (15 minutes)
  static const int cacheDurationMinutes = 15;
  
  // Max articles to fetch
  static const int maxArticles = 50;
}
```

## 🎯 Features

✅ **Real-time news** from major sources  
✅ **Category filtering** (All, Business, Technology, etc.)  
✅ **Pull-to-refresh** functionality  
✅ **News detail view** with full articles  
✅ **Offline fallback** with cached articles  
✅ **Multiple API support** (NewsAPI, NewsData, RSS)  
✅ **Error handling** with retry options  

## 🔄 How It Works

1. **Primary**: Uses NewsAPI.org if API key is provided
2. **Secondary**: Uses NewsData.io if API key is provided  
3. **Fallback**: Uses RSS feeds (no API key required)
4. **Emergency**: Shows mock data if all sources fail

## 📱 Usage

1. Go to Admin Dashboard
2. Tap the "News Feed" card
3. Browse news by category
4. Tap any article for full details
5. Pull down to refresh

## 🛠️ Troubleshooting

### No News Loading
- Check internet connection
- Verify API keys are correct
- Check debug logs for errors

### API Rate Limits
- NewsAPI: 1000 requests/day
- NewsData: 200 requests/day
- RSS feeds: No limits

### Adding More Sources
Edit `NewsConfig.rssFeeds` to add more RSS feeds:
```dart
static const List<String> rssFeeds = [
  // ... existing feeds
  'https://your-news-source.com/rss.xml',
];
```

## 📊 Performance

- **Cache**: 15-minute cache to reduce API calls
- **Pagination**: Loads 50 articles max
- **Images**: Lazy loading for better performance
- **Offline**: Cached articles available offline

## 🔒 Privacy

- No user data is sent to news APIs
- Only fetches public news content
- RSS feeds are public and free to use
- API keys are stored locally only

---

**Note**: The app will work immediately with RSS feeds. Add API keys for better coverage and more articles! 