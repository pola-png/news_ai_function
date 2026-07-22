import 'package:http/http.dart' as http;
import 'utils.dart';

class HtmlCleaner {
  static String clean(String html) {
    if (html.isEmpty) return '';
    
    // Remove scripts, styles, head, header, footer, nav, ads, tables
    String cleaned = html
        .replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<head\b[^<]*(?:(?!<\/head>)<[^<]*)*<\/head>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<header\b[^<]*(?:(?!<\/header>)<[^<]*)*<\/header>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<footer\b[^<]*(?:(?!<\/footer>)<[^<]*)*<\/footer>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<nav\b[^<]*(?:(?!<\/nav>)<[^<]*)*<\/nav>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<table\b[^<]*(?:(?!<\/table>)<[^<]*)*<\/table>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<ins\b[^<]*(?:(?!<\/ins>)<[^<]*)*<\/ins>', caseSensitive: false), ' '); // Adsense

    // Remove tags but preserve text content
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), ' ');
    
    // Resolve HTML Entities
    cleaned = cleaned
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&ndash;', '-')
        .replaceAll('&mdash;', '--')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned;
  }
}

class NewsWorthinessEngine {
  static bool check(String title, String context) {
    final combined = '$title $context'.toLowerCase();
    
    // Skip terms that clearly denote personal/non-news elements
    final skipPatterns = [
      'my favorite photo',
      'made hundreds of',
      'i made',
      'look at my',
      'my friend\'s wedding',
      'wedding photo',
      'check out my',
      'just want to share',
      'r/beamazed',
      'r/mildlyinteresting'
    ];

    for (final pattern in skipPatterns) {
      if (combined.contains(pattern)) {
        return false;
      }
    }

    // Must be long enough or contain standard information density
    if (title.split(' ').length < 3) {
      return false;
    }

    return true;
  }
}

class TopicClassifier {
  static String classify(String title, String context) {
    final text = '$title $context'.toLowerCase();
    
    if (text.contains('accident') || text.contains('crash') || text.contains('derail') || text.contains('explosion') || text.contains('casualty') || text.contains('deadly')) {
      return 'Accident';
    }
    if (text.contains('war ') || text.contains('military') || text.contains('battle') || text.contains('soldier') || text.contains('invade') || text.contains('bombed') || text.contains('conflict')) {
      return 'War';
    }
    if (text.contains('election') || text.contains('senate') || text.contains('president') || text.contains('governor') || text.contains('democrat') || text.contains('republican') || text.contains('parliament') || text.contains('congress')) {
      return 'Politics';
    }
    if (text.contains('health') || text.contains('medical') || text.contains('disease') || text.contains('vaccine') || text.contains('virus') || text.contains('hospital') || text.contains('diet') || text.contains('food')) {
      return 'Health';
    }
    if (text.contains('football') || text.contains('sports') || text.contains('olympics') || text.contains('match') || text.contains('game') || text.contains('cup') || text.contains('nba') || text.contains('athlete')) {
      return 'Sports';
    }
    if (text.contains('stock') || text.contains('finance') || text.contains('market') || text.contains('inflation') || text.contains('revenue') || text.contains('economic') || text.contains('shares') || text.contains('billion') || text.contains('million') || text.contains('firm') || text.contains('company') || text.contains('business') || text.contains('corporate')) {
      return 'Business';
    }
    if (text.contains('space') || text.contains('nasa') || text.contains('science') || text.contains('quantum') || text.contains('biology') || text.contains('physics') || text.contains('earth') || text.contains('dna') || text.contains('star') || text.contains('galaxy') || text.contains('protein')) {
      return 'Science';
    }
    if (text.contains('movie') || text.contains('film') || text.contains('celebrity') || text.contains('music') || text.contains('actor') || text.contains('hollywood') || text.contains('album') || text.contains('concert')) {
      return 'Entertainment';
    }
    if (text.contains('history') || text.contains('historical') || text.contains('ancient') || text.contains('century') || text.contains('dead men') || text.contains('world war') || text.contains('archaeology') || text.contains('fortress')) {
      return 'History';
    }
    if (text.contains('ai') || text.contains('programming') || text.contains('code') || text.contains('software') || text.contains('windows') || text.contains('intel') || text.contains('gpu') || text.contains('chatgpt') || text.contains('developer') || text.contains('computer') || text.contains('silicon') || text.contains('crypto') || text.contains('bitcoin') || text.contains('technology') || text.contains('tech')) {
      return 'Tech';
    }
    
    return 'News'; // Default dynamic standard news category
  }
}

class EntityRecognizer {
  static Map<String, String> recognize(String title, String context) {
    final text = '$title $context';
    final Map<String, String> entities = {};
    
    // Year extraction
    final yearRegex = RegExp(r'\b(1[89]\d{2}|20\d{2})\b');
    final yearMatch = yearRegex.firstMatch(text);
    if (yearMatch != null) {
      entities['Year'] = yearMatch.group(0)!;
    }

    // Attempt simple capitalization-based entity tags (e.g. Russia, Osowiec, Tesla)
    final capRegex = RegExp(r'\b([A-Z][a-zA-Z]+)\b');
    final matches = capRegex.allMatches(text);
    final List<String> properNouns = [];
    for (final match in matches) {
      final val = match.group(0)!;
      if (val != 'I' && val != 'The' && val != 'A' && val != 'An' && !properNouns.contains(val)) {
        properNouns.add(val);
      }
    }
    if (properNouns.isNotEmpty) {
      entities['Subject'] = properNouns[0];
      if (properNouns.length > 1) {
        entities['LocationOrOrganization'] = properNouns[1];
      }
    }

    return entities;
  }
}

class SourceScraper {
  static Future<Map<String, dynamic>> scrape(dynamic context, String? url) async {
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      return {'content': '', 'images': <String>[]};
    }
    
    logMessage(context, '[SourceScraper] Crawling external source: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final html = response.body;
        
        // Extract Image URLs
        final List<String> extractedImages = [];
        final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false);
        final matches = imgRegex.allMatches(html);
        for (final match in matches) {
          String imgUrl = match.group(1)!;
          if (imgUrl.startsWith('//')) {
            imgUrl = 'https:$imgUrl';
          } else if (imgUrl.startsWith('/') && !imgUrl.startsWith('//')) {
            final uri = Uri.parse(url);
            imgUrl = '${uri.scheme}://${uri.host}$imgUrl';
          }
          if (imgUrl.startsWith('http') && !extractedImages.contains(imgUrl)) {
            extractedImages.add(imgUrl);
          }
          if (extractedImages.length >= 5) break;
        }

        // Clean HTML to text
        final cleanedText = HtmlCleaner.clean(html);
        
        // Return first 6000 characters of clean text
        final content = cleanedText.length > 6000 ? cleanedText.substring(0, 6000) : cleanedText;
        return {
          'content': content,
          'images': extractedImages,
        };
      }
    } catch (e) {
      logMessage(context, '[SourceScraper] Scraper failed for $url: $e');
    }
    
    return {'content': '', 'images': <String>[]};
  }
}
