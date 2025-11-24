package models

import (
	"errors"
	"regexp"
	"sync/atomic"
)

// User представляет модель пользователя
type User struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

// Validate проверяет корректность данных пользователя
func (u *User) Validate() error {
	if u.Name == "" {
		return errors.New("name is required")
	}
	if u.Email == "" {
		return errors.New("email is required")
	}
	
	// Валидация email с помощью регулярного выражения
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)
	if !emailRegex.MatchString(u.Email) {
		return errors.New("invalid email format")
	}
	
	return nil
}

// nextID используется для генерации уникальных ID
var nextID int64

// GenerateID генерирует следующий уникальный ID
func GenerateID() int {
	return int(atomic.AddInt64(&nextID, 1))
}

