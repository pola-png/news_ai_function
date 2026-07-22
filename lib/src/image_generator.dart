import 'dart:convert';
import 'package:http/http.dart' as http;

// Phase 7: Image Generation
Future<String> generateFeaturedImage(
  dynamic context,
  Map<String, String> env,
  String topic,
  String title,
) async {
  final String? newsApiKey = env['NEWS_IMAGE_API_KEY'];
  if (newsApiKey != null && newsApiKey.isNotEmpty) {
    try {
      final uri = Uri.parse('https://newsapi.org/v2/everything?q=${Uri.encodeComponent(topic)}&pageSize=1');
      final resp = await http.get(uri, headers: {'X-Api-Key': newsApiKey});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List<dynamic> articles = data['articles'] as List<dynamic>? ?? [];
        if (articles.isNotEmpty) {
          final imageUrl = articles.first['urlToImage'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            return imageUrl;
          }
        }
      }
    } catch (_) {}
  }
  
  return '';
}
