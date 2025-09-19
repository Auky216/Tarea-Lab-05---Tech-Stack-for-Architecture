const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Cache en memoria
const cache = {};

// Mock data - tickets disponibles
let tickets = [
  { id: 1, event: 'Concierto Rock', seat: 'A1', price: 50, available: true },
  { id: 2, event: 'Concierto Rock', seat: 'A2', price: 50, available: true },
  { id: 3, event: 'Concierto Rock', seat: 'A3', price: 50, available: true },
  { id: 4, event: 'Teatro', seat: 'B1', price: 30, available: true },
  { id: 5, event: 'Teatro', seat: 'B2', price: 30, available: true },
];

let orders = [];
let orderIdCounter = 1;

// Queue para procesar órdenes de forma sincronizada
const processingQueue = [];
let isProcessing = false;

async function processQueue() {
  if (isProcessing || processingQueue.length === 0) return;
  
  isProcessing = true;
  const { ticketId, customerName, customerEmail, resolve, reject } = processingQueue.shift();
  
  try {
    const ticket = tickets.find(t => t.id === ticketId);
    
    if (!ticket) {
      reject({ status: 404, data: { error: 'Ticket not found' }});
      isProcessing = false;
      setTimeout(processQueue, 0);
      return;
    }
    
    if (!ticket.available) {
      reject({ status: 409, data: { error: 'Ticket already sold', code: 'TICKET_UNAVAILABLE' }});
      isProcessing = false;
      setTimeout(processQueue, 0);
      return;
    }
    
    // Marcar como vendido
    ticket.available = false;
    
    // Crear orden
    const order = {
      id: orderIdCounter++,
      ticketId,
      customerName,
      customerEmail,
      price: ticket.price,
      status: 'completed',
      createdAt: new Date().toISOString(),
      processedBy: `sales-${PORT}`
    };
    
    orders.push(order);
    
    // Invalidar caché
    delete cache['all_tickets'];
    
    console.log(`Order ${order.id} created for ticket ${ticketId} (${ticket.seat}) by ${customerName}`);
    
    resolve({
      success: true, 
      order,
      message: `Ticket ${ticket.seat} comprado exitosamente`
    });
    
  } catch (error) {
    reject({ status: 500, data: { error: error.message }});
  } finally {
    isProcessing = false;
    // Procesar siguiente en queue
    setTimeout(processQueue, 0);
  }
}

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'sales-service',
    port: PORT,
    timestamp: new Date().toISOString()
  });
});

// Get available tickets
app.get('/api/tickets', (req, res) => {
  const cacheKey = 'all_tickets';
  const now = Date.now();
  
  if (cache[cacheKey] && cache[cacheKey].expires > now) {
    console.log('Cache HIT');
    return res.json({
      ...cache[cacheKey].data,
      cached: true
    });
  }
  
  console.log('Cache MISS');
  const availableTickets = tickets.filter(t => t.available);
  
  const response = {
    tickets: availableTickets,
    count: availableTickets.length,
    server: `sales-${PORT}`,
    cached: false
  };
  
  cache[cacheKey] = {
    data: response,
    expires: now + 30000
  };
  
  res.json(response);
});

// Create order - CON COLA DE PROCESAMIENTO
app.post('/api/orders', (req, res) => {
  const { ticketId, customerName, customerEmail } = req.body;
  
  if (!ticketId || !customerName || !customerEmail) {
    return res.status(400).json({ error: 'Missing required fields' });
  }
  
  console.log(`Request from ${customerName} for ticket ${ticketId} - adding to queue (position: ${processingQueue.length + 1})`);
  
  // Agregar a queue y esperar procesamiento
  const promise = new Promise((resolve, reject) => {
    processingQueue.push({ ticketId, customerName, customerEmail, resolve, reject });
    processQueue();
  });
  
  promise
    .then(result => {
      res.status(201).json(result);
    })
    .catch(error => {
      res.status(error.status).json(error.data);
    });
});

// Get orders
app.get('/api/orders', (req, res) => {
  res.json({
    orders,
    count: orders.length,
    server: `sales-${PORT}`
  });
});

app.listen(PORT, () => {
  console.log(`Sales Service running on port ${PORT}`);
});