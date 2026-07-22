import app from './app.js';
import { config } from './config.js';
import { logger } from './logger.js';
import { scheduler } from './scheduler.js';
import { database } from './database.js';
// Initialize BullMQ Workers on boot
import '../workers/bullWorkers.js';

const startServer = async () => {
  try {
    // 1. Database Connection
    await database.connect();

    // 2. Start Cron Scheduler
    scheduler.start();

    // 3. Start Listening on Port
    app.listen(config.port, () => {
      logger.info(`Autonomous Publishing Platform Backend is running on port ${config.port}`);
    });
  } catch (error) {
    logger.error('Critical failure on server startup:', error);
    process.exit(1);
  }
};

startServer();
