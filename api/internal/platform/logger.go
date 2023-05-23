package platform

import (
	"os"

	"golang.org/x/exp/slog"
)

// NewLogger creates a new slog logger. Levels "info" and "debug" are supported.
func NewLogger(level string) *slog.Logger {
	constantLevel := new(slog.LevelVar)
	constantLevel.Set(slog.LevelInfo)
	if level == "debug" {
		constantLevel.Set(slog.LevelDebug)
	}

	return slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
		Level: constantLevel,
	}))
}
