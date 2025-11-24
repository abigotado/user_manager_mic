#!/bin/bash

# Скрипт для нагрузочного тестирования микросервиса
# Использование: ./load_test.sh

echo "=== Нагрузочное тестирование User Manager Microservice ==="
echo ""

# Проверка наличия wrk
if ! command -v wrk &> /dev/null; then
    echo "Ошибка: wrk не установлен. Установите его:"
    echo "  macOS: brew install wrk"
    echo "  Linux: sudo apt-get install wrk"
    exit 1
fi

# URL сервиса
URL="${1:-http://localhost:8080/api/users}"

echo "Тестируемый URL: $URL"
echo "Параметры: -t12 -c500 -d60s"
echo ""

# Запуск теста
echo "Запуск нагрузочного теста..."
wrk -t12 -c500 -d60s "$URL"

echo ""
echo "=== Тест завершен ==="
echo ""
echo "Для просмотра метрик выполните:"
echo "  curl http://localhost:8080/metrics | grep http_requests"

