package config

import (
	"strings"

	"github.com/spf13/viper"
)

const (
	// DSN connection string to the Postgres database
	PostgresDSN = "postgres.dsn"

	// Bind address for the gRPC server
	GRPCAddr = "grpc.addr"

	// Log level to use for initializing the logger
	LogLevel = "log.level"
)

const (
	defaultGRPCAddr = ":9081"
)

// Init initializes the default values for the config and various other viper settings.
func Init() {
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	viper.SetDefault(GRPCAddr, defaultGRPCAddr)
}
