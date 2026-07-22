import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: process.env.PORT || 3000,
  openaiApiKey: process.env.OPENAI_API_KEY || '',
  openaiModel: process.env.OPENAI_MODEL || 'gpt-4o',
  databaseUrl: process.env.DATABASE_URL || '',
  newsImageApiKey: process.env.NEWS_IMAGE_API_KEY || '',
  environment: process.env.NODE_ENV || 'development'
};
