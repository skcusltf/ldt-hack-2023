package storage

import (
	"context"

	"github.com/samber/lo"
	"github.com/uptrace/bun"
)

type Authority struct {
	bun.BaseModel `bun:"table:authority"`

	ID   int64  `bun:",pk,type:bigserial,autoincrement"`
	Name string `bun:"type:text,notnull"`
}

// CreateAuthoritiesTx creates authorities which don't exist yet and returns all of the authorities in the DB.
func (db *Database) CreateAuthoritiesTx(ctx context.Context, tx bun.Tx, names []string) ([]Authority, error) {
	authorities := lo.Map(names, func(s string, _ int) Authority {
		return Authority{Name: s}
	})

	// Insert new ones
	_, err := tx.NewInsert().Model(&authorities).On("conflict do nothing").Exec(ctx)
	if err != nil {
		return nil, wrapError("CreateAuthoritiesTx.Insert", err)
	}

	// Select all
	authorities = authorities[:0]
	if err := tx.NewSelect().Model(&authorities).Scan(ctx); err != nil {
		return nil, wrapError("CreateAuthoritiesTx.Select", err)
	}

	return authorities, nil
}

// ListAuthorities returns a list of the current authorities.
func (db *Database) ListAuthorities(ctx context.Context) ([]Authority, error) {
	var authorities []Authority

	if err := db.bun.NewSelect().Model(&authorities).Scan(ctx); err != nil {
		return nil, wrapError("ListAuthorities", err)
	}

	return authorities, nil
}
