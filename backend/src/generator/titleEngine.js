import { logger } from '../core/logger.js';

export const titleEngine = {
  /**
   * Generates a high-CTR news headline using template combinations.
   */
  generateTitle: async (topic, facts = []) => {
    logger.info(`[Rule-Based] Synthesizing title for: ${topic}`);

    const templates = [
      `Breaking: How ${topic} is Reshaping the Industry`,
      `The Future of ${topic}: What You Need to Know`,
      `Why ${topic} Matters Right Now: Key Facts and Analysis`,
      `New Updates: The Rise of ${topic} and Market Impact`
    ];

    // Pick a template based on topic length to make it deterministic but variable
    const index = topic.length % templates.length;
    return templates[index];
  }
};
