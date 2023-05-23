package app

import (
	"context"
	"fmt"

	"ldt-hack/api/internal/crypto"
	desc "ldt-hack/api/internal/pb/app/v1"
	"ldt-hack/api/internal/storage"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

var (
	errSessionUnknownType  = status.Error(codes.InvalidArgument, "Указан неподдерживаемый тип пользователя")
	errSessionInvalidCreds = status.Error(codes.Unauthenticated, "Указан несуществующий почтовый адрес или неправильный пароль")
)

// Session is the struct which is encoded in a user's session
type Session struct {
	AccountID   int64               `json:"account_id"`
	AccountType storage.AccountType `json:"account_type"`
}

// CreateSession implements the session creation endpoint.
func (s *Service) CreateSession(ctx context.Context, req *desc.CreateSessionRequest) (*desc.SessionToken, error) {
	accountType, ok := sessionUserToStorage[req.SessionUser]
	if !ok {
		return nil, errSessionUnknownType
	}

	account, err := s.db.GetAccount(ctx, req.Email, accountType)
	if err != nil {
		return nil, errSessionInvalidCreds
	}

	if !crypto.ValidateHashedPassword(req.Password, account.PasswordHash) {
		return nil, errSessionInvalidCreds
	}

	session := s.constructSession("login", account.ID, accountType)
	if session == nil {
		return nil, errInternal
	}

	return session, nil
}

func (s *Service) constructSession(operation string, accountID int64, accountType storage.AccountType) *desc.SessionToken {
	token, err := s.authorizer.Construct(Session{AccountID: accountID, AccountType: storage.AccountTypeBusiness})
	if err != nil {
		s.logger.Error("failed to construct user token", "operation", operation, "account_id", accountID, "error", err)
		return nil
	}

	return &desc.SessionToken{Token: token}
}

func (s *Service) authorizeSession(ctx context.Context, session Session, accountType ...storage.AccountType) (bool, error) {
	if len(accountType) >= 1 && session.AccountType != accountType[0] {
		return false, nil
	}

	exists, err := s.db.CheckAccountExists(ctx, session.AccountID, session.AccountType)
	if err != nil {
		return false, fmt.Errorf("checking whether session account %d, %s exists in db: %w",
			session.AccountID, session.AccountType, err,
		)
	}

	return exists, nil
}
