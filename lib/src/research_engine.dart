import 'dart:convert';
import 'package:http/http.dart' as http;
import 'utils.dart';

// Phase 3: Research AI / Knowledge Builder
Future<Map<String, dynamic>> buildResearchKnowledge(
  dynamic context,
  String apiKey,
  String model,
  String topic,
) async {
  final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
  
  final prompt = '''
  Conduct structured research on the topic: "$topic".
  Produce a comprehensive factual Knowledge Object. Extract facts, timeline, statistics, entities, and reliable sources.
  
  Return format must be valid JSON:
  {
    "title": "$topic",
    "facts": [
      "Fact statement 1",
      "Fact statement 2"
    ],
    "timeline": [
      {"date": "2026-Q1", "event": "Event description"}
    ],
    "statistics": [
      {"metric": "Usage metric", "value": "85%"}
    ],
    "entities": {
      "companies": ["Company A"],
      "people": ["Person A"],
      "locations": ["Global"]
    },
    "sources": [
      "https://example.com/source1"
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
          {'role': 'system', 'content': 'You are a Knowledge Graph Researcher AI that compiles verified facts.'},
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
    logMessage(context, 'Research Builder failed: $e');
  }

  return {
    'title': topic,
    'facts': ['General industry advancements in technology.'],
    'timeline': [{'date': 'Present', 'event': 'Ongoing development.'}],
    'statistics': [{'metric': 'Interest', 'value': 'High'}],
    'entities': {'companies': [], 'people': [], 'locations': []},
    'sources': ['https://wikipedia.org']
  };
}
