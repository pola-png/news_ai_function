import { logger } from '../core/logger.js';

export const rss = {
  updateFeed: async (article) => {
    logger.info(`Adding article "${article.title}" to public RSS feed XML...`);
    return true;
  }
};
