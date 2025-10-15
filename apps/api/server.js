// API Server - Environment variables are injected by `dual run`
// No need to load .env files manually - dual handles the entire env cascade:
//   1. Base environment (.env.base)
//   2. Service-specific environment (apps/api/.env)
//   3. Context-specific overrides (.dual/.local/service/api/.env)

const express = require('express');
const app = express();

console.log('=== API Service Starting ===\n');

const PORT = process.env.PORT || 3001;

app.get('/', (req, res) => {
  res.json({
    service: 'api',
    port: PORT,
    environment: {
      DATABASE_URL: process.env.DATABASE_URL,
      REDIS_URL: process.env.REDIS_URL,
      DEBUG: process.env.DEBUG,
      LOG_LEVEL: process.env.LOG_LEVEL,
      API_KEY: process.env.API_KEY,
      NODE_ENV: process.env.NODE_ENV
    }
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'api', port: PORT });
});

app.listen(PORT, () => {
  console.log('=== Environment Variables ===');
  console.log('PORT:', PORT);
  console.log('DATABASE_URL:', process.env.DATABASE_URL);
  console.log('REDIS_URL:', process.env.REDIS_URL);
  console.log('DEBUG:', process.env.DEBUG);
  console.log('LOG_LEVEL:', process.env.LOG_LEVEL);
  console.log('API_KEY:', process.env.API_KEY);
  console.log('NODE_ENV:', process.env.NODE_ENV);
  console.log('\n✓ API service listening on port', PORT);
  console.log(`Visit http://localhost:${PORT}/ to see environment info\n`);
});
