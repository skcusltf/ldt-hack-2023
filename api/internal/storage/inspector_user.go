package storage

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/uptrace/bun"
)

type InspectorUser struct {
	bun.BaseModel `bun:"table:inspector_user,alias:iu"`

	ID          int64     `bun:",pk,type:bigserial,autoincrement"`
	AccountID   int64     `bun:"type:bigint"`
	AuthorityID int64     `bun:"type:bigint"`
	Authority   Authority `bun:"rel:belongs-to,join:authority_id=id"`
	FirstName   string    `bun:"type:text,notnull"`
	LastName    string    `bun:"type:text,notnull"`
}

// CreateInspectorUser creates a new inspector user account and returns the created account's id.
func (db *Database) CreateInspectorUser(ctx context.Context, email string, passwordHash []byte, user InspectorUser) error {
	account := Account{
		Type:         AccountTypeAuthority,
		Email:        email,
		PasswordHash: passwordHash,
	}

	err := db.bun.RunInTx(ctx, &sql.TxOptions{ReadOnly: false}, func(ctx context.Context, tx bun.Tx) error {
		_, err := tx.NewInsert().Model(&account).Returning("id").Exec(ctx)
		if err != nil {
			return wrapError("CreateInspectorUser.Account", err)
		}

		user.AccountID = account.ID
		_, err = tx.NewInsert().Model(&user).Returning("").Exec(ctx)
		if err != nil {
			return wrapError("CreateInspectorUser.User", err)
		}

		return nil
	})
	if err != nil {
		return fmt.Errorf("executing transaction: %w", err)
	}

	return nil
}

// GetInspectorUser gets the inspector user's information by account ID.
func (db *Database) GetInspectorUser(ctx context.Context, accountID int64) (InspectorUser, error) {
	var user InspectorUser
	err := db.bun.NewSelect().Model(&user).Relation("Authority").Where("account_id = ?", accountID).Scan(ctx)
	if err != nil {
		return InspectorUser{}, wrapError("GetInspectorUser", err)
	}

	return user, nil
}
