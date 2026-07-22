import { logger } from '../core/logger.js';

export const notification = {
  sendPush: async (title, body) => {
    logger.info(`Sending push notifications: "${title}" - "${body}"`);
    return true;
  }
};
