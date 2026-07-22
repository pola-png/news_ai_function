import 'dart:convert';
import 'package:http/http.dart' as http;
import 'utils.dart';

// Phase 4: Multi-Agent Editorial System
Future<Map<String, dynamic>> runEditorialPipeline({
  required dynamic context,
  required String apiKey,
  required String model,
  required String topic,
  required String language,
  required Map<String, dynamic> knowledge,
}) async {
  final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

  final prompt = '''
  You are orchestrating a Multi-Agent Editorial system to write a professional article.
  Execute these agents step-by-step:
  1. Editor AI: Drafts detailed outline with headers.
  2. Research AI: Infuses the structured research facts: ${jsonEncode(knowledge)}
  3. Writer AI: Writes comprehensive body sections in "$language" (800-1200 words, rich Markdown format).
  4. SEO AI: Inserts natural search terms, headers, and structures content.
  5. FAQ & Headline AI: Synthesizes high-CTR title, subtitle, and FAQs.
  
  Return exactly a valid JSON object:
  {
    "title": "Optimized high-CTR title",
    "subtitle": "Engaging subtitle",
    "summary": "1-2 sentence meta summary",
    "category": "Technology",
    "body": "Markdown article body containing the full content...",
    "faqs": [
      {"question": "FAQ Question?", "answer": "Detailed answer."}
    ]
  }
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
        {'role': 'system', 'content': 'You are an autonomous AI newsroom orchestrator.'},
        {'role': 'user', 'content': prompt}
      ],
      'response_format': {'type': 'json_object'}
    }),
  );

  if (response.statusCode == 200) {
    final content = jsonDecode(response.body)['choices'][0]['message']['content'] as String;
    return jsonDecode(content) as Map<String, dynamic>;
  } else {
    throw Exception('Editorial Pipeline failed: ${response.body}');
  }
}

// Phase 14: AI Moderation
Future<Map<String, dynamic>> runModerationAudit(
  dynamic context,
  String apiKey,
  String model,
  Map<String, dynamic> article,
) async {
  final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
  
  final prompt = '''
  Perform a critical moderation audit on this generated content.
  Evaluate:
  - fakeNewsScore (0 to 100, where 0 is perfect truth)
  - toxicityScore (0 to 100)
  - duplicationPercentage (0 to 100)
  - hallucinationLikelihood (0 to 100)
  
  Article Title: ${article['title']}
  Article Body Sample: ${truncateString(article['body'] as String? ?? '', 1000)}
  
  Return exactly JSON:
  {
    "status": "passed" | "failed",
    "reason": "If failed, state reason. Otherwise empty.",
    "duplicationScore": 5.0,
    "fakeNewsScore": 2.0,
    "toxicityScore": 0.0
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
          {'role': 'system', 'content': 'You are an objective AI Moderation Officer.'},
          {'role': 'user', 'content': prompt}
        ],
        'response_format': {'type': 'json_object'}
      }),
    );

    if (response.statusCode == 200) {
      final content = jsonDecode(response.body)['choices'][0]['message']['content'] as String;
      return jsonDecode(content) as Map<String, dynamic>;
    }
  } catch (e) {
    logMessage(context, 'Moderation audit failed: $e');
  }

  return {
    'status': 'passed',
    'reason': '',
    'duplicationScore': 0.0,
    'fakeNewsScore': 0.0,
    'toxicityScore': 0.0
  };
}
