import Parser from 'rss-parser';
import { logger } from '../core/logger.js';

const parser = new Parser();

export const rssCollector = {
  fetch: async (feedUrl) => {
    logger.info(`Fetching RSS feed: ${feedUrl}`);
    try {
      const feed = await parser.parseURL(feedUrl);
      return feed.items.map(item => ({
        title: item.title,
        link: item.link,
        pubDate: item.pubDate,
        categories: item.categories || [],
        source: feedUrl
      }));
    } catch (e) {
      logger.error(`Failed to parse RSS feed from ${feedUrl}:`, e);
      return [];
    }
  }
};
