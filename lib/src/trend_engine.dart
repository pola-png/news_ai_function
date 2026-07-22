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
