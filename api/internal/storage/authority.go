package storage

import (
	"context"
	"time"

	"github.com/samber/lo"
	"github.com/uptrace/bun"
)

type Authority struct {
	bun.BaseModel `bun:"table:authority"`

	ID   int64  `bun:",pk,type:bigserial,autoincrement"`
	Name string `bun:"type:text,notnull"`
}

type ConsultationTopic struct {
	bun.BaseModel `bun:"table:authority_consultation_topic"`

	ID          int64  `bun:",pk,type:bigserial,autoincrement"`
	AuthorityID int64  `bun:"type:bigint"`
	Name        string `bun:"type:text,notnull"`
}

type ConsultationSlot struct {
	bun.BaseModel `bun:"table:authority_consultation_slots"`

	ID          int64     `bun:",pk,type:bigserial,autoincrement"`
	AuthorityID int64     `bun:"type:bigint"`
	FromTime    time.Time `bun:"type:timestamptz,notnull"`
	ToTime      time.Time `bun:"type:timestamptz,notnull"`
}

// ListAuthorities returns a list of the current authorities.
func (db *Database) ListAuthorities(ctx context.Context) ([]Authority, error) {
	var authorities []Authority

	if err := db.bun.NewSelect().Model(&authorities).Scan(ctx); err != nil {
		return nil, wrapError("ListAuthorities", err)
	}

	return authorities, nil
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

// CreateTopicsTx creates topics which don't exist yet and returns all of the topics in the DB.
func (db *Database) CreateTopicsTx(ctx context.Context, tx bun.Tx, topics []ConsultationTopic) error {
	// Insert new ones
	_, err := tx.NewInsert().Model(&topics).On("conflict do nothing").Exec(ctx)
	if err != nil {
		return wrapError("CreateTopicsTx.Insert", err)
	}

	return err
}

// CreateSlotsTx creates consultation slots which don't exist yet.
func (db *Database) CreateSlotsTx(ctx context.Context, tx bun.Tx, slots []ConsultationSlot) error {
	_, err := tx.NewInsert().Model(&slots).On("conflict do nothing").Exec(ctx)
	if err != nil {
		return wrapError("CreateSlotsTx", err)
	}

	return nil
}
