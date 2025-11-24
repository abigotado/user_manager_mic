# Многоэтапная сборка для оптимизации размера образа
FROM golang:1.22-alpine AS builder

# Установка рабочей директории
WORKDIR /app

# Копирование go mod файлов
COPY go.mod go.sum ./

# Загрузка зависимостей
RUN go mod download

# Копирование исходного кода
COPY . .

# Сборка приложения
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Финальный образ
FROM alpine:latest

# Установка ca-certificates для HTTPS запросов
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Копирование бинарного файла из builder
COPY --from=builder /app/main .

# Открытие порта
EXPOSE 8080

# Запуск приложения
CMD ["./main"]

