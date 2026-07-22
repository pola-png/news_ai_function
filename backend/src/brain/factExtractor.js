import { logger } from '../core/logger.js';

export const factExtractor = {
  /**
   * Rule-based extraction of numbers, currency rates, dates, and statements.
   */
  extractFactsAndStats: async (topicContent) => {
    logger.info('[Rule-Based] Extracting facts and statistics from context...');

    // Regex patterns
    const amountRegex = /(₦|\$|€|£)\d{1,3}(,\d{3})*(\.\d{2})?/g;
    const dateRegex = /\b\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\b/gi;
    const percentRegex = /\b\d+(\.\d+)?%/g;

    const amounts = topicContent.match(amountRegex) || [];
    const dates = topicContent.match(dateRegex) || [];
    const percentages = topicContent.match(percentRegex) || [];

    const statistics = [];
    if (amounts.length > 0) {
      statistics.push({ metric: 'Economic Value/Amount', value: amounts[0] });
    }
    if (percentages.length > 0) {
      statistics.push({ metric: 'Growth/Market Share', value: percentages[0] });
    }

    const facts = [];
    if (dates.length > 0) {
      facts.push(`Key event verified on ${dates[0]}.`);
    } else {
      facts.push(`Factual activity recorded for ${topicContent}.`);
    }

    return {
      facts,
      statistics,
      primaryDate: dates.length > 0 ? dates[0] : new Date().toDateString()
    };
  }
};
