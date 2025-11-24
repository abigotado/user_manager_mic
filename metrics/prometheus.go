package metrics

import (
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	// TotalRequests - счетчик общего количества HTTP запросов
	TotalRequests = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint"},
	)

	// RequestDuration - гистограмма длительности запросов
	RequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Request duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)

	// RequestErrors - счетчик ошибок
	RequestErrors = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_request_errors_total",
			Help: "Total number of HTTP request errors",
		},
		[]string{"method", "endpoint", "status"},
	)
)

func init() {
	prometheus.MustRegister(TotalRequests)
	prometheus.MustRegister(RequestDuration)
	prometheus.MustRegister(RequestErrors)
}

// MetricsMiddleware возвращает middleware для сбора метрик
func MetricsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Получаем путь из роутера
		route := mux.CurrentRoute(r)
		var path string
		if route != nil {
			path, _ = route.GetPathTemplate()
		}
		if path == "" {
			path = r.URL.Path
		}

		// Создаем обертку для ResponseWriter для отслеживания статуса
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		next.ServeHTTP(wrapped, r)

		// Записываем метрики
		duration := time.Since(start).Seconds()
		TotalRequests.WithLabelValues(r.Method, path).Inc()
		RequestDuration.WithLabelValues(r.Method, path).Observe(duration)

		// Записываем ошибки (4xx, 5xx)
		if wrapped.statusCode >= 400 {
			RequestErrors.WithLabelValues(r.Method, path, http.StatusText(wrapped.statusCode)).Inc()
		}
	})
}

// responseWriter обертка для ResponseWriter для отслеживания статуса
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// RegisterMetricsHandler регистрирует endpoint /metrics для Prometheus
func RegisterMetricsHandler(router *mux.Router) {
	router.Handle("/metrics", promhttp.Handler()).Methods("GET")
}

