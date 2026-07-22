import cron from 'node-cron';
import { logger } from './logger.js';
import { collectWorker } from '../workers/collectWorker.js';

export const scheduler = {
  start: () => {
    logger.info('Scheduler started.');
    
    // Scheduled job every 20 minutes (matches Phase 1 requirements)
    cron.schedule('*/20 * * * *', async () => {
      logger.info('Scheduled task triggered: trend & keyword intelligence collection.');
      try {
        await collectWorker.run();
      } catch (error) {
        logger.error('Error running collectWorker inside scheduler:', error);
      }
    });
  }
};
