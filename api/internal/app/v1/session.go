package app

import (
	"context"

	"ldt-hack/api/internal/auth"
	"ldt-hack/api/internal/crypto"
	desc "ldt-hack/api/internal/pb/app/v1"
	"ldt-hack/api/internal/storage"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
	"google.golang.org/protobuf/types/known/timestamppb"
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

// GetSessionUser gets the authorized users' info.
func (s *Service) GetSessionUser(ctx context.Context, _ *emptypb.Empty) (*desc.GetSessionUserResponse, error) {
	session, authorized := s.authorizeSession(ctx)
	if !authorized {
		return nil, errUnauthorized
	}

	var businessUser *desc.BusinessUser
	var err error

	if session.AccountType == storage.AccountTypeBusiness {
		var user storage.BusinessUser
		user, err = s.db.GetBusinessUser(ctx, session.AccountID)

		businessUser = &desc.BusinessUser{
			FirstName:      user.FirstName,
			PatronymicName: user.PatronymicName,
			LastName:       user.LastName,
			BirthDate:      timestamppb.New(user.BirthDate),
			Sex:            personSexFromStorage[user.Sex],
			BusinessName:   user.BusinessName,
			PhoneNumber:    user.PhoneNumber,
		}
	}
	// TODO: support authority account type

	if err != nil {
		s.logger.Error("failed to retrieve authorized user info from db", "account_id", session.AccountID, "error", err)
		return nil, errInternal
	}

	resp := &desc.GetSessionUserResponse{}
	if businessUser != nil {
		resp.User = &desc.GetSessionUserResponse_Business{Business: businessUser}
	}

	return resp, nil
}

func (s *Service) constructSession(operation string, accountID int64, accountType storage.AccountType) *desc.SessionToken {
	token, err := s.authorizer.Construct(Session{AccountID: accountID, AccountType: storage.AccountTypeBusiness})
	if err != nil {
		s.logger.Error("failed to construct user token", "operation", operation, "account_id", accountID, "error", err)
		return nil
	}

	return &desc.SessionToken{Token: token}
}

func (s *Service) authorizeSession(ctx context.Context, accountType ...storage.AccountType) (Session, bool) {
	session := auth.ClaimsFromCtx[Session](ctx)
	if session == (Session{}) {
		return Session{}, false
	}

	if len(accountType) >= 1 && session.AccountType != accountType[0] {
		return Session{}, false
	}

	exists, err := s.db.CheckAccountExists(ctx, session.AccountID, session.AccountType)
	if err != nil {
		s.logger.Error("failed to check session account in db",
			"account_id", session.AccountID,
			"account_type", session.AccountType,
			"error", err,
		)
		return Session{}, false
	} else if !exists {
		return Session{}, false
	}

	return session, true
}
