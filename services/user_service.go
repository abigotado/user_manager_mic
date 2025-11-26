package services

import (
	"errors"
	"go-microservice/models"
	"sync"
)

type UserService struct {
	users map[int]*models.User
	mu    sync.RWMutex
}

func NewUserService() *UserService {
	return &UserService{
		users: make(map[int]*models.User),
	}
}
func (s *UserService) GetAll() []*models.User {
	s.mu.RLock()
	defer s.mu.RUnlock()
	users := make([]*models.User, 0, len(s.users))
	for _, user := range s.users {
		users = append(users, user)
	}
	return users
}
func (s *UserService) GetByID(id int) (*models.User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	user, exists := s.users[id]
	if !exists {
		return nil, errors.New("user not found")
	}
	return user, nil
}
func (s *UserService) Create(user models.User) (*models.User, error) {
	if err := user.Validate(); err != nil {
		return nil, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	user.ID = models.GenerateID()
	userCopy := user
	s.users[user.ID] = &userCopy
	return &userCopy, nil
}
func (s *UserService) Update(id int, user models.User) (*models.User, error) {
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
