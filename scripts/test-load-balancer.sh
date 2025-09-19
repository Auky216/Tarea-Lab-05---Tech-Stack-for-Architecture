#!/bin/bash

echo "🧪 Testing Load Balancer..."

echo -e "\n1. Testing Sales Service (10 requests):"
for i in {1..10}; do
  curl -s http://localhost:8080/api/tickets | jq -r '.server'
done

echo -e "\n2. Testing Accounting Service (10 requests):"
for i in {1..10}; do
  curl -s http://localhost:8080/api/report | jq -r '.server'
done

echo -e "\n✅ Test completed!"