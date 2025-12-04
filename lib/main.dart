import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:http/http.dart' as http;

/// Appwrite function entrypoint for generating AI-written news articles.
///
/// Expects JSON body:
/// {
///   "topic": "fuel price Nigeria",
///   "language": "en",                // optional, default "en"
///   "trendType": "trending",         // optional
///   "trendScore": 3.4,               // optional
///   "trendSource": ["google_trends", "twitter"], // optional
///   "trendWindowMinutes": 20        // optional
/// }
///
/// Required env vars (Function settings):
/// - APPWRITE_ENDPOINT
/// - APPWRITE_PROJECT_ID
/// - APPWRITE_API_KEY
/// - APPWRITE_DATABASE_ID          (e.g. "xapzap_db")
/// - NEWS_COLLECTION_ID or NEWS_TABLE_ID  (we default to "news")
/// - OPENAI_API_KEY
/// Optional:
/// - OPENAI_MODEL                  (default: "gpt-5-nano")
/// - NEWS_DEFAULT_THUMBNAIL_URL
void _log(dynamic context, String message) {
  try {
    // New Appwrite runtimes expose `log` on the context.
    context.log(message);
  } catch (_) {
    stderr.writeln(message);
  }
}

Future<dynamic> main(dynamic context) async {
  final req = context.req;
  final res = context.res;
  // Use process environment; RuntimeContext may not expose `env` directly.
  final Map<String, String> env = Platform.environment;

  _log(context, '[news_ai] Invocation started');

  if (req.method.toUpperCase() != 'POST') {
    return res.json({'error': 'Only POST is allowed'}, 405);
  }

  try {
    // ---------- Parse input ----------
    final rawBody = req.body ?? '{}';
    final Map<String, dynamic> body =
        jsonDecode(rawBody) as Map<String, dynamic>;

    final String? rawTopic = (body['topic'] as String?)?.trim();
    if (rawTopic == null || rawTopic.isEmpty) {
      return res.json({'error': 'topic is required'}, 400);
    }
    final String topic = rawTopic;
    final String language =
        ((body['language'] as String?) ?? 'en').trim().toLowerCase();

    final String trendType =
        (body['trendType'] as String?)?.trim() ?? 'manual';
    final double? trendScore = (body['trendScore'] is num)
        ? (body['trendScore'] as num).toDouble()
        : null;
    final int? trendWindowMinutes =
        (body['trendWindowMinutes'] is num)
            ? (body['trendWindowMinutes'] as num).toInt()
            : null;
    final List<String> trendSource = (body['trendSource'] is List)
        ? (body['trendSource'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    // ---------- Env vars ----------
    final String? openaiKey = env['OPENAI_API_KEY'];
    if (openaiKey == null || openaiKey.isEmpty) {
      _log(context, '[news_ai] OPENAI_API_KEY is missing');
      return res.json(
        {'error': 'Failed to generate news'},
        500,
      );
    }
    final String openaiModel = env['OPENAI_MODEL'] ?? 'gpt-5-nano';

    final String? appwriteEndpoint = env['APPWRITE_ENDPOINT'];
    final String? appwriteProjectId = env['APPWRITE_PROJECT_ID'];
    final String? appwriteApiKey = env['APPWRITE_API_KEY'];

    if (appwriteEndpoint == null ||
        appwriteProjectId == null ||
        appwriteApiKey == null) {
      _log(
        context,
        '[news_ai] Appwrite env missing: endpoint=$appwriteEndpoint projectId=$appwriteProjectId apiKeyConfigured=${appwriteApiKey != null}',
      );
      return res.json(
        {'error': 'Failed to generate news'},
        500,
      );
    }

    final String databaseId = env['APPWRITE_DATABASE_ID'] ?? 'xapzap_db';
    final String newsCollectionId =
        env['NEWS_TABLE_ID'] ?? env['NEWS_COLLECTION_ID'] ?? 'news';
    final String defaultThumb =
        env['NEWS_DEFAULT_THUMBNAIL_URL']?.toString() ?? '';

    _log(context, '[news_ai] Calling OpenAI model=$openaiModel topic="$topic" language=$language');
    // ---------- Generate article with OpenAI ----------
    final article = await _generateArticle(
      apiKey: openaiKey,
      model: openaiModel,
      topic: topic,
      language: language,
    );

    final String title = article['title']!;
    final String summary = article['summary']!;
    final String content = article['body']!;

    // ---------- SEO ----------
    final seo = _buildSeo(title, content);

    _log(context, '[news_ai] OpenAI article generated, storing in Appwrite...');
    // ---------- Store in Appwrite ----------
    final client = Client()
      ..setEndpoint(appwriteEndpoint)
      ..setProject(appwriteProjectId)
      ..setKey(appwriteApiKey);

    final databases = Databases(client);
    final now = DateTime.now().toUtc().toIso8601String();

    final String docId = ID.unique();
    final String newsId = docId;

    final Map<String, dynamic> data = {
      // Core identity
      'newsId': newsId,
      'topic': topic,
      'language': language,

      // Content
      'title': title,
      'subtitle': null,
      'content': content,
      'summary': summary,
      'category': null,
      'tags': seo['keywords'] as List<String>,

      // Media (placeholder thumbnail for now)
      // NOTE: collection uses `thumbnailUr` (without the second "l")
      'thumbnailUr': defaultThumb,
      'imageUrls': <String>[],
      'videoUrl': null,
      'mediaSource': null,
      'mediaCredits': null,

      // SEO
      'seoTitle': seo['title'],
      'seoDescription': seo['description'],
      'seoSlug': seo['slug'],
      'seoKeywords': (seo['keywords'] as List<String>).join(','),
      'canonicalUrl': null,
      'ogImageUrl': defaultThumb.isNotEmpty ? defaultThumb : null,

      // AI
      'aiModel': openaiModel,
      'aiPrompt':
          'News article for topic "$topic" in "$language" generated by $openaiModel.',
      'aiConfidence': null,
      'aiGenerated': true,
      'aiEditedByUserId': null,

      // Trend metadata
      'trendType': trendType,
      'trendScore': trendScore,
      'trendSource': trendSource,
      'trendWindowMinutes': trendWindowMinutes,

      // Engagement
      'views': 0,
      'uniqueViews': 0,
      'likes': 0,
      'commentsCount': 0,
      'shares': 0,
      'bookmarks': 0,
      'trendingScore': null,

      // Moderation / region
      'status': 'published',
      'isFlagged': false,
      'flagReason': null,
      'flagCount': 0,
      'blockedInCountries': null,
      'ageRating': null,
      'region': null,
      'city': null,
      'country': null,
      'timezone': null,

      // Audit
      'sourceType': 'ai_trending',
      'publishedAt': now,
      'createdByUserId': null,
      'approvedByUserId': null,
    };

    final created = await databases.createDocument(
      databaseId: databaseId,
      collectionId: newsCollectionId,
      documentId: docId,
      data: data,
    );

    _log(
      context,
      '[news_ai] Stored news document id=${created.$id} topic="$topic" language=$language',
    );

    return res.json(
      {
        'status': 'ok',
        'id': created.$id,
        'newsId': newsId,
        'title': title,
        'language': language,
        'trendType': trendType,
      },
      201,
    );
  } catch (e, st) {
    _log(context, 'Error in news_ai_function: $e');
    _log(context, st.toString());
    return res.json(
      {
        'error': 'Failed to generate news',
        'detail': e.toString(),
      },
      500,
    );
  }
}

Future<Map<String, String>> _generateArticle({
  required String apiKey,
  required String model,
  required String topic,
  required String language,
}) async {
  final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

  final userContent = '''
Write a high-quality news article in language code "$language" about the topic:
"$topic".

Requirements:
- Be factual and unbiased, like a serious news outlet.
- Include recent context and why this topic matters right now.
- Structure it as: title, short summary (1–2 sentences), then full body (600–900 words).
- Do not copy text from any source; write everything from scratch.
Return ONLY valid JSON with exactly these keys: "title", "summary", "body".
''';

  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a professional journalist for a global news site.',
        },
        {
          'role': 'user',
          'content': userContent,
        },
      ],
    }),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'OpenAI error ${response.statusCode}: ${response.body}',
    );
  }

  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  final choices = decoded['choices'] as List<dynamic>? ?? const [];
  if (choices.isEmpty) {
    throw Exception('OpenAI returned no choices');
  }
  final message = choices.first['message'] as Map<String, dynamic>;
  final content = (message['content'] as String?)?.trim();
  if (content == null || content.isEmpty) {
    throw Exception('OpenAI returned empty content');
  }

  // Model was asked to return JSON; try to parse.
  Map<String, dynamic> json;
  try {
    json = jsonDecode(content) as Map<String, dynamic>;
  } catch (_) {
    // Fallback: wrap content as body.
    final snippet = _truncate(content, 240);
    json = {
      'title': topic,
      'summary': snippet,
      'body': content,
    };
  }

  String title = (json['title'] as String? ?? topic).trim();
  String summary = (json['summary'] as String? ?? '').trim();
  String body = (json['body'] as String? ?? '').trim();

  if (title.isEmpty) title = topic;
  if (body.isEmpty) body = summary;
  if (summary.isEmpty) summary = _truncate(body, 240);

  return {
    'title': title,
    'summary': summary,
    'body': body,
  };
}

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength);
}

Map<String, dynamic> _buildSeo(String rawTitle, String rawContent) {
  final title = rawTitle.trim();
  final normalized = rawContent.replaceAll('\n', ' ').trim();

  final String description;
  if (normalized.length <= 160) {
    description = normalized;
  } else {
    description = '${normalized.substring(0, 157)}...';
  }

  final slug = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');

  final tokens = normalized
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.length >= 4)
      .toList();

  final counts = <String, int>{};
  for (final t in tokens) {
    counts[t] = (counts[t] ?? 0) + 1;
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final keywords = sorted.take(8).map((e) => e.key).toList();

  final String seoTitle;
  if (title.length <= 60) {
    seoTitle = title;
  } else {
    seoTitle = '${title.substring(0, 57)}...';
  }

  return {
    'title': seoTitle,
    'description': description,
    'slug': slug,
    'keywords': keywords,
  };
}
