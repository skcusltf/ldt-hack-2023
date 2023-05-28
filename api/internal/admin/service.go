package admin

import (
	"errors"
	"strings"

	"ldt-hack/api/internal/auth"
	"ldt-hack/api/internal/storage"

	"github.com/gin-gonic/gin"
	"golang.org/x/exp/slog"
)

// Service implements the admin web server logic.
type Service struct {
	adminUsername     []byte
	adminPasswordHash []byte

	logger     *slog.Logger
	db         *storage.Database
	authorizer *auth.Authorizer
}

func NewService(logger *slog.Logger, db *storage.Database, authorizer *auth.Authorizer, adminCredentials string) (*Service, error) {
	credentials := strings.Split(adminCredentials, ":")
	if len(credentials) != 2 || credentials[0] == "" || credentials[1] == "" {
		return nil, errors.New("invalid admin credentials provided")
	}

	return &Service{
		adminUsername:     []byte(credentials[0]),
		adminPasswordHash: []byte(credentials[1]),
		logger:            logger.With("component", "admin"),
		db:                db,
		authorizer:        authorizer,
	}, nil
}

func (s *Service) RegisterRoutes(group *gin.RouterGroup) {
	group.Use(func(c *gin.Context) {
		c.Next()

		s.logger.Info("handling http request",
			"method", c.Request.Method,
			"path", c.FullPath(),
			"status_code", c.Writer.Status(),
		)
	})

	{
		group.POST("/login", s.loginHandler)
	}

	// Authorized endpoints
	authorized := group.Group("/")
	authorized.Use(func(c *gin.Context) {
		if !s.authorizeSession(c) {
			return
		}

		c.Next()
	})
	{
		authorized.GET("/authority", s.listAuthoritiesHandler)
		authorized.POST("/authority/info", s.authorityInfoHandler)
		authorized.POST("/authority/:id/inspector", s.createInspectorHandler)
	}
}
