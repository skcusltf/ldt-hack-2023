package storage

import (
	"context"

	"github.com/uptrace/bun"
)

type ChatMessage struct {
	bun.BaseModel `bun:"table:chat_message"`

	ID       int64    `bun:",pk,type:bigserial,autoincrement"`
	Request  string   `bun:"type:text,notnull"`
	Response []string `bun:"type:text[],notnull"`
	Rating   *bool    `bun:"type:boolean"`
}

// CreateChatMessage creates a chat message entry and returns its ID.
// Currently chat messages aren't bound to specific users, and are stored only on the client side.
func (db *Database) CreateChatMessage(ctx context.Context, request string, response []string) (int64, error) {
	message := ChatMessage{
		Request:  request,
		Response: response,
	}

	if _, err := db.bun.NewInsert().Model(&message).Exec(ctx); err != nil {
		return 0, wrapError("CreateChatMessage", err)
	}
	return message.ID, nil
}

// UpdateChatMessageRating updates a chat message's rating. If rating is nil, this practically means
// that the rating is removed from the DB.
func (db *Database) UpdateChatMessageRating(ctx context.Context, id int64, rating *bool) error {
	_, err := db.bun.NewUpdate().Model((*ChatMessage)(nil)).
		Set("rating = ?", rating).
		Where("id = ?", id).
		Exec(ctx)
	if err != nil {
		return wrapError("UpdateChatMessageRating", err)
	}

	return nil
}
