package app

import (
	"context"
	"fmt"

	"ldt-hack/api/internal/storage"
)

// Session is the struct which is encoded in a user's session
type Session struct {
	AccountID   int64               `json:"account_id"`
	AccountType storage.AccountType `json:"account_type"`
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
