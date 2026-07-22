import express from 'express';
import cors from 'cors';
import { logger } from './logger.js';
import { collectWorker } from '../workers/collectWorker.js';

const app = express();

app.use(cors());
app.use(express.json());

// API route to trigger autonomous publishing run manually
app.post('/api/run-publishing', async (req, res) => {
  logger.info('Manual trigger request received for publishing platform.');
  try {
    // Run collector in background to prevent request timeout
    collectWorker.run().catch(err => {
      logger.error('Background run failed:', err);
    });
    
    return res.status(202).json({
      status: 'accepted',
      message: 'Autonomous publishing collection run initiated in the background.'
    });
  } catch (error) {
    logger.error('Error initiating run:', error);
    return res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date() });
});

export default app;
