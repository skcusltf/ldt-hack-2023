package auth

import (
	"context"

	desc "ldt-hack/api/internal/pb/auth/v1"

	"golang.org/x/exp/slog"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
)

type storage interface {
	Select(ctx context.Context) (string, error)
}

// Service implements the AuthN/AuthZ service
type Service struct {
	desc.UnimplementedAuthServiceServer

	logger  *slog.Logger
	storage storage
}

// NewService initializes a new auth service using the given components.
func NewService(logger *slog.Logger, storage storage) *Service {
	return &Service{
		logger:  logger.With("app", "auth"),
		storage: storage,
	}
}

// RegisterServer registers this service with a gRPC server.
func (s *Service) RegisterServer(server *grpc.Server) {
	desc.RegisterAuthServiceServer(server, s)
}

func (s *Service) Echo(_ context.Context, req *desc.EchoRequest) (*desc.EchoResponse, error) {
	return &desc.EchoResponse{
		S: req.S,
	}, nil
}

func (s *Service) Select(ctx context.Context, _ *emptypb.Empty) (*desc.SelectResponse, error) {
	str, err := s.storage.Select(ctx)
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	return &desc.SelectResponse{S: str}, nil
}
