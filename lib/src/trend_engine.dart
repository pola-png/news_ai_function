import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:http/http.dart' as http;
import 'utils.dart';

// Phase 1: Trend Discovery
Future<List<String>> discoverTrends(dynamic context, Map<String, String> env) async {
  final List<String> discovered = [];

  try {
    final response = await http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/topstories.json')).timeout(Duration(seconds: 5));
    if (response.statusCode == 200) {
      final List<dynamic> ids = jsonDecode(response.body) as List<dynamic>;
      for (final id in ids.take(5)) {
        final storyResp = await http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/item/$id.json'));
        if (storyResp.statusCode == 200) {
          final story = jsonDecode(storyResp.body) as Map<String, dynamic>;
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

  final standardTrends = [
    'Artificial Intelligence coding assistants',
    'Open-source LLM local deployment',
    'Next.js 16 server components performance',
    'Quantum computing cloud access',
    'Rust programming language memory safety benefits'
  ];
  discovered.addAll(standardTrends);

  return discovered.toSet().toList();
}

// Phase 2: Keyword Scoring
Future<List<Map<String, dynamic>>> scoreKeywords(
  dynamic context,
  String apiKey,
  String model,
  List<String> rawKeywords,
) async {
  final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
  
  final prompt = '''
  Analyze the following list of raw discovered trend topics and evaluate them for publication eligibility.
  For each topic, estimate:
  - searchVolume (monthly searches, scale 100 - 1000000)
  - trendScore (0 to 100)
  - difficulty (SEO difficulty, 0 to 100)
  - publishersCount (estimated competing publishers covering it)
  - viralityScore (0 to 100)
  
  Calculate a final overallScore = (trendScore * 0.4) + ((100 - difficulty) * 0.3) + (viralityScore * 0.3).
  
  Raw Topics:
  ${rawKeywords.join('\n')}
  
  Return response as a valid JSON object matching this schema:
  {
    "keywords": [
      {
        "keyword": "Pillar Topic Name",
        "searchVolume": 15000,
        "trendScore": 85,
        "difficulty": 40,
        "publishersCount": 12,
        "viralityScore": 75,
        "overallScore": 81.0,
        "category": "Technology",
        "eligible": true
      }
    ]
  }
  ''';

  try {
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': 'You are a professional SEO Data Analyst AI.'},
          {'role': 'user', 'content': prompt}
        ],
        'response_format': {'type': 'json_object'}
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content);
      final List<dynamic> list = parsed['keywords'] as List<dynamic>? ?? [];
      
      final eligible = list
          .map((e) => e as Map<String, dynamic>)
          .where((item) => (item['overallScore'] as num? ?? 0) >= 60)
          .toList();
      return eligible;
    }
  } catch (e) {
    logMessage(context, 'Error scoring keywords: $e');
  }

  return [
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
  List<Map<String, dynamic>> scoredKeywords,
) async {
  final bestKeyword = scoredKeywords.first;
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
