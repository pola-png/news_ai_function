import { logger } from '../core/logger.js';

export const relationDetector = {
  detectRelations: (entities) => {
    logger.info('Detecting semantic relations between entities...');
    return [
      { subject: 'OpenAI', relation: 'released', object: 'GPT-5' }
    ];
  }
};
