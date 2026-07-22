import { logger } from '../core/logger.js';

export const paragraphEngine = {
  /**
   * Generates paragraph sections using fact mapping and Natural Language Generation (NLG) templates.
   */
  buildSection: async (sectionTitle, facts = [], language = 'en') => {
    logger.info(`[NLG] Building paragraph block for: ${sectionTitle}`);

    // Predefined lexical templates mapping common topics
    const templates = {
      'introduction': [
        'Recent market intelligence indicates a significant shift regarding {topic}. Industry leaders are actively tracking development events as performance requirements continue to evolve globally.',
        'Official updates regarding {topic} have sparked conversations across primary channels. Observers note this could impact standard operations and strategic alignments moving forward.'
      ],
      'deep_dive': [
        'A closer look at the verified details reveals key findings. Specially, {fact}. This highlights operational transitions and illustrates how sectors are organizing resources.',
        'Strategic reviews confirm that {fact}. Analysts emphasize that this trend points to an emerging pattern that will define operations in the coming quarters.'
      ],
      'conclusion': [
        'In conclusion, the trajectory of {topic} remains critical. Stakeholders should prepare for incremental adaptations as new findings emerge.',
        'Ultimately, these developments clarify the future of {topic}. Continuous monitoring of these milestones is recommended for accurate positioning.'
      ]
    };

    const topic = facts.length > 0 ? facts[0] : 'industry updates';
    const fact = facts.length > 1 ? facts[1] : 'advancements are developing smoothly';

    let content = '';

    const titleLower = sectionTitle.toLowerCase();
    if (titleLower.includes('intro')) {
      const option = templates.introduction[topic.length % templates.introduction.length];
      content = option.replace('{topic}', topic);
    } else if (titleLower.includes('deep') || titleLower.includes('fact')) {
      const option = templates.deep_dive[fact.length % templates.deep_dive.length];
      content = option.replace('{fact}', fact);
    } else {
      const option = templates.conclusion[topic.length % templates.conclusion.length];
      content = option.replace('{topic}', topic);
    }

    return content;
  }
};
