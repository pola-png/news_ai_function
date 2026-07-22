
// Phase 6: SEO Engine
Map<String, dynamic> generateSeoMetadata({
  required String title,
  required String body,
  required String summary,
  required String imageUrl,
  required String language,
  required List<dynamic> faqs,
}) {
  final slug = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');

  final canonicalUrl = 'https://xapzap.com/news/$slug';

  final words = body
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z\s]'), '')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 5)
      .toList();
  final wordCounts = <String, int>{};
  for (final w in words) {
    wordCounts[w] = (wordCounts[w] ?? 0) + 1;
  }
  final sortedWords = wordCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final keywords = sortedWords.take(5).map((e) => e.key).toList();
  if (keywords.isEmpty) keywords.add('technology');

  final Map<String, dynamic> jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'NewsArticle',
    'headline': title,
    'image': [imageUrl],
    'datePublished': DateTime.now().toUtc().toIso8601String(),
    'dateModified': DateTime.now().toUtc().toIso8601String(),
    'author': {
      '@type': 'Organization',
      'name': 'XapZap News',
      'url': 'https://xapzap.com'
    },
    'publisher': {
      '@type': 'Organization',
      'name': 'XapZap',
      'logo': {
        '@type': 'ImageObject',
        'url': 'https://xapzap.com/logo.png'
      }
    },
    'description': summary,
  };

  if (faqs.isNotEmpty) {
    final List<Map<String, dynamic>> faqEntities = [];
    for (final faq in faqs) {
      faqEntities.add({
        '@type': 'Question',
        'name': faq['question'] ?? '',
        'acceptedAnswer': {
          '@type': 'Answer',
          'text': faq['answer'] ?? '',
        }
      });
    }
    jsonLd['mainEntity'] = faqEntities;
  }

  return {
    'title': title.length > 60 ? '${title.substring(0, 57)}...' : title,
    'description': summary.length > 160 ? '${summary.substring(0, 157)}...' : summary,
    'slug': slug,
    'keywords': keywords,
    'canonicalUrl': canonicalUrl,
    'jsonLd': jsonLd,
  };
}
