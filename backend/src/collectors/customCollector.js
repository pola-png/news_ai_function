import { logger } from '../core/logger.js';
import { rssCollector } from './rssCollector.js';

export const customCollector = {
  fetchCustomSources: async () => {
    logger.info('Fetching from custom publisher RSS list...');
    const customFeeds = [
      'https://news.ycombinator.com/rss'
    ];
    
    const results = [];
    for (const feed of customFeeds) {
      const items = await rssCollector.fetch(feed);
      results.push(...items);
    }
    return results;
  }
};
