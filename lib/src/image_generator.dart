import 'dart:convert';
import 'package:http/http.dart' as http;

String toHdImageUrl(String url) {
  if (url.isEmpty) return '';
  var hdUrl = url;

  if (hdUrl.contains('unsplash.com')) {
    hdUrl = hdUrl.replaceAll(RegExp(r'[?&]w=\d+'), '');
    hdUrl = hdUrl.replaceAll(RegExp(r'[?&]q=\d+'), '');
    hdUrl = hdUrl.replaceAll(RegExp(r'[?&]h=\d+'), '');
    if (hdUrl.contains('?')) {
      hdUrl = '$hdUrl&w=1200&q=85&fit=crop';
    } else {
      hdUrl = '$hdUrl?w=1200&q=85&fit=crop';
    }
    return hdUrl;
  }

  if (hdUrl.contains('wikimedia.org') && hdUrl.contains('/thumb/')) {
    final parts = hdUrl.split('/');
    if (parts.length > 2) {
      final cleanedParts = parts.toList()..removeLast()..removeWhere((p) => p == 'thumb');
      hdUrl = cleanedParts.join('/');
      return hdUrl;
    }
  }

  final wpRegex = RegExp(r'-\d+x\d+(\.(jpg|jpeg|png|webp|gif))$', caseSensitive: false);
  if (wpRegex.hasMatch(hdUrl)) {
    hdUrl = hdUrl.replaceFirstMapped(wpRegex, (match) => match.group(1)!);
    return hdUrl;
  }

  if (hdUrl.contains('googleusercontent.com') || hdUrl.contains('blogspot.com')) {
    hdUrl = hdUrl.replaceAll(RegExp(r'/w\d+-h\d+/'), '/s1200/');
    hdUrl = hdUrl.replaceAll(RegExp(r'/s\d+/'), '/s1200/');
  }

  return hdUrl;
}

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
            return toHdImageUrl(imageUrl);
          }
        }
      }
    } catch (_) {}
  }
  
  return '';
}
