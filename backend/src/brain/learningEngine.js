import { logger } from '../core/logger.js';

export const learningEngine = {
  analyzePerformance: async (analyticsData) => {
    logger.info('Analyzing article performance & metrics for learning loop...');
    const improvements = [];
    
    for (const stat of analyticsData) {
      if (stat.ctr < 0.02) {
        improvements.push({
          articleId: stat.articleId,
          type: 'LOW_CTR',
          recommendation: 'Rewrite title with higher emotional resonance or curiosity gap.'
        });
      }
      if (stat.bounceRate > 0.8) {
        improvements.push({
          articleId: stat.articleId,
          type: 'HIGH_BOUNCE',
          recommendation: 'Rewrite introduction, make paragraphs shorter and add a compelling hook.'
        });
      }
    }
    
    return improvements;
  }
};
