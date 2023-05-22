package storage

import "fmt"

func wrapError(query string, err error) error {
	if err == nil {
		return nil
	}

	return fmt.Errorf("executing %s query: %w", query, err)
}
