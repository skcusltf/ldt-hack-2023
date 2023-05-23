package app

import (
	"ldt-hack/api/internal/auth"
	desc "ldt-hack/api/internal/pb/app/v1"
	"ldt-hack/api/internal/storage"

	"golang.org/x/exp/slog"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

var (
	errInternal      = status.Error(codes.Internal, "Приложению плохо, попробуйте повторить немного позже!")
	errMissingFields = status.Error(codes.InvalidArgument, "Необходимо заполнить все обязательные поля")
	errUnauthorized  = status.Error(codes.PermissionDenied, "Необходимо авторизоваться для работы с приложением")
)

// Service implements the main application gRPC service logic.
type Service struct {
	desc.UnimplementedAppServiceServer

	logger     *slog.Logger
	db         *storage.Database
	authorizer *auth.Authorizer
}

func NewService(logger *slog.Logger, db *storage.Database, authorizer *auth.Authorizer) *Service {
	return &Service{logger: logger.With("component", "app"), db: db, authorizer: authorizer}
}

// RegisterServer registers this service with the gRPC server.
func (s *Service) RegisterServer(server *grpc.Server) {
	desc.RegisterAppServiceServer(server, s)
}
