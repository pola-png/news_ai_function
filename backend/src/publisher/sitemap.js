import { logger } from '../core/logger.js';

export const sitemap = {
  update: async (slug) => {
    logger.info(`Adding new path /news/${slug} to sitemap.xml...`);
    return true;
  }
};
