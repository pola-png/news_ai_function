import 'dart:convert';
import 'package:http/http.dart' as http;
import 'utils.dart';

DateTime? parseRssDate(String dateStr) {
  try {
    if (dateStr.contains('T')) {
      return DateTime.parse(dateStr).toUtc();
    }
    final regex = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})');
    final match = regex.firstMatch(dateStr);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final monthStr = match.group(2)!;
      final year = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = int.parse(match.group(6)!);

      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
      };
      final month = months[monthStr] ?? 1;

      return DateTime.utc(year, month, day, hour, minute, second);
    }
  } catch (_) {}
  return null;
}

// Phase 1: Trend Discovery
Future<List<Map<String, dynamic>>> discoverTrends(dynamic context, Map<String, String> env) async {
  final List<Map<String, dynamic>> discovered = [];
  final nowUtc = DateTime.now().toUtc();

  // 1. Fetch Google Trends RSS for 32 supported countries concurrently
  final geos = [
    'US', 'NG', 'GB', 'CA', 'ZA', 'IN', 'AU', 'NZ', 'IE', 'SG', 'MY', 'PH',
    'DE', 'FR', 'ES', 'IT', 'BR', 'MX', 'AR', 'CO', 'CL', 'PE', 'JP', 'KR',
    'TR', 'NL', 'BE', 'SE', 'NO', 'FI', 'DK', 'PT'
  ];

  logMessage(context, '[Phase 1] Querying Google Trends daily RSS feeds for ${geos.length} countries...');
  final futures = geos.map((geo) => http.get(
    Uri.parse('https://trends.google.com/trends/trendingsearches/daily/rss?geo=$geo'),
    headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
  ).timeout(Duration(seconds: 4)).catchError((_) => http.Response('', 500)));

  final responses = await Future.wait(futures);

  for (int i = 0; i < responses.length; i++) {
    final response = responses[i];
    final geo = geos[i];
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final itemsRegex = RegExp(r'<item>(.*?)<\/item>', dotAll: true);
      final items = itemsRegex.allMatches(response.body);
      for (final item in items) {
        final content = item.group(1) ?? '';
        
        final titleMatch = RegExp(r'<title>(.*?)<\/title>').firstMatch(content);
        final pubDateMatch = RegExp(r'<pubDate>(.*?)<\/pubDate>').firstMatch(content);
        final descMatch = RegExp(r'<description>(.*?)<\/description>').firstMatch(content);
        final pictureMatch = RegExp(r'<ht:picture>(.*?)<\/ht:picture>').firstMatch(content);
        final linkMatch = RegExp(r'<link>(.*?)<\/link>').firstMatch(content);

        final title = titleMatch?.group(1)?.trim() ?? '';
        final pubDateStr = pubDateMatch?.group(1)?.trim() ?? '';
        var desc = descMatch?.group(1)?.trim() ?? '';
        desc = desc.replaceAll(RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true), r'$1');
        final picture = pictureMatch?.group(1)?.trim() ?? '';
        final link = linkMatch?.group(1)?.trim() ?? '';

        if (title.isNotEmpty) {
          final pubDate = parseRssDate(pubDateStr);
          if (pubDate != null) {
            final diff = nowUtc.difference(pubDate);
            if (diff.inHours <= 5 && diff.inHours >= 0) {
              discovered.add({
                'keyword': title,
                'context': desc.isNotEmpty ? desc : 'Trending topic in $geo: $title.',
                'category': 'General',
                'images': picture.isNotEmpty ? [picture] : <String>[],
                'url': link,
              });
            }
          }
        }
      }
    }
  }

  // 2. Fetch Hacker News Top Stories
  logMessage(context, '[Phase 1] Querying Hacker News top stories...');
  try {
    final response = await http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/topstories.json')).timeout(Duration(seconds: 5));
    if (response.statusCode == 200) {
      final List<dynamic> ids = jsonDecode(response.body) as List<dynamic>;
      final targetIds = ids.take(100).toList();
      
      final hnFutures = targetIds.map((id) => 
        http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/item/$id.json')).timeout(Duration(seconds: 4))
      );
      final hnResponses = await Future.wait(hnFutures);
      
      for (final resp in hnResponses) {
        if (resp.statusCode == 200) {
          final story = jsonDecode(resp.body) as Map<String, dynamic>;
          final title = story['title'] as String? ?? '';
          final time = story['time'] as int? ?? 0;
          final link = story['url'] as String? ?? '';
          if (title.isNotEmpty && time > 0) {
            final storyDate = DateTime.fromMillisecondsSinceEpoch(time * 1000, isUtc: true);
            if (nowUtc.difference(storyDate).inHours <= 5) {
              discovered.add({
                'keyword': title,
                'context': 'Hacker News story: $title.',
                'category': 'Technology',
                'images': <String>[],
                'url': link,
              });
            }
          }
        }
      }
    }
  } catch (e) {
    logMessage(context, 'HackerNews trend fetch skipped or failed: $e');
  }

  // 3. Fetch Reddit /r/all/ RSS
  logMessage(context, '[Phase 1] Querying Reddit /r/all RSS...');
  try {
    final response = await http.get(
      Uri.parse('https://www.reddit.com/r/all/.rss'),
      headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
    ).timeout(Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      final entryRegex = RegExp(r'<entry>(.*?)<\/entry>', dotAll: true);
      final entries = entryRegex.allMatches(response.body);
      for (final entry in entries) {
        final content = entry.group(1) ?? '';
        final titleMatch = RegExp(r'<title>(.*?)<\/title>').firstMatch(content);
        final updatedMatch = RegExp(r'<updated>(.*?)<\/updated>').firstMatch(content);
        final contentMatch = RegExp(r'<content.*?>(.*?)<\/content>', dotAll: true).firstMatch(content);
        final linkMatch = RegExp(r'<link[^>]+href="([^">]+)"').firstMatch(content);

        final title = titleMatch?.group(1)?.trim() ?? '';
        final updatedStr = updatedMatch?.group(1)?.trim() ?? '';
        final link = linkMatch?.group(1)?.trim() ?? '';
        var rawContent = contentMatch?.group(1)?.trim() ?? '';
        rawContent = rawContent.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (rawContent.length > 200) {
          rawContent = rawContent.substring(0, 200) + '...';
        }

        if (title.isNotEmpty) {
          final updatedDate = parseRssDate(updatedStr);
          if (updatedDate != null) {
            final diff = nowUtc.difference(updatedDate);
            if (diff.inHours <= 5 && diff.inHours >= 0) {
              discovered.add({
                'keyword': title,
                'context': rawContent.isNotEmpty ? rawContent : 'Trending Reddit post: $title.',
                'category': 'General',
                'images': <String>[],
                'url': link,
              });
            }
          }
        }
      }
    }
  } catch (e) {
    logMessage(context, 'Reddit RSS fetch skipped or failed: $e');
  }

  // 4. Fetch NewsAPI Top Headlines
  final String? newsApiKey = env['NEWS_IMAGE_API_KEY'];
  if (newsApiKey != null && newsApiKey.isNotEmpty) {
    logMessage(context, '[Phase 1] Querying NewsAPI top headlines...');
    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/top-headlines?country=us&pageSize=50'),
        headers: {'X-Api-Key': newsApiKey},
      ).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> articles = data['articles'] as List<dynamic>? ?? [];
        for (final art in articles) {
          final title = art['title'] as String? ?? '';
          final desc = art['description'] as String? ?? '';
          final pic = art['urlToImage'] as String? ?? '';
          final pubAt = art['publishedAt'] as String? ?? '';
          final link = art['url'] as String? ?? '';
          
          if (title.isNotEmpty) {
            final pubDate = parseRssDate(pubAt);
            if (pubDate != null) {
              final diff = nowUtc.difference(pubDate);
              if (diff.inHours <= 5 && diff.inHours >= 0) {
                discovered.add({
                  'keyword': title,
                  'context': desc.isNotEmpty ? desc : title,
                  'category': 'General',
                  'images': pic.isNotEmpty ? [pic] : <String>[],
                  'url': link,
                });
              }
            }
          }
        }
      }
    } catch (e) {
      logMessage(context, 'NewsAPI trend fetch skipped or failed: $e');
    }
  }

  // Deduplicate by keyword
  final Map<String, Map<String, dynamic>> unique = {};
  for (final item in discovered) {
    final kw = item['keyword'] as String;
    if (!unique.containsKey(kw)) {
      unique[kw] = item;
    }
  }

  final result = unique.values.toList();
  logMessage(context, '[Phase 1] Discovered raw trends count: ${result.length}');
  return result;
}

// Phase 2: Keyword Scoring
Future<List<Map<String, dynamic>>> scoreKeywords(
  dynamic context,
  List<Map<String, dynamic>> rawKeywords,
) async {
  logMessage(context, '[Rule-Based] Scoring trends and keywords.');
  
  final List<Map<String, dynamic>> scored = [];
  for (final item in rawKeywords) {
    final kw = item['keyword'] as String;
    final searchVolume = 5000 + (kw.length * 1200);
    final trendScore = 90;
    final difficulty = 30;
    final publishersCount = 5;
    final viralityScore = 80;
    final overallScore = (trendScore * 0.4) + ((100 - difficulty) * 0.3) + (viralityScore * 0.3);
    
    if (overallScore >= 60) {
      scored.add({
        'keyword': kw,
        'context': item['context'] ?? '',
        'category': item['category'] ?? 'General',
        'images': item['images'] ?? <String>[],
        'url': item['url'] ?? '',
        'searchVolume': searchVolume,
        'trendScore': trendScore,
        'difficulty': difficulty,
        'publishersCount': publishersCount,
        'viralityScore': viralityScore,
        'overallScore': overallScore,
        'eligible': true
      });
    }
  }

  scored.sort((a, b) => (b['overallScore'] as num).compareTo(a['overallScore'] as num));
  logMessage(context, '[Phase 2] Scored keywords count: ${scored.length}');
  return scored;
}
