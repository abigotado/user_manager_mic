package services

import (
	"errors"
	"go-microservice/models"
	"sync"
)

// UserService предоставляет методы для работы с пользователями
type UserService struct {
	users map[int]*models.User
	mu    sync.RWMutex
}

// NewUserService создает новый экземпляр UserService
func NewUserService() *UserService {
	return &UserService{
		users: make(map[int]*models.User),
	}
}

// GetAll возвращает список всех пользователей
func (s *UserService) GetAll() []*models.User {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	users := make([]*models.User, 0, len(s.users))
	for _, user := range s.users {
		users = append(users, user)
	}
	return users
}

// GetByID возвращает пользователя по ID
func (s *UserService) GetByID(id int) (*models.User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	user, exists := s.users[id]
	if !exists {
		return nil, errors.New("user not found")
	}
	return user, nil
}

// Create создает нового пользователя
func (s *UserService) Create(user models.User) (*models.User, error) {
	// Валидация
	if err := user.Validate(); err != nil {
		return nil, err
	}
	
	s.mu.Lock()
	defer s.mu.Unlock()
	
	// Генерируем ID
	user.ID = models.GenerateID()
	
	// Создаем копию для хранения
	userCopy := user
	s.users[user.ID] = &userCopy
	
	return &userCopy, nil
}

// Update обновляет данные пользователя
func (s *UserService) Update(id int, user models.User) (*models.User, error) {
	// Валидация
	if err := user.Validate(); err != nil {
		return nil, err
	}
	
	s.mu.Lock()
	defer s.mu.Unlock()
	
	_, exists := s.users[id]
	if !exists {
		return nil, errors.New("user not found")
	}
	
	user.ID = id
	userCopy := user
	s.users[id] = &userCopy
	
	return &userCopy, nil
}

// Delete удаляет пользователя по ID
func (s *UserService) Delete(id int) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	_, exists := s.users[id]
	if !exists {
		return errors.New("user not found")
	}
	
	delete(s.users, id)
	return nil
}

