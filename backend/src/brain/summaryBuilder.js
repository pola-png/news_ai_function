import { logger } from '../core/logger.js';

export const summaryBuilder = {
  buildMetaSummary: (bodyText) => {
    logger.info('Building article meta description summary...');
    const sentences = bodyText.split(/[.!?]+/).map(s => s.trim()).filter(s => s.length > 0);
    return sentences.slice(0, 2).join('. ') + '.';
  }
};
