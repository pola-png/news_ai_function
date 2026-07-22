import { exec } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import { logger } from '../core/logger.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const googleTrends = {
  fetchTrendingKeywords: async () => {
    logger.info('Fetching Google Trends using Python pytrends helper...');
    
    return new Promise((resolve) => {
      const scriptPath = path.join(__dirname, 'pytrends_fetcher.py');
      
      exec(`python "${scriptPath}"`, (error, stdout, stderr) => {
        if (error) {
          logger.error(`Failed to execute pytrends script: ${error.message}`);
          return resolve([]);
        }
        
        try {
          const parsed = JSON.parse(stdout);
          if (parsed && parsed.length > 0) {
            logger.info(`Successfully fetched ${parsed.length} daily trends from pytrends.`);
            return resolve(parsed);
          }
        } catch (e) {
          logger.error('Failed to parse pytrends JSON output:', e);
        }
        
        resolve([]);
      });
    });
  }
};
