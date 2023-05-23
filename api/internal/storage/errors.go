package storage

import (
	"database/sql"
	"errors"
	"fmt"

	"github.com/jackc/pgerrcode"
	"github.com/uptrace/bun/driver/pgdriver"
)

var (
	ErrAlreadyExists = errors.New("entity already exists")
	ErrNotFound      = errors.New("entity not found")
)

func wrapError(query string, err error) error {
	if err == nil {
		return nil
	}

	var pgerr pgdriver.Error
	if errors.As(err, &pgerr) && pgerr.Field('C') == pgerrcode.UniqueViolation {
		return ErrAlreadyExists
	} else if errors.Is(err, sql.ErrNoRows) {
		return ErrNotFound
	}

	return fmt.Errorf("executing %s query: %w", query, err)
}
