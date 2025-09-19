const express = require('express');
const axios = require('axios');

const app = express();
app.use(express.json());

// Round Robin simple
let salesCounter = 0;
let accountingCounter = 0;

const salesServers = ['http://localhost:3001', 'http://localhost:3011'];


const accountingServers = ['http://localhost:3002', 'http://localhost:3012'];

// Helper para round robin
function getNextServer(servers, counter) {
  const server = servers[counter % servers.length];
  return server;
}

// Proxy para /api/tickets
app.get('/api/tickets', async (req, res) => {
  try {
    const server = getNextServer(salesServers, salesCounter++);
    console.log(`📍 Forwarding GET /api/tickets to ${server}`);
    const response = await axios.get(`${server}/api/tickets`);
    res.json(response.data);
  } catch (error) {
    console.error('❌ Error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Proxy para /api/orders (GET)
app.get('/api/orders', async (req, res) => {
  try {
    const server = getNextServer(salesServers, salesCounter++);
    console.log(`📍 Forwarding GET /api/orders to ${server}`);
    const response = await axios.get(`${server}/api/orders`);
    res.json(response.data);
  } catch (error) {
    console.error('❌ Error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Proxy para /api/orders (POST)
app.post('/api/orders', async (req, res) => {
  try {
    const server = getNextServer(salesServers, salesCounter++);
    console.log(`📍 Forwarding POST /api/orders to ${server}`);
    const response = await axios.post(`${server}/api/orders`, req.body);
    res.status(response.status).json(response.data);
  } catch (error) {
    console.error('❌ Error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Proxy para /api/report
app.get('/api/report', async (req, res) => {
  try {
    const server = getNextServer(accountingServers, accountingCounter++);
    console.log(`📍 Forwarding GET /api/report to ${server}`);
    const response = await axios.get(`${server}/api/report`);
    res.json(response.data);
  } catch (error) {
    console.error('❌ Error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Proxy para /api/transactions (GET)
app.get('/api/transactions', async (req, res) => {
  try {
    const server = getNextServer(accountingServers, accountingCounter++);
    console.log(`📍 Forwarding GET /api/transactions to ${server}`);
    const response = await axios.get(`${server}/api/transactions`);
    res.json(response.data);
  } catch (error) {
    console.error('❌ Error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Proxy para /api/transactions (POST)
app.post('/api/transactions', async (req, res) => {
  try {
    const server = getNextServer(accountingServers, accountingCounter++);
    console.log(`📍 Forwarding POST /api/transactions to ${server}`);
    const response = await axios.post(`${server}/api/transactions`, req.body);
    res.status(response.status).json(response.data);
  } catch (error) {
    console.error('❌ Error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'gateway',
    loadBalancing: 'round-robin',
    timestamp: new Date().toISOString()
  });
});

const PORT = 8080;
app.listen(PORT, () => {
  console.log(`🚪 Gateway running on http://localhost:${PORT}`);
  console.log(`📊 Load balancing:`);
  console.log(`   Sales: ${salesServers.join(', ')}`);
  console.log(`   Accounting: ${accountingServers.join(', ')}`);
  console.log(`\nReady to accept requests!`);
});