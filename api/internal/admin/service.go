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
	group.POST("/login", s.loginHandler)
	group.POST("/authority/info", s.authorityInfoHandler)
}
