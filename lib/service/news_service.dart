// service/news_service.dart
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:task/utils/constants/news_config.dart';

class NewsService extends GetxService {
  
  final RxList<Map<String, dynamic>> newsArticles = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // News sources we want to fetch from



  @override
  void onInit() {
    super.onInit();
    // Load initial news (recent only)
    fetchRecentNews();
  }

  Future<void> fetchNews() async {
    await fetchRecentNews();
  }

  Future<void> fetchRecentNews() async {
    try {
      isLoading(true);
      errorMessage.value = '';
      
      debugPrint('NewsService: Fetching recent news (Google News RSS only)...');
      
      // Only fetch from Google News RSS feeds
      final List<Map<String, dynamic>> allNews = await _fetchFromRSSFeeds();
      
      // Remove duplicates and sort by date
      final uniqueNews = _removeDuplicates(allNews);
      debugPrint('NewsService: After removing duplicates: ${uniqueNews.length} articles');
      
      final sortedNews = _sortByDate(uniqueNews);
      debugPrint('NewsService: After sorting: ${sortedNews.length} articles');
      
      // Filter for recent news only (today and yesterday)
      final recentNews = _filterRecentNews(sortedNews);
      debugPrint('NewsService: After filtering for recent: ${recentNews.length} articles');
      
      // Take the latest articles (up to 50 for recent news)
      newsArticles.assignAll(recentNews.take(50).toList());
      
      debugPrint('NewsService: Final result: ${newsArticles.length} recent news articles');
      
      // If no recent news found, fall back to showing some articles anyway
      if (newsArticles.isEmpty && sortedNews.isNotEmpty) {
        debugPrint('NewsService: No recent news found, showing latest articles instead');
        newsArticles.assignAll(sortedNews.take(20).toList());
      }
      
    } catch (e) {
      debugPrint('NewsService: Error fetching recent news: $e');
      errorMessage.value = 'Failed to load news. Please try again.';
      _loadMockNews();
    } finally {
      isLoading(false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFromRSSFeeds() async {
    try {
      // RSS feed URLs from config
      const rssUrls = NewsConfig.rssFeeds;
      final List<Map<String, dynamic>> allRssNews = [];

      debugPrint('NewsService: Starting to fetch from ${rssUrls.length} RSS feeds');

      for (int i = 0; i < rssUrls.length; i++) {
        final url = rssUrls[i];
        final sourceName = _getSourceName(url);
        
        try {
          debugPrint('NewsService: Fetching from $sourceName ($url)');
          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            debugPrint('NewsService: Successfully fetched from $sourceName');
            final rssNews = _parseRSSFeed(response.body, url);
            allRssNews.addAll(rssNews);
            debugPrint('NewsService: Added ${rssNews.length} articles from $sourceName');
          } else {
            debugPrint('NewsService: Failed to fetch from $sourceName - Status: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('NewsService: RSS feed error for $sourceName ($url): $e');
        }
        
        // Small delay between requests to be respectful
        if (i < rssUrls.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      debugPrint('NewsService: Total RSS articles fetched: ${allRssNews.length}');
      return allRssNews;
    } catch (e) {
      debugPrint('NewsService: RSS feeds error: $e');
    }
    return [];
  }

  List<Map<String, dynamic>> _parseRSSFeed(String xmlContent, String sourceUrl) {
    try {
      final List<Map<String, dynamic>> articles = [];
      final sourceName = _getSourceName(sourceUrl);
      
      debugPrint('NewsService: Parsing RSS feed for $sourceName');
      
      // Try different RSS patterns
      final patterns = [
        // Standard RSS pattern
        RegExp(r'<item>(.*?)</item>', dotAll: true),
        // Alternative pattern for some feeds
        RegExp(r'<entry>(.*?)</entry>', dotAll: true),
      ];
      
      for (final pattern in patterns) {
        final itemMatches = pattern.allMatches(xmlContent);
        
        for (final itemMatch in itemMatches) {
          final itemContent = itemMatch.group(1) ?? '';
          
          // Extract title
          final titleMatch = RegExp(r'<title>(.*?)</title>', dotAll: true).firstMatch(itemContent);
          final title = titleMatch != null ? _cleanHtml(titleMatch.group(1) ?? '') : '';
          
          // Extract description/content
          final descriptionMatch = RegExp(r'<description>(.*?)</description>', dotAll: true).firstMatch(itemContent);
          final contentMatch = RegExp(r'<content>(.*?)</content>', dotAll: true).firstMatch(itemContent);
          final summaryMatch = RegExp(r'<summary>(.*?)</summary>', dotAll: true).firstMatch(itemContent);
          
          final description = descriptionMatch?.group(1) ?? 
                             contentMatch?.group(1) ?? 
                             summaryMatch?.group(1) ?? '';
          final cleanDescription = _cleanHtml(description);
          
          // Extract link
          final linkMatch = RegExp(r'<link>(.*?)</link>').firstMatch(itemContent);
          final link = linkMatch?.group(1) ?? '';
          
          // Extract date
          final pubDateMatch = RegExp(r'<pubDate>(.*?)</pubDate>').firstMatch(itemContent);
          final updatedMatch = RegExp(r'<updated>(.*?)</updated>').firstMatch(itemContent);
          final date = pubDateMatch?.group(1) ?? updatedMatch?.group(1) ?? '';
          
          debugPrint('NewsService: Raw date from RSS: $date');
          
          // Extract author
          final authorMatch = RegExp(r'<author>(.*?)</author>', dotAll: true).firstMatch(itemContent);
          final creatorMatch = RegExp(r'<dc:creator>(.*?)</dc:creator>').firstMatch(itemContent);
          final author = authorMatch?.group(1) ?? creatorMatch?.group(1) ?? '';
          final cleanAuthor = _cleanHtml(author);

          // --- IMAGE EXTRACTION PATCH START ---
          String? imageUrl;
          // Try <media:content url="...">
          final mediaContentMatch = RegExp(r'<media:content[^>]*url=["\"](.*?)["\"][^>]*/?>', dotAll: true).firstMatch(itemContent);
          if (mediaContentMatch != null) {
            imageUrl = mediaContentMatch.group(1);
          }
          // Try <enclosure url="...">
          if (imageUrl == null) {
            final enclosureMatch = RegExp(r'<enclosure[^>]*url=["\"](.*?)["\"][^>]*/?>', dotAll: true).firstMatch(itemContent);
            if (enclosureMatch != null) {
              imageUrl = enclosureMatch.group(1);
            }
          }
          // Try <img ... src="..."> in description
          if (imageUrl == null && description.isNotEmpty) {
            final imgTagMatch = RegExp(r'<img[^>]*src=["\"](.*?)["\"][^>]*>', dotAll: true).firstMatch(description);
            if (imgTagMatch != null) {
              imageUrl = imgTagMatch.group(1);
            }
          }
          // --- IMAGE EXTRACTION PATCH END ---

          // Use local asset for Channels TV
          String? finalImageUrl = imageUrl;
          if (sourceName == 'Channels TV') {
            finalImageUrl = 'assets/images/tv-logos/CHANNELS.png';
          }

          // Only add if we have a title and some content
          if (title.isNotEmpty && (cleanDescription.isNotEmpty || title.length > 20)) {
            articles.add({
              'id': link.isNotEmpty ? link : '${sourceName}_${DateTime.now().millisecondsSinceEpoch}',
              'title': title,
              'summary': cleanDescription.isNotEmpty 
                ? (cleanDescription.length > 200 ? '${cleanDescription.substring(0, 200)}...' : cleanDescription)
                : 'Read full article for more details.',
              'content': cleanDescription.isNotEmpty ? cleanDescription : 'Click the link to read the full article.',
              'author': cleanAuthor.isNotEmpty ? cleanAuthor : sourceName,
              'date': date.isNotEmpty ? date : DateTime.now().toIso8601String(),
              'category': _categorizeArticle(title, cleanDescription),
              'imageUrl': finalImageUrl,
              'source': sourceName,
              'url': link,
            });
            
            debugPrint('NewsService: Added article from $sourceName: ${title.substring(0, title.length > 50 ? 50 : title.length)}...');
          }
        }
        
        // If we found articles with this pattern, break
        if (articles.isNotEmpty) break;
      }
      
      debugPrint('NewsService: Parsed ${articles.length} articles from $sourceName');
      return articles;
    } catch (e) {
      debugPrint('NewsService: RSS parsing error for ${_getSourceName(sourceUrl)}: $e');
      return [];
    }
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  String _getSourceName(String url) {
    final lowerUrl = url.toLowerCase();
    debugPrint('NewsService: Matching source for feed URL: $url');
    if (lowerUrl.contains('news.google.com')) {
      if (lowerUrl.contains('hl=en&gl=ng')) return 'Google News Nigeria';
      if (lowerUrl.contains('sports')) return 'Google News - Sports';
      if (lowerUrl.contains('technology')) return 'Google News - Technology';
      if (lowerUrl.contains('healthcare')) return 'Google News - Healthcare';
      if (lowerUrl.contains('africa')) return 'Google News - Africa';
      return 'Google News';
    }
    if (lowerUrl.contains('premiumtimesng.com')) return 'Premium Times Nigeria';
    if (lowerUrl.contains('vanguardngr.com')) return 'Vanguard Nigeria';
    if (lowerUrl.contains('thecable.ng')) return 'The Cable Nigeria';
    if (lowerUrl.contains('guardian.ng')) return 'The Guardian Nigeria';
    if (lowerUrl.contains('channelstv.com')) return 'Channels TV';
    // Add more as needed
    debugPrint('NewsService: No match for feed URL: $url');
    return 'Unknown Source';
  }

  String _categorizeArticle(String title, String description) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
    
    if (text.contains('tech') || text.contains('technology') || text.contains('ai') || text.contains('artificial intelligence')) {
      return 'Technology';
    } else if (text.contains('business') || text.contains('economy') || text.contains('market') || text.contains('finance')) {
      return 'Business';
    } else if (text.contains('sport') || text.contains('football') || text.contains('basketball') || text.contains('tennis')) {
      return 'Sports';
    } else if (text.contains('entertainment') || text.contains('movie') || text.contains('music') || text.contains('celebrity')) {
      return 'Entertainment';
    } else if (text.contains('health') || text.contains('medical') || text.contains('covid') || text.contains('vaccine')) {
      return 'Health';
    } else if (text.contains('science') || text.contains('research') || text.contains('study')) {
      return 'Science';
    } else {
      return 'Latest News';
    }
  }

  List<Map<String, dynamic>> _removeDuplicates(List<Map<String, dynamic>> articles) {
    final Set<String> seenTitles = {};
    final List<Map<String, dynamic>> uniqueArticles = [];

    for (final article in articles) {
      final title = article['title']?.toString().toLowerCase() ?? '';
      if (!seenTitles.contains(title) && title.isNotEmpty) {
        seenTitles.add(title);
        uniqueArticles.add(article);
      }
    }

    return uniqueArticles;
  }

  List<Map<String, dynamic>> _sortByDate(List<Map<String, dynamic>> articles) {
    articles.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA); // Newest first
    });
    return articles;
  }

  List<Map<String, dynamic>> _filterRecentNews(List<Map<String, dynamic>> articles) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    debugPrint('NewsService: Filtering ${articles.length} articles for recent news');
    debugPrint('NewsService: Current time: $now');
    debugPrint('NewsService: Yesterday: $yesterday');
    
    final filteredArticles = articles.where((article) {
      try {
        String dateString = article['date'] ?? '';
        DateTime? articleDate;
        
        // Try to parse the date string
        articleDate = DateTime.tryParse(dateString);
        
        // If that fails, try to parse RSS date format
        if (articleDate == null && dateString.isNotEmpty) {
          // Handle RSS date format like "Mon, 25 Dec 2023 10:30:00 GMT"
          try {
            final parts = dateString.split(' ');
            if (parts.length >= 5) {
              final day = int.tryParse(parts[1]) ?? 1;
              final month = _getMonthNumber(parts[2]);
              final year = int.tryParse(parts[3]) ?? now.year;
              final timeParts = parts[4].split(':');
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
              final second = timeParts.length > 2 ? int.tryParse(timeParts[2]) ?? 0 : 0;
              
              articleDate = DateTime(year, month, day, hour, minute, second);
            }
          } catch (e) {
            debugPrint('NewsService: Failed to parse RSS date format: $dateString');
          }
        }
        
        // If still no date, assume it's recent (within last 24 hours)
        if (articleDate == null) {
          debugPrint('NewsService: No valid date for article: ${article['title']} - Assuming recent');
          return true; // Include articles without dates for now
        }
        
        // Check if article is from today or yesterday (more lenient)
        final isRecent = articleDate.isAfter(yesterday.subtract(const Duration(hours: 24))) &&
                         articleDate.isBefore(now.add(const Duration(hours: 12)));
        
        if (!isRecent) {
          debugPrint('NewsService: Article too old: ${article['title']} - Date: $articleDate');
        }
        
        return isRecent;
      } catch (e) {
        debugPrint('NewsService: Error parsing date for article: ${article['title']} - Error: $e');
        return true; // Include articles with parsing errors for now
      }
    }).toList();
    
    debugPrint('NewsService: After filtering, ${filteredArticles.length} articles remain');
    return filteredArticles;
  }

  int _getMonthNumber(String month) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    };
    return months[month] ?? 1;
  }

  void _loadMockNews() {
    // Fallback mock news if all APIs fail (recent news only)
    final now = DateTime.now();
    newsArticles.assignAll([
      {
        'id': '1',
        'title': 'Breaking: Major Tech Conference Announced',
        'summary': 'A major technology conference has been announced for next month, featuring industry leaders and innovative startups.',
        'content': 'The conference will bring together technology leaders, entrepreneurs, and innovators from around the world. The event will feature keynote speeches, panel discussions, and networking opportunities.',
        'author': 'Tech News Team',
        'date': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'category': 'Technology',
        'imageUrl': null,
        'source': 'Tech News',
        'url': null,
      },
      {
        'id': '2',
        'title': 'Global Economic Update: Markets Show Recovery Signs',
        'summary': 'Global markets are showing signs of recovery as economic indicators improve across major economies.',
        'content': 'Recent economic data suggests a positive trend in global markets. Analysts are optimistic about the recovery trajectory, though challenges remain in certain sectors.',
        'author': 'Economic Analysis Team',
        'date': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'category': 'Business',
        'imageUrl': null,
        'source': 'Financial Times',
        'url': null,
      },
      {
        'id': '3',
        'title': 'Sports: Championship Finals Set for Next Week',
        'summary': 'The championship finals have been scheduled for next week, with top teams competing for the ultimate prize.',
        'content': 'After an exciting season, the championship finals are finally set. Fans are eagerly anticipating the showdown between the top-performing teams.',
        'author': 'Sports Desk',
        'date': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'category': 'Sports',
        'imageUrl': null,
        'source': 'Sports Central',
        'url': null,
      },
      {
        'id': '4',
        'title': 'Health Alert: New Medical Breakthrough Announced',
        'summary': 'Scientists have announced a breakthrough in medical research that could revolutionize treatment options.',
        'content': 'The breakthrough involves a new approach to treating chronic conditions that affects millions of people worldwide. Clinical trials have shown promising results.',
        'author': 'Health Research Team',
        'date': now.subtract(const Duration(hours: 8)).toIso8601String(),
        'category': 'Health',
        'imageUrl': null,
        'source': 'Medical News',
        'url': null,
      },
      {
        'id': '5',
        'title': 'Entertainment: Major Movie Release Breaks Records',
        'summary': 'The latest blockbuster movie has broken box office records in its opening weekend.',
        'content': 'The film has received critical acclaim and has become the highest-grossing movie of the year so far. Fans are already asking for sequels.',
        'author': 'Entertainment Desk',
        'date': now.subtract(const Duration(hours: 10)).toIso8601String(),
        'category': 'Entertainment',
        'imageUrl': null,
        'source': 'Entertainment Weekly',
        'url': null,
      },
    ]);
  }

  Future<void> refreshNews() async {
    await fetchNews();
  }

  List<Map<String, dynamic>> getNewsByCategory(String category) {
    if (category == 'All News') return newsArticles.toList();
    if (category == 'All') return newsArticles.toList(); // Show all articles for "All" category
    return newsArticles.where((article) => 
      article['category']?.toString().toLowerCase() == category.toLowerCase()
    ).toList();
  }

  List<Map<String, dynamic>> searchNews(String query) {
    if (query.isEmpty) return newsArticles.toList();
    
    final lowercaseQuery = query.toLowerCase();
    return newsArticles.where((article) {
      final title = article['title']?.toString().toLowerCase() ?? '';
      final summary = article['summary']?.toString().toLowerCase() ?? '';
      final content = article['content']?.toString().toLowerCase() ?? '';
      final source = article['source']?.toString().toLowerCase() ?? '';
      final author = article['author']?.toString().toLowerCase() ?? '';
      final category = article['category']?.toString().toLowerCase() ?? '';
      
      return title.contains(lowercaseQuery) ||
             summary.contains(lowercaseQuery) ||
             content.contains(lowercaseQuery) ||
             source.contains(lowercaseQuery) ||
             author.contains(lowercaseQuery) ||
             category.contains(lowercaseQuery);
    }).toList();
  }

  List<String> getAvailableCategories() {
    final categories = newsArticles.map((article) => 
      article['category']?.toString() ?? 'Uncategorized'
    ).toSet().toList();
    categories.insert(0, 'All News');
    categories.add('All'); // Add "All" at the end for showing all categories
    return categories;
  }
} 