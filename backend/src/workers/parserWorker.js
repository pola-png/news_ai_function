import { logger } from '../core/logger.js';
import { keywordAnalyzer } from '../brain/keywordAnalyzer.js';
import { decisionEngine } from '../brain/decisionEngine.js';
import { duplicateWorker } from './duplicateWorker.js';

export const parserWorker = {
  processTopics: async (topics) => {
    logger.info('Parser Worker processing topics for keyword intelligence...');
    
    for (const topic of topics.slice(0, 3)) { // Limit concurrency during batch
      const metrics = await keywordAnalyzer.analyze(topic);
      if (metrics) {
        metrics.keyword = topic;
        const eligible = decisionEngine.shouldPublish(metrics);
        if (eligible) {
          logger.info(`Topic approved for publication: "${topic}"`);
          await duplicateWorker.queueForPublication(topic, metrics);
        } else {
          logger.info(`Topic rejected (low score): "${topic}"`);
        }
      }
    }
  }
};
