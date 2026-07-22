import { logger } from './logger.js';

export const database = {
  connect: async () => {
    logger.info('Connected to database successfully.');
    return true;
  },
  query: async (sql, params = []) => {
    logger.info(`Executing query: ${sql.substring(0, 100)}...`);
    return { rows: [] };
  }
};
