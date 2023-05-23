package storage

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/uptrace/bun"
)

type BusinessUser struct {
	bun.BaseModel `bun:"table:business_user,alias:bu"`

	ID             int64     `bun:",pk,type:bigserial,autoincrement"`
	AccountID      int64     `bun:"type:bigint"`
	FirstName      string    `bun:"type:text,notnull"`
	PatronymicName string    `bun:"type:text,notnull"`
	LastName       string    `bun:"type:text,notnull"`
	Sex            PersonSex `bun:"type:person_sex,notnull"`
	BirthDate      time.Time `bun:"type:date,notnull"`
	BusinessName   string    `bun:"type:text,notnull"`
}

// CreateBusinessUser creates a new business user account and returns the created account's id.
func (db *Database) CreateBusinessUser(ctx context.Context, email string, passwordHash []byte, user BusinessUser) (int64, error) {
	account := Account{
		Type:         AccountTypeBusiness,
		Email:        email,
		PasswordHash: passwordHash,
	}

	err := db.bun.RunInTx(ctx, &sql.TxOptions{ReadOnly: false}, func(ctx context.Context, tx bun.Tx) error {
		_, err := tx.NewInsert().Model(&account).Returning("id").Exec(ctx)
		if err != nil {
			return wrapError("CreateBusinessUser.Account", err)
		}

		user.AccountID = account.ID
		_, err = tx.NewInsert().Model(&user).Returning("").Exec(ctx)
		if err != nil {
			return wrapError("CreateBusinessUser.User", err)
		}

		return nil
	})
	if err != nil {
		return 0, fmt.Errorf("executing transaction: %w", err)
	}

	return account.ID, nil
}

// GetBusinessUser gets the business user's information by account ID.
func (db *Database) GetBusinessUser(ctx context.Context, accountID int64) (BusinessUser, error) {
	var user BusinessUser
	err := db.bun.NewSelect().Model(&user).Where("account_id = ?", accountID).Scan(ctx)
	if err != nil {
		return BusinessUser{}, wrapError("GetBusinessUser", err)
	}

	return user, nil
}

// UpdateBusinessUser updates all of the information of a business user.
func (db *Database) UpdateBusinessUser(ctx context.Context, user BusinessUser) error {
	_, err := db.bun.NewUpdate().Model(&user).OmitZero().Where("account_id = ?", user.AccountID).Returning("").Exec(ctx)
	if err != nil {
		return wrapError("UpdateBusinessUser", err)
	}

	return nil
}
