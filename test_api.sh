#!/bin/bash

# Скрипт для тестирования API endpoints
# Использование: ./test_api.sh [base_url]
# По умолчанию: http://localhost:8080

BASE_URL="${1:-http://localhost:8080}"
API_URL="${BASE_URL}/api/users"

echo "=== Тестирование User Manager API ==="
echo "Base URL: $BASE_URL"
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для проверки ответа
check_response() {
    local name=$1
    local status=$2
    local expected_status=$3
    
    if [ "$status" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓${NC} $name: OK (Status: $status)"
        return 0
    else
        echo -e "${RED}✗${NC} $name: FAILED (Expected: $expected_status, Got: $status)"
        return 1
    fi
}

# 1. Health check
echo "1. Health Check"
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
check_response "Health Check" "$HEALTH" "200"
echo ""

# 2. Получение всех пользователей (должно быть пусто)
echo "2. GET /api/users (должен вернуть пустой список)"
RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
check_response "GET /api/users" "$HTTP_CODE" "200"
echo "Response: $BODY"
echo ""

# 3. Создание пользователя
echo "3. POST /api/users (создание пользователя)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test User","email":"test@example.com"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
check_response "POST /api/users" "$HTTP_CODE" "201"
echo "Response: $BODY"

# Извлекаем ID из ответа
USER_ID=$(echo "$BODY" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)
if [ -z "$USER_ID" ]; then
    echo -e "${RED}✗${NC} Не удалось извлечь ID пользователя"
    exit 1
fi
echo "Created User ID: $USER_ID"
echo ""

# 4. Получение пользователя по ID
echo "4. GET /api/users/$USER_ID"
RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/$USER_ID")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
check_response "GET /api/users/$USER_ID" "$HTTP_CODE" "200"
echo "Response: $BODY"
echo ""

# 5. Обновление пользователя
echo "5. PUT /api/users/$USER_ID (обновление пользователя)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$API_URL/$USER_ID" \
    -H "Content-Type: application/json" \
    -d '{"name":"Updated User","email":"updated@example.com"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
check_response "PUT /api/users/$USER_ID" "$HTTP_CODE" "200"
echo "Response: $BODY"
echo ""

# 6. Получение всех пользователей (должен быть один)
echo "6. GET /api/users (должен вернуть одного пользователя)"
RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
check_response "GET /api/users" "$HTTP_CODE" "200"
echo "Response: $BODY"
echo ""

# 7. Удаление пользователя
echo "7. DELETE /api/users/$USER_ID"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$API_URL/$USER_ID")
check_response "DELETE /api/users/$USER_ID" "$HTTP_CODE" "204"
echo ""

# 8. Попытка получить удаленного пользователя (должна вернуть 404)
echo "8. GET /api/users/$USER_ID (должен вернуть 404)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/$USER_ID")
check_response "GET /api/users/$USER_ID (404 expected)" "$HTTP_CODE" "404"
echo ""

# 9. Проверка метрик
echo "9. GET /metrics"
METRICS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/metrics")
if [ "$METRICS_CODE" -eq "200" ]; then
    echo -e "${GREEN}✓${NC} Metrics endpoint доступен"
    METRICS_COUNT=$(curl -s "$BASE_URL/metrics" | grep -c "http_requests_total")
    echo "   Найдено метрик http_requests_total: $METRICS_COUNT"
else
    echo -e "${RED}✗${NC} Metrics endpoint недоступен (Status: $METRICS_CODE)"
fi
echo ""

# 10. Тест валидации (некорректный email)
echo "10. POST /api/users (некорректный email - должен вернуть 400)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"name":"Invalid User","email":"invalid-email"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
check_response "POST /api/users (validation error)" "$HTTP_CODE" "400"
echo "Response: $BODY"
echo ""

# 11. Тест валидации (отсутствует name)
echo "11. POST /api/users (отсутствует name - должен вернуть 400)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"email":"test2@example.com"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
check_response "POST /api/users (validation error)" "$HTTP_CODE" "400"
echo "Response: $BODY"
echo ""

echo "=== Тестирование завершено ==="

