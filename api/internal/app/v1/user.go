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
	"google.golang.org/protobuf/types/known/emptypb"
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

// CreateBusinessUser implements the business user creation endpoint.
func (s *Service) CreateBusinessUser(ctx context.Context, req *desc.CreateBusinessUserRequest) (*desc.SessionToken, error) {
	if !govalidator.IsEmail(req.Email) {
		return nil, errCreateInvalidEmail
	} else if len(req.Password) < minPasswordLen || len(req.Password) > maxPasswordLen {
		return nil, errCreateInvalidPassword
	} else if err := validateBusinessUserFields(req.User); err != nil {
		return nil, err
	}

	passwordHash, err := crypto.HashPassword(req.Password)
	if err != nil {
		s.logger.Error("failed to hash password", "error", err)
		return nil, errInternal
	}

	storageUser := businessUserToStorage(req.User)
	accountID, err := s.db.CreateBusinessUser(ctx, req.Email, passwordHash, storageUser)
	if errors.Is(err, storage.ErrAlreadyExists) {
		return nil, errCreateEmailTaken
	} else if err != nil {
		s.logger.Error("failed to create business user in db", "email", req.Email, "business_user", storageUser, "error", err)
		return nil, errInternal
	}

	session := s.constructSession("creation", accountID, storage.AccountTypeBusiness)
	if session == nil {
		return nil, errInternal
	}

	return session, nil
}

// UpdateBusinessUser implements the endpoint for updating a business user's information.
func (s *Service) UpdateBusinessUser(ctx context.Context, req *desc.UpdateBusinessUserRequest) (*emptypb.Empty, error) {
	session, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness)
	if !authorized {
		return nil, errUnauthorized
	}

	if err := validateBusinessUserFields(req.User); err != nil {
		return nil, err
	}

	storageUser := businessUserToStorage(req.User)
	storageUser.AccountID = session.AccountID

	if err := s.db.UpdateBusinessUser(ctx, storageUser); err != nil {
		s.logger.Error("failed to update business user in db", "user", storageUser, "error", err)
		return nil, errInternal
	}

	return &emptypb.Empty{}, nil
}

// DeleteBusinessUser implements the endpoint for deleting a business user's account.
func (s *Service) DeleteBusinessUser(ctx context.Context, _ *emptypb.Empty) (*emptypb.Empty, error) {
	session, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness)
	if !authorized {
		return nil, errUnauthorized
	}

	if err := s.db.DeleteAccount(ctx, session.AccountID); err != nil {
		s.logger.Error("failed to delete business user's account", "account_id", session.AccountID, "error", err)
		return nil, errInternal
	}

	return &emptypb.Empty{}, nil
}

func validateBusinessUserFields(user *desc.BusinessUser) error {
	if user == nil ||
		user.FirstName == "" ||
		user.LastName == "" ||
		!user.BirthDate.IsValid() ||
		user.BusinessName == "" {
		return errMissingFields
	}

	if _, ok := personSexToStorage[user.Sex]; !ok {
		return errUserUnknownSex
	}

	return nil
}

func businessUserToStorage(user *desc.BusinessUser) storage.BusinessUser {
	return storage.BusinessUser{
		FirstName:      user.FirstName,
		PatronymicName: user.PatronymicName,
		LastName:       user.LastName,
		Sex:            personSexToStorage[user.Sex],
		BirthDate:      user.BirthDate.AsTime(),
		BusinessName:   user.BusinessName,
	}
}
