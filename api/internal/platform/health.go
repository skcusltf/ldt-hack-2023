package platform

import (
	"net/http"
	"time"

	"github.com/hellofresh/health-go/v5"
)

const healthCheckTimeout = time.Second * 5

// HealthHandler initializes a healthcheck http handler
func HealthHandler(pgCheck health.CheckFunc) http.Handler {
	h, _ := health.New(
		health.WithComponent(health.Component{
			Name:    "ldt-api",
			Version: "v0.1.1",
		}),
		health.WithChecks(
			health.Config{
				Name:      "postgres",
				Timeout:   healthCheckTimeout,
				SkipOnErr: false,
				Check:     pgCheck,
			},
		),
	)

	return h.Handler()
}
