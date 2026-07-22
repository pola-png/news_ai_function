import { logger } from '../core/logger.js';

export const decisionEngine = {
  shouldPublish: (metrics) => {
    if (!metrics) return false;
    
    const score = (metrics.trendScore * 0.4) + ((100 - metrics.difficulty) * 0.3) + (metrics.viralityScore * 0.3);
    logger.info(`Decision Engine Score for "${metrics.keyword || ''}": ${score}`);
    
    // Publish if score is 60 or above
    return score >= 60;
  },
  determineStrategy: (metrics) => {
    return {
      priority: metrics.trendScore > 80 ? 'high' : 'normal',
      template: 'breaking_news', // breaking_news, tutorial, buyer_guide, listicle, etc.
      seoStrategy: 'long-tail-enrichment',
      publishingTime: new Date()
    };
  }
};
