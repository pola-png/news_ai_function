import { logger } from '../core/logger.js';

export const scoringEngine = {
  calculateScore: (trend, difficulty, virality) => {
    logger.info(`Scoring keywords: trend=${trend}, diff=${difficulty}, virality=${virality}`);
    return (trend * 0.4) + ((100 - difficulty) * 0.3) + (virality * 0.3);
  }
};
