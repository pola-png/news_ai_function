import { logger } from '../core/logger.js';
import { rssCollector } from './rssCollector.js';

export const redditCollector = {
  /**
   * Fetches trending technology posts using Reddit's RSS feed (more permissive than JSON API).
   */
  fetchTrending: async (subreddit = 'technology') => {
    logger.info(`Fetching trending RSS posts from r/${subreddit}...`);
    try {
      const feedUrl = `https://www.reddit.com/r/${subreddit}/.rss`;
      const items = await rssCollector.fetch(feedUrl);
      
      return items.map(item => ({
        title: item.title,
        link: item.link,
        source: `reddit:${subreddit}`
      }));
    } catch (e) {
      logger.error(`Failed to fetch reddit RSS: ${e.message}`);
      return [];
    }
  }
};
