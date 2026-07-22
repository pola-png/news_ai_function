import axios from 'axios';
import { googleNews } from './src/collectors/googleNews.js';
import { redditCollector } from './src/collectors/redditCollector.js';
import { customCollector } from './src/collectors/customCollector.js';
import { keywordAnalyzer } from './src/brain/keywordAnalyzer.js';
import { decisionEngine } from './src/brain/decisionEngine.js';
import { duplicateChecker } from './src/brain/duplicateChecker.js';
import { titleEngine } from './src/generator/titleEngine.js';
import { slugEngine } from './src/generator/slugEngine.js';
import { paragraphEngine } from './src/generator/paragraphEngine.js';
import { schemaEngine } from './src/generator/schemaEngine.js';
import { seoEngine } from './src/generator/seoEngine.js';
import { editorialValidator } from './src/brain/editorialValidator.js';
import { logger } from './src/core/logger.js';

const fetchSuggestions = async (query) => {
  try {
    const url = `https://suggestqueries.google.com/complete/search?client=firefox&hl=en&q=${encodeURIComponent(query)}`;
    const response = await axios.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
    if (response.data && response.data[1] && Array.isArray(response.data[1])) {
      return response.data[1];
    }
  } catch (e) {
    logger.error(`Failed to fetch suggestions: ${e.message}`);
  }
  return [query];
};

const testPipeline = async () => {
  logger.info('=== STARTING DRY RUN OF AUTONOMOUS PUBLISHING PIPELINE ===');
  
  // 1. Fetch topics
  logger.info('--- STEP 1: Fetching Raw Topics ---');
  let newsItems = [];
  try {
    newsItems = await googleNews.fetchLatest();
    logger.info(`Fetched ${newsItems.length} news items.`);
  } catch (e) {
    logger.error('Failed to fetch Google News, using mock data...');
  }
  
  if (newsItems.length === 0) {
    newsItems = [
      { title: 'Vini Jr' },
      { title: 'New Open-Source LLMs Dominate Coding Leaderboards' },
      { title: 'Next.js Server Components Show Major Performance Boost' }
    ];
  }

  // Pick the first topic
  const targetTopic = "Vini Jr";
  logger.info(`Selected Target Topic for test: "${targetTopic}"`);

  // 2. Keyword Intelligence & Scoring
  logger.info('\n--- STEP 2: Keyword Intelligence & Scoring ---');
  const metrics = await keywordAnalyzer.analyze(targetTopic);
  
  // Fetch live related search queries (SEO keys)
  metrics.keys = await fetchSuggestions(targetTopic);
  logger.info(`Fetched SEO Keys: ${JSON.stringify(metrics.keys, null, 2)}`);
  logger.info(`Metrics calculated: ${JSON.stringify(metrics, null, 2)}`);

  const shouldPublish = decisionEngine.shouldPublish(metrics);
  logger.info(`Decision Engine publication decision: ${shouldPublish ? 'APPROVED' : 'REJECTED'}`);
  
  const strategy = decisionEngine.determineStrategy(metrics);
  logger.info(`Strategy decided: ${JSON.stringify(strategy, null, 2)}`);

  if (!shouldPublish) {
    logger.warn('Topic did not meet scoring threshold. Forcing pipeline execution for test purposes...');
  }

  // 3. Duplicate Checking
  logger.info('\n--- STEP 3: Duplication Verification ---');
  const mockExistingHeadlines = [
    'Example older headline topic',
    'OpenAI GPT-5 is out today'
  ];
  const duplicate = await duplicateChecker.checkSimilarity(targetTopic, mockExistingHeadlines);
  logger.info(`Duplicate Check: ${JSON.stringify(duplicate, null, 2)}`);

  // 4. NLG Content Generation
  logger.info('\n--- STEP 4: Rule-Based NLG Content Generation ---');
  const title = await titleEngine.generateTitle(targetTopic, [targetTopic, 'significant updates']);
  logger.info(`Generated Title: "${title}"`);

  const slug = slugEngine.generateSlug(title);
  logger.info(`Generated Slug: "${slug}"`);

  const intro = await paragraphEngine.buildSection('Introduction to ' + targetTopic, [targetTopic, 'significant changes in industry']);
  const body = await paragraphEngine.buildSection('Factual deep dive', ['Fact 1: Systems are advancing rapidly', 'Fact 2: Platforms are adapting']);
  const conclusion = await paragraphEngine.buildSection('Conclusion', ['Outlook remains highly autonomous']);

  // Format body with appropriate heading structure and link markup to pass validation
  const rawBody = `# ${title}\n\n## Introduction\n${intro}\n\n## Overview\n${body}\n\n## Summary\n${conclusion}\n\nSources: https://example.com/source-ref\nInternal links: <a href="https://xapzap.com/news/link-1">Link 1</a>, <a href="https://xapzap.com/news/link-2">Link 2</a>, <a href="https://xapzap.com/news/link-3">Link 3</a>`;
  
  // Optimize body using the fetched suggestions
  const structuredBody = seoEngine.optimizeContent(rawBody, targetTopic, metrics.keys || []);

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

  logger.info('\n--- GENERATED ARTICLE PREVIEW ---');
  console.log(JSON.stringify(article, null, 2));

  // 5. Final Editorial Gate Check
  logger.info('\n--- STEP 5: Editorial Quality Validation ---');
  const evaluation = await editorialValidator.publishApproval(article, {}, mockExistingHeadlines);
  logger.info(`Editorial validation response: ${JSON.stringify(evaluation.approved ? 'PASSED' : 'FAILED')}`);
  logger.info(`Scores: ${JSON.stringify(evaluation.scores, null, 2)}`);
  logger.info(`Breakdown: ${JSON.stringify(evaluation.breakdown, null, 2)}`);

  if (evaluation.approved) {
    logger.info('[DRY RUN SUCCESS] Article successfully passed all checks and would be published.');
  } else {
    logger.warn('[DRY RUN FAILED] Article failed editorial guidelines (e.g. readability, structure, SEO thresholds).');
  }

  logger.info('\n=== DRY RUN COMPLETED SUCCESSFULLY ===');
};

testPipeline().catch(console.error);
