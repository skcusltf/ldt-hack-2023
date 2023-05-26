package config

import (
	"strings"

	"github.com/spf13/viper"
)

const (
	// DSN connection string to the Postgres database
	PostgresDSN = "postgres.dsn"
	// Path to private key PEM file
	JWTPath = "jwt.path"
	// Bind address for the gRPC server
	GRPCAddr = "grpc.addr"
	// Bind address for the HTTP server
	HTTPAddr = "http.addr"
	// Log level to use for initializing the logger
	LogLevel = "log.level"
	// Admin username:password pair
	AdminUserPass = "admin.userpass"
)

const (
	defaultGRPCAddr = ":9081"
	defaultHTTPAddr = ":9080"
	defaultJWTPath  = "/var/run/secrets/jwt.pem"
)

// Init initializes the default values for the config and various other viper settings.
func Init() {
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	viper.SetDefault(GRPCAddr, defaultGRPCAddr)
	viper.SetDefault(HTTPAddr, defaultHTTPAddr)
	viper.SetDefault(JWTPath, defaultJWTPath)
}
