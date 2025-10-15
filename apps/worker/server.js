const path = require('path');
const fs = require('fs');

// Load environment variables from multiple sources (cascade)
// Priority: service-specific .env > base .env
const serviceEnvPath = path.join(__dirname, '../../.dual/.local/service/worker/.env');
const baseEnvPath = path.join(__dirname, '../../.env.base');

console.log('=== Worker Service Starting ===\n');

// Track loaded env vars
const loadedVars = {
  service: [],
  base: []
};

// Load service-specific env (if exists)
if (fs.existsSync(serviceEnvPath)) {
  console.log('Loading service-specific env from:', serviceEnvPath);
  require('dotenv').config({ path: serviceEnvPath });
  // Parse to see what vars were loaded
  const content = fs.readFileSync(serviceEnvPath, 'utf8');
  loadedVars.service = content.split('\n')
    .filter(line => line && !line.startsWith('#') && line.includes('='))
    .map(line => line.split('=')[0]);
} else {
  console.log('No service-specific env file found at:', serviceEnvPath);
}

// Load base env
if (fs.existsSync(baseEnvPath)) {
  console.log('Loading base env from:', baseEnvPath);
  require('dotenv').config({ path: baseEnvPath });
  const content = fs.readFileSync(baseEnvPath, 'utf8');
  loadedVars.base = content.split('\n')
    .filter(line => line && !line.startsWith('#') && line.includes('='))
    .map(line => line.split('=')[0]);
} else {
  console.log('No base env file found at:', baseEnvPath);
}

const express = require('express');
const app = express();

const PORT = process.env.PORT || 3002;

app.get('/', (req, res) => {
  res.json({
    service: 'worker',
    port: PORT,
    environment: {
      DATABASE_URL: process.env.DATABASE_URL,
      REDIS_URL: process.env.REDIS_URL,
      DEBUG: process.env.DEBUG,
      LOG_LEVEL: process.env.LOG_LEVEL,
      API_KEY: process.env.API_KEY,
      NODE_ENV: process.env.NODE_ENV
    },
    loaded_from: {
      service_env: loadedVars.service,
      base_env: loadedVars.base
    }
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'worker', port: PORT });
});

app.listen(PORT, () => {
  console.log('\n=== Environment Variables ===');
  console.log('DATABASE_URL:', process.env.DATABASE_URL);
  console.log('REDIS_URL:', process.env.REDIS_URL);
  console.log('DEBUG:', process.env.DEBUG);
  console.log('LOG_LEVEL:', process.env.LOG_LEVEL);
  console.log('API_KEY:', process.env.API_KEY);
  console.log('NODE_ENV:', process.env.NODE_ENV);
  console.log('\n=== Loaded From ===');
  console.log('Service-specific:', loadedVars.service.join(', ') || 'none');
  console.log('Base env:', loadedVars.base.join(', ') || 'none');
  console.log(`\nWorker service listening on port ${PORT}`);
  console.log(`Visit http://localhost:${PORT}/ to see environment info\n`);
});
