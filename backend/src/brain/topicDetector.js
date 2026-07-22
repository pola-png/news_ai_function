import { logger } from '../core/logger.js';

export const topicDetector = {
  detectTopic: (keywordsList) => {
    logger.info('Running topic classification...');
    return keywordsList.length > 0 ? keywordsList[0] : 'General Development';
  }
};
