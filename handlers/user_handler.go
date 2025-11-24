package handlers

import (
	"encoding/json"
	"go-microservice/models"
	"go-microservice/services"
	"go-microservice/utils"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
)

// UserHandler содержит обработчики для работы с пользователями
type UserHandler struct {
	service *services.UserService
}

// NewUserHandler создает новый экземпляр UserHandler
func NewUserHandler(service *services.UserService) *UserHandler {
	return &UserHandler{
		service: service,
	}
}

// GetAllUsers обрабатывает GET /api/users
func (h *UserHandler) GetAllUsers(w http.ResponseWriter, r *http.Request) {
	users := h.service.GetAll()
	
	// Асинхронное логирование
	go utils.LogUserAction("GET_ALL", 0)
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// GetUserByID обрабатывает GET /api/users/{id}
func (h *UserHandler) GetUserByID(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		go utils.LogError("GetUserByID", err)
		return
	}
	
	user, err := h.service.GetByID(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		go utils.LogError("GetUserByID", err)
		return
	}
	
	// Асинхронное логирование
	go utils.LogUserAction("GET", user.ID)
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// CreateUser обрабатывает POST /api/users
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
	var user models.User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		go utils.LogError("CreateUser", err)
		return
	}
	
	// Создаем пользователя
	savedUser, err := h.service.Create(user)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		go utils.LogError("CreateUser", err)
		return
	}
	
	// Асинхронное логирование (после присвоения ID)
	go utils.LogUserAction("CREATE", savedUser.ID)
	
	// Асинхронная отправка уведомления
	go utils.SendNotification(savedUser.ID, "User created successfully")
	
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(savedUser)
}

// UpdateUser обрабатывает PUT /api/users/{id}
func (h *UserHandler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		go utils.LogError("UpdateUser", err)
		return
	}
	
	var user models.User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		go utils.LogError("UpdateUser", err)
		return
	}
	
	updatedUser, err := h.service.Update(id, user)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		go utils.LogError("UpdateUser", err)
		return
	}
	
	// Асинхронное логирование
	go utils.LogUserAction("UPDATE", updatedUser.ID)
	
	// Асинхронная отправка уведомления
	go utils.SendNotification(updatedUser.ID, "User updated successfully")
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updatedUser)
}

// DeleteUser обрабатывает DELETE /api/users/{id}
func (h *UserHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		go utils.LogError("DeleteUser", err)
		return
	}
	
	err = h.service.Delete(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		go utils.LogError("DeleteUser", err)
		return
	}
	
	// Асинхронное логирование
	go utils.LogUserAction("DELETE", id)
	
	w.WriteHeader(http.StatusNoContent)
}

