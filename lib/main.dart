import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'src/utils.dart';
import 'src/trend_engine.dart';
import 'src/research_engine.dart';
import 'src/editorial_engine.dart';
import 'src/seo_engine.dart';
import 'src/image_generator.dart';
import 'src/link_builder.dart';

/// Appwrite function entrypoint for the AI Autonomous Publishing Platform.
Future<dynamic> main(dynamic context) async {
  final req = context.req;
  final res = context.res;
  final Map<String, String> env = Platform.environment;

  logMessage(context, '[publishing_platform] Platform execution started');

  final method = req.method.toUpperCase();
  if (method != 'POST' && method != 'GET') {
    return res.json({'error': 'Only GET and POST are allowed'}, 405);
  }

  try {
    // 1. Parse input parameters
    final String rawBody = (req.body as String? ?? '').trim();
    final Map<String, dynamic> body = rawBody.isEmpty 
        ? <String, dynamic>{} 
        : jsonDecode(rawBody) as Map<String, dynamic>;
    final String topicInput = ((body['topic'] as String?) ?? 'auto').trim();
    final String language = ((body['language'] as String?) ?? 'en').trim().toLowerCase();
    final bool publishImmediately = body['publishImmediately'] as bool? ?? true;
    final bool dryRun = body['dryRun'] as bool? ?? false;

    final String? appwriteEndpoint = env['APPWRITE_ENDPOINT'];
    final String? appwriteProjectId = env['APPWRITE_PROJECT_ID'];
    final String? appwriteApiKey = env['APPWRITE_API_KEY'];

    if (appwriteEndpoint == null || appwriteProjectId == null || appwriteApiKey == null) {
      logMessage(context, '[publishing_platform] Appwrite configuration env variables are missing');
      return res.json({'error': 'Appwrite configurations are missing'}, 500);
    }

    final String databaseId = env['APPWRITE_DATABASE_ID'] ?? 'xapzap_db';
    
    // Initialize Appwrite Clients
    final client = Client()
      ..setEndpoint(appwriteEndpoint)
      ..setProject(appwriteProjectId)
      ..setKey(appwriteApiKey);
    final databases = Databases(client);

    // List of topics to process
    final List<Map<String, dynamic>> targetTopics = [];

    // --- Phase 1 & 2: Trend Discovery, Scoring & Clustering ---
    if (topicInput.toLowerCase() == 'auto') {
      logMessage(context, '[Phase 1] Discovering trending keywords from multiple sources...');
      final discoveredKeywords = await discoverTrends(context, env);
      
      logMessage(context, '[Phase 2] Analyzing and scoring keywords...');
      final scoredKeywords = await scoreKeywords(context, discoveredKeywords);
      
      if (scoredKeywords.isEmpty) {
        return res.json({'status': 'idle', 'message': 'No keywords met the publishing threshold.'}, 200);
      }

      // Filter out keywords that have already been published
      for (final kwData in scoredKeywords) {
        final keyword = kwData['keyword'] as String;
        try {
          final existing = await databases.listDocuments(
            databaseId: databaseId,
            collectionId: env['NEWS_COLLECTION_ID'] ?? 'news',
            queries: [
              Query.equal('topic', keyword),
              Query.limit(1),
            ],
          );
          if (existing.total == 0) {
            targetTopics.add(kwData);
          } else {
            logMessage(context, 'Topic "$keyword" has already been published. Skipping.');
          }
        } catch (_) {
          // Default to add if DB query fails or collections not yet set up
          targetTopics.add(kwData);
        }
      }

      if (targetTopics.isEmpty) {
        return res.json({'status': 'idle', 'message': 'All discovered trending keywords have already been published.'}, 200);
      }
    } else {
      // Single topic input (manual run)
      targetTopics.add({
        'keyword': topicInput,
        'context': 'Manual publication for "$topicInput".',
        'category': 'General',
        'images': <String>[],
      });
    }

    logMessage(context, '[publishing_platform] Found ${targetTopics.length} topics to process.');
    final List<Map<String, dynamic>> publishedArticles = [];

    // Process all discovered trends in a batch
    for (final topicData in targetTopics) {
      final String currentTopic = topicData['keyword'] as String;
      final String category = topicData['category'] as String? ?? 'General';
      final String gatheredContext = topicData['context'] as String? ?? 'No extra context available.';
      final List<dynamic> sourceImages = topicData['images'] as List<dynamic>? ?? [];

      logMessage(context, '\n==================================================');
      logMessage(context, 'PROCESSING TOPIC: "$currentTopic"');
      logMessage(context, '==================================================');

      // Cluster creation (Pillar + Cluster strategy)
      final String clusterId = ID.unique();
      try {
        await databases.createDocument(
          databaseId: databaseId,
          collectionId: 'topic_clusters',
          documentId: clusterId,
          data: {
            'pillarKeyword': currentTopic,
            'category': category,
            'description': 'Topic cluster built around the core pillar topic: $currentTopic',
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          },
        );
      } catch (e) {
        logMessage(context, 'Could not save topic cluster to DB: $e');
      }

      // --- Phase 3: Research AI / Knowledge Builder ---
      logMessage(context, '[Phase 3] Conducting research & building structured knowledge for "$currentTopic"...');
      final knowledge = await buildResearchKnowledge(context, currentTopic, gatheredContext, sourceImages);

      // --- Phase 4 & 5: Multi-Agent Editorial System & Content Types ---
      logMessage(context, '[Phase 4] Launching Editorial pipeline (Editor, Research, Writer, SEO, Grammar, Fact Checker)...');
      final Map<String, dynamic> generatedArticle = await runEditorialPipeline(
        context: context,
        topic: currentTopic,
        language: language,
        knowledge: knowledge,
      );

      // --- Phase 14: AI Moderation ---
      logMessage(context, '[Phase 14] Running AI Moderation and Quality Assurance audits...');
      final moderation = await runModerationAudit(context, generatedArticle);
      if (moderation['status'] == 'failed') {
        logMessage(context, '[Phase 14] Article failed moderation: ${moderation['reason']}. Skipping.');
        continue;
      }

      // --- Phase 7: AI Image Generation ---
      logMessage(context, '[Phase 7] Generating featured media for the article...');
      // Use the first source image if available, else fall back to generation
      final String imageUrl = sourceImages.isNotEmpty
          ? sourceImages.first as String
          : await generateFeaturedImage(context, env, currentTopic, generatedArticle['title']!);

      // --- Phase 6: SEO Engine ---
      logMessage(context, '[Phase 6] Optimizing SEO metadata and schemas...');
      final seoData = generateSeoMetadata(
        title: generatedArticle['title']!,
        body: generatedArticle['body']!,
        summary: generatedArticle['summary']!,
        imageUrl: imageUrl,
        language: language,
        faqs: generatedArticle['faqs'] as List<dynamic>? ?? [],
      );

      // --- Save to Appwrite ---
      final now = DateTime.now().toUtc().toIso8601String();
      final String articleId = ID.unique();

      final Map<String, dynamic> articleDocument = {
        'newsId': articleId,
        'topic': currentTopic,
        'language': language,
        'title': generatedArticle['title']!,
        'subtitle': generatedArticle['subtitle'] ?? '',
        'content': generatedArticle['body']!,
        'summary': generatedArticle['summary']!,
        'category': generatedArticle['category'] ?? 'Technology',
        'tags': (seoData['keywords'] as List<dynamic>).map((e) => e.toString()).toList(),
        'thumbnailUr': imageUrl,
        'imageUrls': sourceImages.map((e) => e.toString()).toList()..add(imageUrl),
        'videoUrl': null,
        'mediaSource': 'AI Generated',
        'mediaCredits': 'Generated by DALL-E / Flux via Platform',
        
        // SEO Fields
        'seoTitle': seoData['title'],
        'seoDescription': seoData['description'],
        'seoSlug': seoData['slug'],
        'seoKeywords': (seoData['keywords'] as List<dynamic>).join(','),
        'canonicalUrl': seoData['canonicalUrl'],
        'ogImageUrl': imageUrl,
        'jsonLdSchema': jsonEncode(seoData['jsonLd']),
        
        // AI Parameters
        'aiModel': 'Local Rule-Based Generator',
        'aiPrompt': 'Autonomous generation for "$currentTopic".',
        'aiConfidence': 0.98,
        'aiGenerated': true,
        'status': publishImmediately ? 'published' : 'draft',
        
        // Relations
        'clusterId': clusterId,
        'publishedAt': now,
      };

      logMessage(context, '[publishing_platform] Article generated successfully!');
      logMessage(context, '-> Title: ${generatedArticle['title']}');
      logMessage(context, '-> Slug: ${seoData['slug']}');
      logMessage(context, '-> Category: ${generatedArticle['category']}');
      logMessage(context, '-> Summary: ${generatedArticle['summary']}');
      logMessage(context, '-> Keywords: ${seoData['keywords']}');

      if (dryRun) {
        logMessage(context, '[publishing_platform] [DRY RUN] Skipping database save.');
        publishedArticles.add(articleDocument);
        continue;
      }

      logMessage(context, '[publishing_platform] Saving article to database...');
      final doc = await databases.createDocument(
        databaseId: databaseId,
        collectionId: env['NEWS_COLLECTION_ID'] ?? 'news',
        documentId: articleId,
        data: articleDocument,
      );

      // --- Phase 8: Internal Linking Engine ---
      logMessage(context, '[Phase 8] Building internal links graph...');
      try {
        await buildInternalLinks(context, databases, databaseId, env['NEWS_COLLECTION_ID'] ?? 'news', doc.$id, clusterId);
      } catch (e) {
        logMessage(context, 'Internal linking warning: $e');
      }

      logMessage(context, '[publishing_platform] Done! Saved with ID: ${doc.$id}');
      publishedArticles.add(articleDocument);
    }

    return res.json({
      'status': dryRun ? 'dry_run_ok' : 'ok',
      'publishedCount': publishedArticles.length,
      'articles': publishedArticles.map((a) => {
        'title': a['title'],
        'slug': a['seoSlug'],
        'newsId': a['newsId'],
      }).toList(),
    }, 200);

  } catch (e, st) {
    logMessage(context, 'Critical error in publishing platform execution: $e');
    logMessage(context, st.toString());
    return res.json({
      'error': 'Execution failed',
      'detail': e.toString(),
    }, 500);
  }
}
