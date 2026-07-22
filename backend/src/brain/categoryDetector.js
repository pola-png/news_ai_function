import { logger } from '../core/logger.js';

export const categoryDetector = {
  detect: (title, content = '') => {
    logger.info(`Detecting category for: ${title}`);
    const normalized = `${title} ${content}`.toLowerCase();
    
    if (normalized.includes('ai') || normalized.includes('programming') || normalized.includes('code') || normalized.includes('software')) {
      return 'Technology';
    }
    if (normalized.includes('football') || normalized.includes('premier league') || normalized.includes('chelsea')) {
      return 'Sports';
    }
    if (normalized.includes('stock') || normalized.includes('finance') || normalized.includes('cpc') || normalized.includes('market')) {
      return 'Finance';
    }
    
    return 'General';
  }
};
