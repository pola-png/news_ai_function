import { logger } from '../core/logger.js';
import { database } from '../core/database.js';
import { sitemap } from './sitemap.js';
import { rss } from './rss.js';
import { notification } from './notification.js';

export const publisher = {
  publish: async (article) => {
    logger.info(`Publishing article: "${article.title}"`);
    
    // Save to Database
    await database.query(
      'INSERT INTO articles (title, content, slug, category, published_at) VALUES ($1, $2, $3, $4, $5)',
      [article.title, article.body, article.slug, article.category, new Date()]
    );
    
    // Update sitemap & RSS feeds
    await sitemap.update(article.slug);
    await rss.updateFeed(article);
    
    // Send notifications to subscribers
    await notification.sendPush(article.title, article.summary);
    
    logger.info('Article published successfully.');
    return true;
  }
};
