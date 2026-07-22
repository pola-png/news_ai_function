import { googleTrends } from './src/collectors/googleTrends.js';
import { googleNews } from './src/collectors/googleNews.js';
import { redditCollector } from './src/collectors/redditCollector.js';
import { customCollector } from './src/collectors/customCollector.js';

const testRun = async () => {
  console.log('--- Testing Live Keyword & Topic Fetching ---');
  
  console.log('\n1. Google Trends Keywords:');
  const trends = await googleTrends.fetchTrendingKeywords();
  console.log(JSON.stringify(trends, null, 2));
  
  console.log('\n2. Google News RSS Headlines:');
  const news = await googleNews.fetchLatest();
  console.log(news.slice(0, 3)); // show first 3 headlines
  
  console.log('\n3. Reddit Technology Trends:');
  const reddit = await redditCollector.fetchTrending('technology');
  console.log(reddit.slice(0, 3)); // show first 3 posts
  
  console.log('\n4. Custom Publisher RSS Feeds (e.g. Hacker News):');
  const custom = await customCollector.fetchCustomSources();
  console.log(custom.slice(0, 3)); // show first 3 posts
};

testRun().catch(console.error);
