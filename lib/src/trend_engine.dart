import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:http/http.dart' as http;
import 'utils.dart';

// Phase 1: Trend Discovery
Future<List<String>> discoverTrends(dynamic context, Map<String, String> env) async {
  final List<String> discovered = [];

  // 1. Fetch Hacker News Top Stories concurrently (up to 100)
  try {
    final response = await http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/topstories.json')).timeout(Duration(seconds: 5));
    if (response.statusCode == 200) {
      final List<dynamic> ids = jsonDecode(response.body) as List<dynamic>;
      final targetIds = ids.take(100).toList();
      
      final futures = targetIds.map((id) => 
        http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/item/$id.json')).timeout(Duration(seconds: 4))
      );
      final responses = await Future.wait(futures);
      
      for (final resp in responses) {
        if (resp.statusCode == 200) {
          final story = jsonDecode(resp.body) as Map<String, dynamic>;
          final title = story['title'] as String? ?? '';
          if (title.isNotEmpty) {
            discovered.add(title);
          }
        }
      }
    }
  } catch (e) {
    logMessage(context, 'HackerNews trend fetch skipped or failed: $e');
  }

  // 2. Fetch Google News RSS and parse titles using Regex
  try {
    final response = await http.get(Uri.parse('https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en')).timeout(Duration(seconds: 5));
    if (response.statusCode == 200) {
      final titleRegExp = RegExp(r'<title>(.*?)<\/title>', caseSensitive: false);
      final matches = titleRegExp.allMatches(response.body);
      for (final m in matches) {
        var title = m.group(1)?.trim() ?? '';
        title = title
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&apos;', "'");
        if (title.isNotEmpty && !title.toLowerCase().contains('google news')) {
          discovered.add(title);
        }
      }
    }
  } catch (e) {
    logMessage(context, 'Google News RSS fetch skipped or failed: $e');
  }

  // 3. Fetch Reddit Technology RSS and parse titles using Regex
  try {
    final response = await http.get(
      Uri.parse('https://www.reddit.com/r/technology/.rss'),
      headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
    ).timeout(Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      final titleRegExp = RegExp(r'<title>(.*?)<\/title>', caseSensitive: false);
      final matches = titleRegExp.allMatches(response.body);
      for (final m in matches) {
        var title = m.group(1)?.trim() ?? '';
        title = title
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&apos;', "'");
        if (title.isNotEmpty && !title.toLowerCase().contains('/r/technology') && !title.toLowerCase().contains('technology')) {
          discovered.add(title);
        }
      }
    }
  } catch (e) {
    logMessage(context, 'Reddit RSS fetch skipped or failed: $e');
  }

  // 4. Fetch NewsAPI Top Technology Headlines
  final String? newsApiKey = env['NEWS_IMAGE_API_KEY'];
  if (newsApiKey != null && newsApiKey.isNotEmpty) {
    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/top-headlines?category=technology&country=us&pageSize=50'),
        headers: {'X-Api-Key': newsApiKey},
      ).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> articles = data['articles'] as List<dynamic>? ?? [];
        for (final art in articles) {
          final title = art['title'] as String? ?? '';
          if (title.isNotEmpty) {
            discovered.add(title);
          }
        }
      }
    } catch (e) {
      logMessage(context, 'NewsAPI trend fetch skipped or failed: $e');
    }
  }

  final result = discovered.toSet().toList();
  logMessage(context, '[Phase 1] Discovered raw trends: $result');
  return result;
}

// Phase 2: Keyword Scoring
Future<List<Map<String, dynamic>>> scoreKeywords(
  dynamic context,
  List<String> rawKeywords,
) async {
  logMessage(context, '[Rule-Based] Scoring trends and keywords.');
  
  final List<Map<String, dynamic>> scored = [];
  for (final kw in rawKeywords) {
    final searchVolume = 5000 + (kw.length * 1200);
    final trendScore = 90;
    final difficulty = 30;
    final publishersCount = 5;
    final viralityScore = 80;
    final overallScore = (trendScore * 0.4) + ((100 - difficulty) * 0.3) + (viralityScore * 0.3);
    
    if (overallScore >= 60) {
      scored.add({
        'keyword': kw,
        'searchVolume': searchVolume,
        'trendScore': trendScore,
        'difficulty': difficulty,
        'publishersCount': publishersCount,
        'viralityScore': viralityScore,
        'overallScore': overallScore,
        'category': 'Technology',
        'eligible': true
      });
    }
  }

  // Sort by overall score descending
  scored.sort((a, b) => (b['overallScore'] as num).compareTo(a['overallScore'] as num));
  logMessage(context, '[Phase 2] Scored keywords details: $scored');
  return scored.isNotEmpty ? scored : [
    {
      'keyword': 'Artificial Intelligence coding assistants',
      'searchVolume': 45000,
      'trendScore': 95,
      'difficulty': 35,
      'publishersCount': 5,
      'viralityScore': 80,
      'overallScore': 85.0,
      'category': 'Technology',
      'eligible': true
    }
  ];
}

// Topic Clustering
Future<Map<String, String>> createOrGetTopicCluster(
  dynamic context,
  Databases databases,
  String databaseId,
  String newsCollectionId,
  List<Map<String, dynamic>> scoredKeywords,
) async {
  Map<String, dynamic>? selectedKeyword;

  for (final kwData in scoredKeywords) {
    final String keyword = kwData['keyword'] as String;
    try {
      final existing = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: newsCollectionId,
        queries: [
          Query.equal('topic', keyword),
          Query.limit(1),
        ],
      );
      if (existing.total == 0) {
        selectedKeyword = kwData;
        break;
      } else {
        logMessage(context, 'Topic "$keyword" has already been published. Checking next trend...');
      }
    } catch (e) {
      // If query fails (e.g. database not initialized), break and use the first one
      selectedKeyword = kwData;
      break;
    }
  }

  final bestKeyword = selectedKeyword ?? scoredKeywords.first;
  final String pillar = bestKeyword['keyword'] as String;
  final String category = bestKeyword['category'] as String? ?? 'General';
  
  final String clusterId = ID.unique();
  
  try {
    await databases.createDocument(
      databaseId: databaseId,
      collectionId: 'topic_clusters',
      documentId: clusterId,
      data: {
        'pillarKeyword': pillar,
        'category': category,
        'description': 'Topic cluster built around the core pillar topic: $pillar',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  } catch (e) {
    logMessage(context, 'Could not save topic cluster to DB: $e');
  }

  return {
    'pillar': pillar,
    'clusterId': clusterId,
  };
}
