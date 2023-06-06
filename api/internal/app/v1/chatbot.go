package app

import (
	"context"
	"strconv"

	desc "ldt-hack/api/internal/pb/app/v1"
	"ldt-hack/api/internal/storage"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
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

	id, err := s.db.CreateChatMessage(ctx, req.Message, response)
	if err != nil {
		s.logger.Error("failed to record chat bot request/response in storage",
			"request", req.Message,
			"response", response,
			"error", err,
		)
		return nil, errInternal
	}

	return &desc.SendChatBotMessageResponse{Id: id, Messages: response}, nil
}

// RateChatBot implements the chat bot rating message.
func (s *Service) RateChatBot(ctx context.Context, req *desc.RateChatBotRequest) (*emptypb.Empty, error) {
	_, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness)
	if !authorized {
		return nil, errUnauthorized
	}

	rating := new(bool)
	switch req.Rating {
	case desc.RateChatBotRequest_RATING_REMOVED:
		rating = nil
	case desc.RateChatBotRequest_RATING_NEGATIVE:
		*rating = false
	case desc.RateChatBotRequest_RATING_POSITIVE:
		*rating = true
	default:
		return nil, status.Error(codes.InvalidArgument, "Указана недопустимая оценка сообщения")
	}

	if err := s.db.UpdateChatMessageRating(ctx, req.Id, rating); err != nil {
		s.logger.Error("failed to update chat bot message rating in storage",
			"id", req.Id,
			"rating", rating,
			"error", err,
		)
		return nil, errInternal
	}

	return &emptypb.Empty{}, nil
}
