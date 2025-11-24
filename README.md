# User Manager Microservice

Высоконагруженный микросервис для управления пользователями на языке Go.

## Описание

Микросервис предоставляет RESTful API для выполнения CRUD-операций с пользователями, поддерживает высокую нагрузку (1000+ RPS), включает мониторинг метрик Prometheus и rate limiting.

## Функциональность

### HTTP API Endpoints

- `GET /api/users` - получение списка всех пользователей
- `GET /api/users/{id}` - получение конкретного пользователя
- `POST /api/users` - создание нового пользователя
- `PUT /api/users/{id}` - обновление данных пользователя
- `DELETE /api/users/{id}` - удаление пользователя
- `GET /metrics` - метрики Prometheus
- `GET /health` - проверка здоровья сервиса

### Особенности

- **Конкурентная обработка**: Использование goroutines для асинхронного логирования и отправки уведомлений
- **Rate Limiting**: Ограничение 1000 запросов в секунду с burst 5000
- **Мониторинг**: Метрики Prometheus (RPS, latency, ошибки)
- **Валидация**: Проверка корректности данных пользователя (email, обязательные поля)
- **Безопасность**: Thread-safe операции с использованием sync.RWMutex

## Технологии

- **Go 1.22+**
- **gorilla/mux** - HTTP роутинг
- **prometheus/client_golang** - сбор метрик
- **golang.org/x/time/rate** - rate limiting
- **Docker** - контейнеризация

## Структура проекта

```
go-microservice/
├── main.go                 # Точка входа приложения
├── handlers/               # HTTP обработчики
│   └── user_handler.go
├── services/               # Бизнес-логика
│   └── user_service.go
├── models/                 # Модели данных
│   └── user.go
├── utils/                  # Утилиты
│   ├── logger.go
│   └── rate_limiter.go
├── metrics/                # Метрики Prometheus
│   └── prometheus.go
├── go.mod
├── go.sum
├── Dockerfile
├── docker-compose.yml
└── README.md
```

## Установка и запуск

### Локальный запуск

```bash
# Установка зависимостей
go mod download

# Запуск сервиса
go run main.go
```

Сервис будет доступен на `http://localhost:8080`

### Запуск через Docker

```bash
# Сборка образа
docker build -t user-manager .

# Запуск контейнера
docker run -p 8080:8080 user-manager
```

### Запуск через Docker Compose

```bash
# Запуск сервиса
docker-compose up -d

# Просмотр логов
docker-compose logs -f

# Остановка
docker-compose down
```

## Использование API

### Создание пользователя

```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com"
  }'
```

### Получение всех пользователей

```bash
curl http://localhost:8080/api/users
```

### Получение пользователя по ID

```bash
curl http://localhost:8080/api/users/1
```

### Обновление пользователя

```bash
curl -X PUT http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Doe",
    "email": "jane@example.com"
  }'
```

### Удаление пользователя

```bash
curl -X DELETE http://localhost:8080/api/users/1
```

### Просмотр метрик

```bash
curl http://localhost:8080/metrics
```

## Нагрузочное тестирование

Для нагрузочного тестирования используется `wrk`:

```bash
wrk -t12 -c500 -d60s http://localhost:8080/api/users
```

Ожидаемые результаты:
- **RPS**: > 1000 запросов в секунду
- **Latency**: < 10 мс
- **Ошибки**: 0%

## Метрики Prometheus

Сервис предоставляет следующие метрики:

- `http_requests_total` - общее количество HTTP запросов (по методу и endpoint)
- `http_request_duration_seconds` - длительность запросов (гистограмма)
- `http_request_errors_total` - количество ошибок (по методу, endpoint и статусу)

## Конфигурация

Переменные окружения:

- `PORT` - порт для запуска сервиса (по умолчанию: 8080)

## Разработка

### Требования

- Go 1.22 или выше
- Docker (опционально)

### Запуск тестов

```bash
go test ./...
```

### Сборка

```bash
go build -o user-manager .
```

## Лицензия

MIT

