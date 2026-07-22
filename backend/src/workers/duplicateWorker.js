import { logger } from '../core/logger.js';
import { duplicateChecker } from '../brain/duplicateChecker.js';
import { publishWorker } from './publishWorker.js';

export const duplicateWorker = {
  queueForPublication: async (topic, metrics) => {
    logger.info(`Running duplication checks for: "${topic}"`);
    
    // In a real system, query database for headlines published in last 24 hours
    const mockExistingHeadlines = [
      'OpenAI GPT-5 is out today',
      'How to setup Next.js server components'
    ];
    
    const duplicate = await duplicateChecker.checkSimilarity(topic, mockExistingHeadlines);
    if (!duplicate.isDuplicate) {
      await publishWorker.generateAndPublish(topic, metrics);
    } else {
      logger.warn(`Skipped duplicate content topic: "${topic}" (matched: "${duplicate.matchedWith}")`);
    }
  }
};
