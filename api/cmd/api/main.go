package main

import (
	"context"
	"fmt"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"ldt-hack/api/internal/app/auth"
	"ldt-hack/api/internal/platform"
	"ldt-hack/api/internal/platform/config"
	"ldt-hack/api/internal/storage"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"golang.org/x/exp/slog"
	"google.golang.org/grpc"
	"google.golang.org/grpc/keepalive"
	"google.golang.org/grpc/reflection"
)

const (
	maxConnectionIdle       = time.Minute
	gracefulShutdownTimeout = time.Second * 5
)

var rootCmd = &cobra.Command{
	Use:           "ldt-api",
	SilenceErrors: true,
	SilenceUsage:  true,
	RunE: func(cmd *cobra.Command, _ []string) error {
		platform.Init()
		logger := platform.NewLogger(viper.GetString(config.LogLevel))

		return runAPI(cmd.Context(), logger)
	},
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		platform.NewLogger("").Error("executing root command: %v", err)
	}
}

func runAPI(ctx context.Context, logger *slog.Logger) error {
	// Initialize database
	db, err := storage.Open(ctx, viper.GetString(config.PostgresDSN))
	if err != nil {
		return fmt.Errorf("opening storage: %w", err)
	}

	// Initialize gRPC services
	authService := auth.NewService(logger, db)

	// Initialize actual gRPC server
	grpcAddr := viper.GetString(config.GRPCAddr)
	grpcServer, grpcCh, err := startGRPC(grpcAddr, authService)
	if err != nil {
		return err
	}

	logger.Info(
		"all components initialized and started",
		"grpc_addr", grpcAddr,
	)

	// Listen for shutdown signals
	exitCh := make(chan os.Signal, 1)
	signal.Notify(exitCh, os.Interrupt, syscall.SIGTERM)

	select {
	case err := <-grpcCh:
		logger.Error("critical error while serving gRPC, will perform shutdown", "error", err)
	case <-exitCh:
		logger.Info("gracefully shutting down all components", "timeout", gracefulShutdownTimeout.String())
	}

	// Launch graceful shutdowns and wait for some time
	shutdownDone := make(chan struct{})
	go func() {
		defer close(shutdownDone)
		grpcServer.GracefulStop()
	}()

	select {
	case <-shutdownDone:
	case <-time.After(gracefulShutdownTimeout):
	}

	// Now, actually force the shutdown
	grpcServer.Stop()
	<-grpcCh
	<-shutdownDone

	return nil
}

func startGRPC(addr string, authService *auth.Service) (*grpc.Server, chan error, error) {
	listener, err := net.Listen("tcp", addr)
	if err != nil {
		return nil, nil, fmt.Errorf("listening on bind address %q: %w", addr, err)
	}

	// Basic gRPC server with limited idle
	server := grpc.NewServer(
		grpc.KeepaliveParams(keepalive.ServerParameters{MaxConnectionIdle: maxConnectionIdle}),
	)
	reflection.Register(server)
	authService.RegisterServer(server)

	// Setup error channel and run server
	ch := make(chan error)
	go func() {
		ch <- server.Serve(listener)
		close(ch)
	}()

	return server, ch, err
}
