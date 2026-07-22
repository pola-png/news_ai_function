import { logger } from '../core/logger.js';
import { imageResizer } from './imageResizer.js';

export const thumbnailGenerator = {
  generate: async (imageBuffer) => {
    logger.info('Generating standard 150x150 preview thumbnail...');
    return await imageResizer.resize(imageBuffer, 150, 150);
  }
};
