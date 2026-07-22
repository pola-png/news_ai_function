import 'package:dart_appwrite/dart_appwrite.dart';
import 'utils.dart';

// Phase 8: Internal Linking Builder
Future<void> buildInternalLinks(
  dynamic context,
  Databases databases,
  String databaseId,
  String collectionId,
  String currentArticleId,
  String? clusterId,
) async {
  if (clusterId == null) return;
  
  try {
    final response = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [
        Query.equal('clusterId', clusterId),
        Query.notEqual('newsId', currentArticleId),
        Query.limit(3),
      ],
    );

    for (final doc in response.documents) {
      final targetId = doc.data['newsId'] as String?;
      if (targetId != null) {
        logMessage(context, '[Phase 8] Found related cluster article: $targetId. Linking $currentArticleId -> $targetId');
        
        await databases.createDocument(
          databaseId: databaseId,
          collectionId: 'internal_links',
          documentId: ID.unique(),
          data: {
            'sourceArticleId': currentArticleId,
            'targetArticleId': targetId,
            'anchorText': doc.data['topic'] ?? 'related article',
            'linkType': 'contextual',
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }
    }
  } catch (e) {
    logMessage(context, 'Internal Link builder skipped (collections may not be configured): $e');
  }
}
