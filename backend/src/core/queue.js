import { Queue } from 'bullmq';
import IORedis from 'ioredis';
import { logger } from './logger.js';

const redisConnection = new IORedis(process.env.REDIS_URL || 'redis://127.0.0.1:6379', {
  maxRetriesPerRequest: null
});

redisConnection.on('connect', () => logger.info('IORedis connected to Redis server.'));
redisConnection.on('error', (err) => logger.error('Redis connection error:', err));

// Queue 1: Bulk Keyword Ingestion Queue
export const keywordQueue = new Queue('keyword-queue', {
  connection: redisConnection
});

// Queue 2: Approved Article Generation Queue
export const generationQueue = new Queue('generation-queue', {
  connection: redisConnection
});

export const queues = {
  keywordQueue,
  generationQueue,
  connection: redisConnection
};
