import { logger } from '../core/logger.js';

export const duplicateChecker = {
  checkSimilarity: async (headline, existingHeadlines = []) => {
    logger.info(`Checking duplicate similarity for headline: "${headline}"`);
    // Basic Jaccard overlap similarity
    const setA = new Set(headline.toLowerCase().split(/\s+/));
    
    for (const ext of existingHeadlines) {
      const setB = new Set(ext.toLowerCase().split(/\s+/));
      const intersection = new Set([...setA].filter(x => setB.has(x)));
      const union = new Set([...setA, ...setB]);
      const similarity = intersection.size / union.size;
      
      if (similarity > 0.6) {
        logger.warn(`Potential duplicate detected: "${ext}" with score ${similarity}`);
        return { isDuplicate: true, similarityScore: similarity, matchedWith: ext };
      }
    }
    
    return { isDuplicate: false, similarityScore: 0 };
  }
};
