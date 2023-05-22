package storage

import (
	"context"
	"fmt"

	"github.com/georgysavva/scany/v2/pgxscan"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Database struct {
	pool *pgxpool.Pool
}

// Open connects to a database using the specified DSN.
func Open(ctx context.Context, dsn string) (*Database, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, fmt.Errorf("connecting to database: %w", err)
	}

	return &Database{pool}, nil
}

// Close closes an active database.
func (db *Database) Close() {
	db.pool.Close()
}

// Ping pings the database. Used for healthchecks.
func (db *Database) Ping(ctx context.Context) error {
	if err := db.pool.Ping(ctx); err != nil {
		return fmt.Errorf("ping failed: %w", err)
	}

	return nil
}

func (db *Database) Select(ctx context.Context) (string, error) {
	const query = `select 'hello from postgres'`

	var s string
	if err := pgxscan.Get(ctx, db.pool, &s, query); err != nil {
		return "", wrapError("Select", err)
	}

	return s, nil
}
