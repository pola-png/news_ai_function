import { Worker } from 'bullmq';
import IORedis from 'ioredis';
import { logger } from '../core/logger.js';
import { keywordAnalyzer } from '../brain/keywordAnalyzer.js';
import { decisionEngine } from '../brain/decisionEngine.js';
import { duplicateChecker } from '../brain/duplicateChecker.js';
import { publishWorker } from './publishWorker.js';
import { generationQueue } from '../core/queue.js';

const redisConnection = new IORedis(process.env.REDIS_URL || 'redis://127.0.0.1:6379', {
  maxRetriesPerRequest: null
});

// Helper: Check if date is older than 24 hours
const isOlderThan24Hours = (timestamp) => {
  if (!timestamp) return true;
  const itemDate = new Date(timestamp);
  const diffInMs = new Date() - itemDate;
  const diffInHours = diffInMs / (1000 * 60 * 60);
  return diffInHours > 24;
};

// 1. Keyword Worker: Analyzes in parallel, filtering out items older than 24h
export const keywordWorker = new Worker('keyword-queue', async (job) => {
  const { keyword, keys, timestamp } = job.data;
  
  logger.info(`[BullMQ] Keyword Worker processing job ${job.id}: "${keyword}"`);

  // MANDATORY CONSTRAINT: Daily keywords only (not older than 24 hours)
  if (isOlderThan24Hours(timestamp)) {
    logger.warn(`[BullMQ] Skipping keyword "${keyword}" - item is older than 24 hours.`);
    return { status: 'skipped', reason: 'older_than_24h' };
  }

  // Analyze & score keyword
  const metrics = await keywordAnalyzer.analyze(keyword);
  if (!metrics) {
    throw new Error(`Failed to analyze keyword: ${keyword}`);
  }
  
  metrics.keyword = keyword;
  metrics.keys = keys || [keyword];
  const eligible = decisionEngine.shouldPublish(metrics);
  if (!eligible) {
    logger.info(`[BullMQ] Keyword "${keyword}" rejected due to low score.`);
    return { status: 'rejected', metrics };
  }

  // Duplicate checks against previous articles
  const duplicate = await duplicateChecker.checkSimilarity(keyword, [
    'Example older headline topic'
  ]);
  if (duplicate.isDuplicate) {
    logger.warn(`[BullMQ] Keyword "${keyword}" rejected as potential duplicate.`);
    return { status: 'duplicate', metrics };
  }

  // Push to Generation Queue for modular LLM generation
  logger.info(`[BullMQ] Ingesting "${keyword}" into approved generation queue.`);
  await generationQueue.add(`generate-${keyword}`, { keyword, metrics, timestamp });

  return { status: 'queued_for_generation', metrics };
}, {
  connection: redisConnection,
  concurrency: 10 // Handle 10 jobs concurrently per worker instance
});

// 2. Generation Worker: Generates and validates modular article draft in parallel
export const generationWorker = new Worker('generation-queue', async (job) => {
  const { keyword, metrics, timestamp } = job.data;
  
  logger.info(`[BullMQ] Generation Worker processing job ${job.id}: "${keyword}"`);

  // Extra sanity check before invoking costly LLM API
  if (isOlderThan24Hours(timestamp)) {
    logger.warn(`[BullMQ] Generation job skipped - item is older than 24 hours.`);
    return { status: 'skipped', reason: 'older_than_24h' };
  }

  // Execute publication workflow (draft, modular engines, schema generation, sitemap, publishing)
  await publishWorker.generateAndPublish(keyword, metrics);

  return { status: 'published' };
}, {
  connection: redisConnection,
  concurrency: 5
});

logger.info('BullMQ workers initialized and listening for jobs.');
export const workers = { keywordWorker, generationWorker };
