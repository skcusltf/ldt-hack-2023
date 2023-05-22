package main

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"ldt-hack/api/internal/app/auth"
	"ldt-hack/api/internal/platform"
	"ldt-hack/api/internal/platform/config"
	"ldt-hack/api/internal/storage"

	"github.com/gin-gonic/gin"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"golang.org/x/exp/slog"
	"google.golang.org/grpc"
	"google.golang.org/grpc/keepalive"
	"google.golang.org/grpc/reflection"
)

const (
	httpHeaderTimeout       = time.Second * 5
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
		return fmt.Errorf("starting gRPC server: %w", err)
	}

	// Initialize HTTP server
	httpAddr := viper.GetString(config.HTTPAddr)
	httpServer, httpCh := startHTTP(httpAddr,
		platform.HealthHandler(db.Ping),
	)

	logger.Info(
		"all components initialized and started",
		"grpc_addr", grpcAddr,
		"http_addr", httpAddr,
	)

	// Listen for shutdown signals
	exitCh := make(chan os.Signal, 1)
	signal.Notify(exitCh, os.Interrupt, syscall.SIGTERM)

	select {
	case err := <-grpcCh:
		logger.Error("critical error while serving gRPC, will perform shutdown", "error", err)
	case err := <-httpCh:
		logger.Error("critical error while serving HTTP, will perform shutdown", "error", err)
	case <-exitCh:
		logger.Info("gracefully shutting down all components", "timeout", gracefulShutdownTimeout.String())
	}

	// Launch graceful shutdowns and wait for some time
	var shutdownWg sync.WaitGroup

	shutdownWg.Add(1)
	go func() {
		defer shutdownWg.Done()
		grpcServer.GracefulStop()
	}()

	shutdownWg.Add(1)
	go func() {
		defer shutdownWg.Done()

		ctx, cancel := context.WithTimeout(context.Background(), gracefulShutdownTimeout)
		defer cancel()

		_ = httpServer.Shutdown(ctx)
	}()

	shutdownDone := make(chan struct{})
	go func() {
		shutdownWg.Wait()
		close(shutdownDone)
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

	return server, ch, nil
}

func startHTTP(addr string, health http.Handler) (*http.Server, chan error) {
	gin.SetMode(gin.ReleaseMode)
	engine := gin.New()

	engine.GET("/health", gin.WrapH(health))

	server := &http.Server{
		Addr:              addr,
		Handler:           engine,
		ReadHeaderTimeout: httpHeaderTimeout,
		IdleTimeout:       maxConnectionIdle,
	}

	ch := make(chan error)
	go func() {
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			ch <- err
		} else {
			ch <- nil
		}
		close(ch)
	}()

	return server, ch
}
