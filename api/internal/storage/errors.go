package storage

import (
	"errors"
	"fmt"

	"github.com/jackc/pgerrcode"
	"github.com/uptrace/bun/driver/pgdriver"
)

var ErrAlreadyExists = errors.New("entity already exists")

func wrapError(query string, err error) error {
	if err == nil {
		return nil
	}

	var pgerr pgdriver.Error
	if errors.As(err, &pgerr) && pgerr.Field('C') == pgerrcode.UniqueViolation {
		return ErrAlreadyExists
	}

	return fmt.Errorf("executing %s query: %w", query, err)
}
