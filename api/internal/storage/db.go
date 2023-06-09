package storage

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/uptrace/bun"
	"github.com/uptrace/bun/dialect/pgdialect"
	"github.com/uptrace/bun/driver/pgdriver"
)

const maxOpenConns = 16

type Database struct {
	bun *bun.DB
}

// Open connects to a database using the specified DSN.
func Open(ctx context.Context, dsn string) (*Database, error) {
	sqldb := sql.OpenDB(pgdriver.NewConnector(pgdriver.WithDSN(dsn)))
	sqldb.SetMaxOpenConns(maxOpenConns)
	sqldb.SetMaxIdleConns(maxOpenConns)

	bundb := bun.NewDB(sqldb, pgdialect.New(), bun.WithDiscardUnknownColumns())
	// bundb.AddQueryHook(bundebug.NewQueryHook(bundebug.WithVerbose(true)))

	db := &Database{bundb}
	if err := db.Ping(ctx); err != nil {
		return nil, err
	}

	return db, nil
}

// Close closes an active database.
func (db *Database) Close() error {
	if err := db.bun.Close(); err != nil {
		return fmt.Errorf("closing database: %w", err)
	}

	return nil
}

// Ping pings the database. Used for healthchecks.
func (db *Database) Ping(ctx context.Context) error {
	if err := db.bun.PingContext(ctx); err != nil {
		return fmt.Errorf("ping failed: %w", err)
	}

	return nil
}

// WithTx runs the specified function in a new transaction.
func (db *Database) WithTx(ctx context.Context, readOnly bool, f func(ctx context.Context, tx bun.Tx) error) error {
	return db.bun.RunInTx(ctx, &sql.TxOptions{ReadOnly: readOnly}, f)
}
