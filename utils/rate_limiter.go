package utils

import (
	"net/http"
	"golang.org/x/time/rate"
)

// RateLimiter содержит лимитер запросов
type RateLimiter struct {
	limiter *rate.Limiter
}

// NewRateLimiter создает новый rate limiter
// rps - запросов в секунду, burst - размер буфера для всплесков
func NewRateLimiter(rps rate.Limit, burst int) *RateLimiter {
	return &RateLimiter{
		limiter: rate.NewLimiter(rps, burst),
	}
}

// Middleware возвращает HTTP middleware для ограничения скорости
func (rl *RateLimiter) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !rl.limiter.Allow() {
			http.Error(w, "Too Many Requests", http.StatusTooManyRequests)
			return
		}
		next.ServeHTTP(w, r)
	})
}

