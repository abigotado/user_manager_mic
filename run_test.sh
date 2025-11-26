#!/bin/bash

set -e

echo "=== Load Test Script ==="
echo

# Step 1: Check somaxconn
echo "1️⃣  Checking system configuration..."
SOMAXCONN=$(sysctl -n kern.ipc.somaxconn)
echo "   kern.ipc.somaxconn = $SOMAXCONN"
if [ "$SOMAXCONN" -lt 4096 ]; then
    echo "   ⚠️  WARNING: somaxconn is too low!"
    echo "   Run: sudo sysctl -w kern.ipc.somaxconn=4096"
    exit 1
fi
echo "   ✅ System configuration OK"
echo

# Step 2: Stop any existing containers
echo "2️⃣  Stopping existing containers..."
docker compose down 2>/dev/null || true
sleep 2
echo "   ✅ Containers stopped"
echo

# Step 3: Start fresh
echo "3️⃣  Starting services..."
docker compose up -d
echo "   Waiting for services to be ready..."
sleep 20

# Step 4: Health check
echo "4️⃣  Checking service health..."
HEALTH=$(curl -s http://localhost:8080/health)
if [ "$HEALTH" != "OK" ]; then
    echo "   ❌ Service not healthy!"
    echo "   Response: $HEALTH"
    docker compose logs user-manager-service
    exit 1
fi
echo "   ✅ Service is healthy"
echo

# Step 5: Run load test
echo "5️⃣  Running load test (60 seconds)..."
echo "   Command: wrk -t12 -c500 -d60s http://localhost:8080/api/users"
echo
wrk -t12 -c500 -d60s http://localhost:8080/api/users
echo
echo "=== Test Complete ==="
