import { rssCollector } from './rssCollector.js';
import { logger } from '../core/logger.js';

export const googleNews = {
  fetchLatest: async () => {
    logger.info('Fetching latest trends from Google News RSS...');
    const googleNewsRssUrl = 'https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en';
    return await rssCollector.fetch(googleNewsRssUrl);
  }
};
