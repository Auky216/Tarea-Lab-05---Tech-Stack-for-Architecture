#!/bin/bash

echo "🚀 Iniciando servicios localmente..."

# Sales Service - 2 instancias
PORT=3001 node services/sales-service/index.js &
PORT=3011 node services/sales-service/index.js &

# Accounting Service - 2 instancias
PORT=3002 node services/accounting-service/index.js &
PORT=3012 node services/accounting-service/index.js &

echo "✅ Servicios iniciados:"
echo "   Sales: http://localhost:3001 y http://localhost:3011"
echo "   Accounting: http://localhost:3002 y http://localhost:3012"

# Mantener script corriendo
wait