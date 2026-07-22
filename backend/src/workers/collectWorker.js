import { logger } from '../core/logger.js';
import { googleTrends } from '../collectors/googleTrends.js';
import { googleNews } from '../collectors/googleNews.js';
import { redditCollector } from '../collectors/redditCollector.js';
import { keywordQueue } from '../core/queue.js';

export const collectWorker = {
  run: async () => {
    logger.info('Collect Worker running bulk keyword intelligence collection...');
    
    const trends = await googleTrends.fetchTrendingKeywords();
    const news = await googleNews.fetchLatest();
    const reddit = await redditCollector.fetchTrending('technology');
    
    // Ingest into array with discovery timestamp
    const rawItems = [
      ...trends.map(t => ({ keyword: t.title, keys: t.keys || [t.title], timestamp: new Date().toISOString() })),
      ...news.map(n => ({ keyword: n.title, keys: [n.title], timestamp: n.pubDate || new Date().toISOString() })),
      ...reddit.map(r => ({ keyword: r.title, keys: [r.title], timestamp: new Date().toISOString() }))
    ];
    
    logger.info(`Found ${rawItems.length} raw keywords. Filtering and pushing to BullMQ...`);
    
    let enqueuedCount = 0;
    for (const item of rawItems) {
      if (item.keyword && item.keyword.length > 5) {
        // Enqueue to Redis for concurrent processing
        await keywordQueue.add(`keyword-${item.keyword}`, {
          keyword: item.keyword,
          keys: item.keys,
          timestamp: item.timestamp
        });
        enqueuedCount++;
      }
    }
    
    logger.info(`Enqueued ${enqueuedCount} keywords to BullMQ.`);
  }
};
