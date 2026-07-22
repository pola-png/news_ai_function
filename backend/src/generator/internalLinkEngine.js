import { logger } from '../core/logger.js';

export const internalLinkEngine = {
  suggestLinks: (body, clusterArticles = []) => {
    logger.info('Running internal linking engine to establish topic clusters...');
    let updatedBody = body;
    
    for (const article of clusterArticles) {
      const keyword = article.topic || '';
      if (keyword.length > 3 && body.toLowerCase().includes(keyword.toLowerCase())) {
        logger.info(`Adding internal anchor link to: ${article.url}`);
        // Simple text replace with hyperlink (case insensitive)
        const regex = new RegExp(`\\b(${keyword})\\b`, 'i');
        updatedBody = updatedBody.replace(regex, `<a href="${article.url}">$1</a>`);
      }
    }
    
    return updatedBody;
  }
};
