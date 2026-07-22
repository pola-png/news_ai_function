import { logger } from '../core/logger.js';

export const eventDetector = {
  detectEvents: (timelineData) => {
    logger.info('Detecting key events for sitemap or timeline view...');
    return timelineData || [];
  }
};
