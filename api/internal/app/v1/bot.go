package app

import (
	"context"

	desc "ldt-hack/api/internal/pb/app/v1"
	"ldt-hack/api/internal/storage"

	"google.golang.org/protobuf/types/known/emptypb"
)

// SendChatBotMessage implements the chat bot message endpoint.
func (s *Service) SendChatBotMessage(ctx context.Context, _ *desc.SendChatBotMessageRequest) (*desc.SendChatBotMessageResponse, error) {
	_, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness)
	if !authorized {
		return nil, errUnauthorized
	}

	return &desc.SendChatBotMessageResponse{
		Messages: []string{
			"Пример ответа от бота",
		},
	}, nil
}

// RateChatBot implements the chat bot rating message.
func (s *Service) RateChatBot(ctx context.Context, _ *desc.RateChatBotRequest) (*emptypb.Empty, error) {
	_, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness)
	if !authorized {
		return nil, errUnauthorized
	}

	return &emptypb.Empty{}, nil
}
