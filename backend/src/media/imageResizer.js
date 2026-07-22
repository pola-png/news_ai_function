import { logger } from '../core/logger.js';

export const imageResizer = {
  resize: async (imageBuffer, width, height) => {
    logger.info(`Resizing media asset to dimensions: ${width}x${height}`);
    return imageBuffer;
  }
};
