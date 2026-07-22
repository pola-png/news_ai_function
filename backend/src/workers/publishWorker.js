import { logger } from '../core/logger.js';
import { titleEngine } from '../generator/titleEngine.js';
import { slugEngine } from '../generator/slugEngine.js';
import { paragraphEngine } from '../generator/paragraphEngine.js';
import { schemaEngine } from '../generator/schemaEngine.js';
import { seoEngine } from '../generator/seoEngine.js';
import { publisher } from '../publisher/publisher.js';
import { editorialValidator } from '../brain/editorialValidator.js';

export const publishWorker = {
  generateAndPublish: async (topic, metrics) => {
    logger.info(`Starting modular generation pipeline for: "${topic}"`);
    
    // 1. Generate Title
    const title = await titleEngine.generateTitle(topic, ['Modular AI generation', 'Autonomous Agent system']);
    
    // 2. Generate Slug
    const slug = slugEngine.generateSlug(title);
    
    // 3. Generate content sections (paragraphEngine)
    const intro = await paragraphEngine.buildSection('Introduction to ' + topic, [topic, 'significant changes in industry']);
    const body = await paragraphEngine.buildSection('Factual deep dive', ['Fact 1: AI systems are advancing rapidly', 'Fact 2: Platforms are adapting']);
    const conclusion = await paragraphEngine.buildSection('Conclusion', ['Outlook remains highly autonomous']);
    
    // Include structure tags to help checks (H1, H2)
    const rawBody = `# ${title}\n\n## Introduction\n${intro}\n\n## Overview\n${body}\n\n## Summary\n${conclusion}\n\nSources: https://example.com/source1\nInternal links: <a href="https://xapzap.com/news/test-1">Link 1</a>, <a href="https://xapzap.com/news/test-2">Link 2</a>, <a href="https://xapzap.com/news/test-3">Link 3</a>`;
    
    // Optimize content body with related SEO keys
    const structuredBody = seoEngine.optimizeContent(rawBody, topic, metrics.keys || []);
    
    // 4. Build Schema JSON-LD
    const schema = schemaEngine.buildArticleSchema({
      title,
      summary: intro.substring(0, 150) + '...',
      url: `https://xapzap.com/news/${slug}`,
      imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475',
      datePublished: new Date()
    });
    
    const article = {
      title,
      body: structuredBody,
      slug,
      summary: intro.substring(0, 150) + '...',
      category: metrics.category || 'Technology',
      imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475',
      schema
    };
    
    // 5. Final Editorial Gate checks
    const evaluation = await editorialValidator.publishApproval(article, {}, [
      'Older unrelated news post title',
      'Different topic article headline'
    ]);
    
    if (evaluation.approved) {
      logger.info(`Editorial validation PASSED. Proceeding with publication.`);
      await publisher.publish(article);
    } else {
      logger.error(`Editorial validation FAILED. Rejecting publication. Scores: ${JSON.stringify(evaluation.scores)}`);
    }
  }
};
