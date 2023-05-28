package app

import (
	"context"
	"strconv"

	desc "ldt-hack/api/internal/pb/app/v1"
	"ldt-hack/api/internal/storage"

	"google.golang.org/protobuf/types/known/emptypb"
)

// SendChatBotMessage implements the chat bot message endpoint.
func (s *Service) SendChatBotMessage(ctx context.Context, req *desc.SendChatBotMessageRequest) (*desc.SendChatBotMessageResponse, error) {
	session, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness)
	if !authorized {
		return nil, errUnauthorized
	}

	response, err := s.bc.SendMessage(strconv.FormatInt(session.AccountID, 10), req.Message)
	if err != nil {
		s.logger.Error("failed to send message to rasa bot", "message", req.Message, "error", err)
		return nil, errInternal
	}

	return &desc.SendChatBotMessageResponse{Messages: response}, nil
}

// RateChatBot implements the chat bot rating message.
func (s *Service) RateChatBot(ctx context.Context, _ *desc.RateChatBotRequest) (*emptypb.Empty, error) {
	_, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness)
	if !authorized {
		return nil, errUnauthorized
	}

	return &emptypb.Empty{}, nil
}
