package app

import (
	"context"

	desc "ldt-hack/api/internal/pb/app/v1"

	"google.golang.org/protobuf/types/known/emptypb"
)

// SendChatBotMessage implements the chat bot message endpoint.
func (s *Service) SendChatBotMessage(context.Context, *desc.SendChatBotMessageRequest) (*desc.SendChatBotMessageResponse, error) {
	return &desc.SendChatBotMessageResponse{
		Messages: []string{
			"Пример ответа от бота",
		},
	}, nil
}

// RateChatBot implements the chat bot rating message.
func (s *Service) RateChatBot(context.Context, *desc.RateChatBotRequest) (*emptypb.Empty, error) {
	return &emptypb.Empty{}, nil
}
