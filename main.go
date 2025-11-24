package main

import (
	"log"
	"net/http"
	"os"

	"go-microservice/handlers"
	"go-microservice/metrics"
	"go-microservice/services"
	"go-microservice/utils"

	"github.com/gorilla/mux"
	"golang.org/x/time/rate"
)

func main() {
	// Инициализация сервисов
	userService := services.NewUserService()
	userHandler := handlers.NewUserHandler(userService)

	// Создание роутера
	router := mux.NewRouter()

	// Регистрация метрик
	metrics.RegisterMetricsHandler(router)

	// API routes
	api := router.PathPrefix("/api").Subrouter()

	// User routes
	api.HandleFunc("/users", userHandler.GetAllUsers).Methods("GET")
	api.HandleFunc("/users/{id:[0-9]+}", userHandler.GetUserByID).Methods("GET")
	api.HandleFunc("/users", userHandler.CreateUser).Methods("POST")
	api.HandleFunc("/users/{id:[0-9]+}", userHandler.UpdateUser).Methods("PUT")
	api.HandleFunc("/users/{id:[0-9]+}", userHandler.DeleteUser).Methods("DELETE")

	// Health check endpoint
	router.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	}).Methods("GET")

	// Создание rate limiter: 1000 req/s с burst 5000
	rateLimiter := utils.NewRateLimiter(rate.Limit(1000), 5000)

	// Применение middleware: сначала метрики, потом rate limiting
	handler := metrics.MetricsMiddleware(router)
	handler = rateLimiter.Middleware(handler)

	// Получение порта из переменной окружения или использование значения по умолчанию
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	log.Printf("API endpoints:")
	log.Printf("  GET    /api/users")
	log.Printf("  GET    /api/users/{id}")
	log.Printf("  POST   /api/users")
	log.Printf("  PUT    /api/users/{id}")
	log.Printf("  DELETE /api/users/{id}")
	log.Printf("  GET    /metrics")
	log.Printf("  GET    /health")

	if err := http.ListenAndServe(":"+port, handler); err != nil {
		log.Fatal("Server failed to start:", err)
	}
}
