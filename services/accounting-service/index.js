const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3002;

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Mock data
let transactions = [];
let transactionIdCounter = 1;

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'accounting-service',
    port: PORT,
    timestamp: new Date().toISOString()
  });
});

// Get financial report
app.get('/api/report', (req, res) => {
  const total = transactions.reduce((sum, t) => sum + t.amount, 0);
  const taxes = total * 0.18; // 18% de impuestos
  
  res.json({
    totalSales: total,
    taxes: taxes,
    netIncome: total - taxes,
    transactionCount: transactions.length,
    server: `accounting-${PORT}`,
    generatedAt: new Date().toISOString()
  });
});

// Record transaction
app.post('/api/transactions', (req, res) => {
  const { orderId, amount, description } = req.body;
  
  const transaction = {
    id: transactionIdCounter++,
    orderId,
    amount,
    description,
    createdAt: new Date().toISOString()
  };
  
  transactions.push(transaction);
  
  res.status(201).json({ 
    success: true, 
    transaction 
  });
});

// Get all transactions
app.get('/api/transactions', (req, res) => {
  res.json({
    transactions,
    count: transactions.length,
    server: `accounting-${PORT}`
  });
});

app.listen(PORT, () => {
  console.log(`💰 Accounting Service running on port ${PORT}`);
});