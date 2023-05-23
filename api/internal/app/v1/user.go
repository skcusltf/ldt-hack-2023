package app

import (
	"context"
	"errors"

	"ldt-hack/api/internal/crypto"
	desc "ldt-hack/api/internal/pb/app/v1"
	"ldt-hack/api/internal/storage"

	"github.com/asaskevich/govalidator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	minPasswordLen = 3
	maxPasswordLen = 50
)

var (
	errCreateInvalidEmail    = status.Error(codes.InvalidArgument, "Укажите корректный почтовый адрес")
	errCreateInvalidPassword = status.Error(codes.InvalidArgument, "Пароль должен быть длиной от 3 до 50 символов")
	errCreateEmailTaken      = status.Error(codes.AlreadyExists, "Указанный почтовый адрес уже используется, попробуйте с ним войти")
	errUserUnknownSex        = status.Error(codes.InvalidArgument, "Указан неизвестный пол")
)

func (s *Service) CreateBusinessUser(ctx context.Context, req *desc.CreateBusinessUserRequest) (*desc.SessionToken, error) {
	if !govalidator.IsEmail(req.Email) {
		return nil, errCreateInvalidEmail
	} else if len(req.Password) < minPasswordLen || len(req.Password) > maxPasswordLen {
		return nil, errCreateInvalidPassword
	}

	if req.User == nil ||
		req.User.FirstName == "" ||
		req.User.LastName == "" ||
		!req.User.BirthDate.IsValid() ||
		req.User.BusinessName == "" {
		return nil, errMissingFields
	}

	personSex, ok := personSexToStorage[req.User.Sex]
	if !ok {
		return nil, errUserUnknownSex
	}

	passwordHash, err := crypto.HashPassword(req.Password)
	if err != nil {
		s.logger.Error("failed to hash password", "error", err)
		return nil, errInternal
	}

	storageUser := storage.BusinessUser{
		FirstName:      req.User.FirstName,
		PatronymicName: req.User.PatronymicName,
		LastName:       req.User.LastName,
		Sex:            personSex,
		BirthDate:      req.User.BirthDate.AsTime(),
		BusinessName:   req.User.BusinessName,
	}
	accountID, err := s.db.CreateBusinessUser(ctx, req.Email, passwordHash, storageUser)
	if errors.Is(err, storage.ErrAlreadyExists) {
		return nil, errCreateEmailTaken
	} else if err != nil {
		s.logger.Error("failed to create business user in db", "email", req.Email, "business_user", storageUser, "error", err)
		return nil, errInternal
	}

	token, err := s.authorizer.Construct(Session{AccountID: accountID, AccountType: storage.AccountTypeBusiness})
	if err != nil {
		s.logger.Error("failed to construct user token after account creation", "account_id", accountID, "error", err)
		return nil, errInternal
	}

	return &desc.SessionToken{Token: token}, nil
}
