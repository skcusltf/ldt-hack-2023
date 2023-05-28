package storage

import (
	"context"
	"time"

	"github.com/uptrace/bun"
)

type ConsultationTopic struct {
	bun.BaseModel `bun:"table:authority_consultation_topic"`

	ID          int64     `bun:",pk,type:bigserial,autoincrement"`
	AuthorityID int64     `bun:"type:bigint"`
	Authority   Authority `bun:"rel:belongs-to,join:authority_id=id"`
	Name        string    `bun:"type:text,notnull"`
}

type ConsultationSlot struct {
	bun.BaseModel `bun:"table:authority_consultation_slots"`

	ID          int64     `bun:",pk,type:bigserial,autoincrement"`
	AuthorityID int64     `bun:"type:bigint"`
	Authority   Authority `bun:"rel:belongs-to,join:authority_id=id"`
	FromTime    time.Time `bun:"type:timestamptz,notnull"`
	ToTime      time.Time `bun:"type:timestamptz,notnull"`
}

// CreateTopicsTx creates topics which don't exist yet and returns all of the topics in the DB.
func (db *Database) CreateTopicsTx(ctx context.Context, tx bun.Tx, topics []ConsultationTopic) error {
	// Insert new ones
	if _, err := tx.NewInsert().Model(&topics).On("conflict do nothing").Exec(ctx); err != nil {
		return wrapError("CreateTopicsTx.Insert", err)
	}

	return nil
}

// CreateSlotsTx creates consultation slots which don't exist yet.
func (db *Database) CreateSlotsTx(ctx context.Context, tx bun.Tx, slots []ConsultationSlot) error {
	if _, err := tx.NewInsert().Model(&slots).On("conflict do nothing").Exec(ctx); err != nil {
		return wrapError("CreateSlotsTx", err)
	}

	return nil
}

// ListConsultationTopics returns a list of all of the consultation topics.
func (db *Database) ListConsultationTopics(ctx context.Context) ([]ConsultationTopic, error) {
	var topics []ConsultationTopic

	if err := db.bun.NewSelect().Model(&topics).Relation("Authority").Scan(ctx); err != nil {
		return nil, wrapError("ListConsultationTopics", err)
	}

	return topics, nil
}
