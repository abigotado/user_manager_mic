package utils

import (
	"log"
	"time"
)

// LogUserAction логирует действие пользователя асинхронно
func LogUserAction(action string, userID int) {
	// Используем goroutine для асинхронного логирования
	go func() {
		// Имитация записи в audit log
		log.Printf("[AUDIT] Action: %s, UserID: %d, Timestamp: %s", 
			action, userID, time.Now().Format(time.RFC3339))
	}()
}

// SendNotification отправляет уведомление асинхронно
func SendNotification(userID int, message string) {
	// Используем goroutine для асинхронной отправки уведомлений
	go func() {
		// Имитация отправки уведомления
		log.Printf("[NOTIFICATION] UserID: %d, Message: %s, Timestamp: %s", 
			userID, message, time.Now().Format(time.RFC3339))
	}()
}

// LogError логирует ошибку асинхронно
func LogError(operation string, err error) {
	// Используем goroutine для асинхронного логирования ошибок
	go func() {
		log.Printf("[ERROR] Operation: %s, Error: %v, Timestamp: %s", 
			operation, err, time.Now().Format(time.RFC3339))
	}()
}

