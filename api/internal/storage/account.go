package storage

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/uptrace/bun"
)

type Account struct {
	bun.BaseModel `bun:"table:account,alias:a"`

	ID           int64       `bun:",pk,type:bigserial,autoincrement"`
	Type         AccountType `bun:"type:account_type,notnull"`
	Email        string      `bun:"type:text,notnull"`
	PasswordHash []byte      `bun:"type:bytea,notnull"`
}

// CheckAccountExists returns true if an account with the given ID and type exists.
func (db *Database) CheckAccountExists(ctx context.Context, accountID int64, accountType AccountType) (bool, error) {
	exists, err := db.bun.NewSelect().Model((*Account)(nil)).
		Where("id = ?", accountID).Where("type = ?", accountType).Exists(ctx)
	if err != nil {
		return false, wrapError("CheckAccountExists", err)
	}

	return exists, nil
}

// GetAccount returns the account with the specified email and type
func (db *Database) GetAccount(ctx context.Context, email string, accountType AccountType) (Account, error) {
	var account Account
	err := db.bun.NewSelect().Model(&account).Where("email = ?", email).Where("type = ?", accountType).Scan(ctx)
	if err != nil {
		return Account{}, wrapError("GetAccountPasswordHash", err)
	}

	return account, nil
}

// DeleteAccount deletes the account and removes the reference to it from other tables.
// Information about the actual users isn't deleted so that inspectors/users can view info
// about the previous consultations even if the user is now gone.
func (db *Database) DeleteAccount(ctx context.Context, accountID int64) error {
	err := db.bun.RunInTx(ctx, &sql.TxOptions{ReadOnly: false}, func(ctx context.Context, tx bun.Tx) error {
		_, err := tx.NewUpdate().Model((*BusinessUser)(nil)).
			Where("account_id  = ?", accountID).Set("account_id = ?", nil).Returning("").Exec(ctx)
		if err != nil {
			return wrapError("DeleteAccount.BusinessUser", err)
		}

		_, err = tx.NewDelete().Model((*Account)(nil)).
			Where("id = ?", accountID).Returning("").Exec(ctx)
		if err != nil {
			return wrapError("DeleteAccount.Account", err)
		}

		return nil
	})
	if err != nil {
		return fmt.Errorf("executing transaction: %w", err)
	}

	return nil
}
