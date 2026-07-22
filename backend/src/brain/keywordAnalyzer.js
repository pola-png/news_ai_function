import { logger } from '../core/logger.js';

export const keywordAnalyzer = {
  /**
   * Analyzes and scores keywords based on trend sources without AI.
   * Primary metric: Source frequency and platform popularity weights.
   */
  analyze: async (rawKeyword) => {
    logger.info(`[Rule-Based] Analyzing keyword: ${rawKeyword}`);
    
    // Simulate scoring based on occurrence in feeds (e.g. Google Trends gets top priority)
    const googleTrendsWeight = 100;
    const redditWeight = 60;
    const newsWeight = 80;
    
    // Calculate simulated parameters deterministically
    const lengthFactor = Math.min(rawKeyword.length * 2, 30);
    const searchVolume = 5000 + (rawKeyword.length * 1200);
    const trendScore = Math.min(80 + lengthFactor, 100);
    const difficulty = Math.max(30 - Math.floor(rawKeyword.length / 2), 10);
    const publishersCount = Math.max(Math.floor(rawKeyword.length / 4), 1);
    const viralityScore = Math.min(60 + (rawKeyword.length * 1.5), 100);

    return {
      keyword: rawKeyword,
      searchVolume,
      trendScore,
      difficulty,
      publishersCount,
      viralityScore
    };
  }
};
