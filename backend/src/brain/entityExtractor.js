import { logger } from '../core/logger.js';

export const entityExtractor = {
  /**
   * Rule-based Named Entity Recognition (NER) using keyword dictionaries.
   */
  extract: async (topicContent) => {
    logger.info('[Rule-Based] Extracting entities from topic content...');
    
    // Static dictionaries of common industry entities for matching
    const companiesDict = ['Google', 'OpenAI', 'Next.js', 'Apple', 'Reddit', 'Microsoft', 'Vercel', 'Meta', 'Tesla'];
    const peopleDict = ['Sam Altman', 'Elon Musk', 'Mark Zuckerberg', 'Sundar Pichai', 'Vitalik Buterin'];
    const locationsDict = ['Nigeria', 'Lagos', 'San Francisco', 'New York', 'London', 'California', 'Global'];
    
    const contentLower = topicContent.toLowerCase();
    
    const companies = companiesDict.filter(c => contentLower.includes(c.toLowerCase()));
    const people = peopleDict.filter(p => contentLower.includes(p.toLowerCase()));
    const locations = locationsDict.filter(l => contentLower.includes(l.toLowerCase()));

    // Fallback default entity extraction
    if (companies.length === 0 && topicContent.length > 3) {
      companies.push(topicContent.split(' ')[0]);
    }

    return {
      companies,
      people,
      locations
    };
  }
};
