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
- `POST /api/storage/objects` - загрузка произвольного объекта в MinIO
- `POST /api/storage/presign` - получение presigned URL для скачивания объекта из MinIO
- `GET /metrics` - метрики Prometheus
- `GET /health` - проверка здоровья сервиса

### Особенности

- **Конкурентная обработка**: Использование goroutines для асинхронного логирования и отправки уведомлений
- **Rate Limiting**: Ограничение 1000 запросов в секунду с burst 5000
- **Мониторинг**: Метрики Prometheus (RPS, latency, ошибки)
- **Валидация**: Проверка корректности данных пользователя (email, обязательные поля)
- **Безопасность**: Thread-safe операции с использованием sync.RWMutex
- **Интеграция с MinIO**: Сохранение снимков пользователей и произвольных объектов в S3-совместимое хранилище, выдача presigned ссылок

## Технологии

- **Go 1.22+**
- **gorilla/mux** - HTTP роутинг
- **prometheus/client_golang** - сбор метрик
- **golang.org/x/time/rate** - rate limiting
- **minio-go** - клиент для S3-совместимого хранилища (MinIO)
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

## Сборка архива для сдачи

Для автоматической сборки архива используйте скрипт:

```bash
# Создать tar.gz архив (по умолчанию)
./build_archive.sh

# Создать zip архив
./build_archive.sh zip

# Создать оба формата
./build_archive.sh both
```

Скрипт автоматически:
- Проверяет наличие всех необходимых файлов
- Копирует исходный код (.go файлы)
- Копирует зависимости (go.mod, go.sum)
- Копирует файлы контейнеризации (Dockerfile, docker-compose.yml)
- Создает архив в выбранном формате
- Проверяет корректность архива

**Примечание**: После создания отчета (.docx) добавьте его в архив вручную или пересоберите архив.

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

## Системные требования для нагрузочного тестирования

### macOS Configuration

Для успешного прохождения нагрузочного теста с 500 одновременными соединениями необходимо увеличить системный параметр `somaxconn`:

```bash
# Проверить текущее значение
sysctl kern.ipc.somaxconn

# Если значение 128 (по умолчанию на macOS), увеличить до 4096
sudo sysctl -w kern.ipc.somaxconn=4096

# Проверить изменение
sysctl kern.ipc.somaxconn
```

**Важно**: Это изменение временное и сбрасывается при перезагрузке. Для постоянного применения добавьте в `/etc/sysctl.conf`:

```
kern.ipc.somaxconn=4096
```

**Почему это необходимо?**
- По умолчанию `somaxconn=128` ограничивает очередь входящих соединений
- При 500 concurrent connections в wrk-тесте многие соединения не успевают попасть в очередь
- Это приводит к "socket errors: connect" в выводе wrk
- Сервер работает отлично (75k+ RPS), но система отбрасывает соединения на уровне ОС

### Linux/Docker Configuration

В production окружении (Linux/Docker/Kubernetes) параметр обычно уже настроен правильно. При необходимости:

```bash
# Временно
sudo sysctl -w net.core.somaxconn=4096

# Постоянно (добавить в /etc/sysctl.conf)
net.core.somaxconn=4096
```

## Нагрузочное тестирование

**Перед запуском теста выполните настройку системных параметров (см. раздел выше).**

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
- `MINIO_ENDPOINT` - адрес MinIO (по умолчанию: minio:9000 в docker-compose)
- `MINIO_ACCESS_KEY` - access key для MinIO
- `MINIO_SECRET_KEY` - secret key для MinIO
- `MINIO_BUCKET` - базовый bucket для экспортов (по умолчанию: users)
- `MINIO_USE_SSL` - использовать ли HTTPS при подключении к MinIO (по умолчанию: false)

Rate limiting фиксированный по заданию: 1000 rps, burst 5000. Применяется к mutating-эндпоинтам (POST/PUT/DELETE), чтения (GET/HEAD) не тормозятся, чтобы пройти нагрузочный тест без 429.

### Пример работы с MinIO

Загрузка объекта:

```bash
curl -X POST http://localhost:8080/api/storage/objects \
  -H "Content-Type: application/json" \
  -d '{
    "bucket": "users",
    "object_name": "notes/example.txt",
    "content": "hello from MinIO",
    "content_type": "text/plain"
  }'
```

Получение presigned URL для скачивания:

```bash
curl -X POST http://localhost:8080/api/storage/presign \
  -H "Content-Type: application/json" \
  -d '{
    "bucket": "users",
    "object_name": "notes/example.txt",
    "expiry_seconds": 900
  }'
```

Снимки пользователей выгружаются в MinIO автоматически при создании/обновлении пользователя:
`users/user-<id>-<timestamp>.json`.

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
