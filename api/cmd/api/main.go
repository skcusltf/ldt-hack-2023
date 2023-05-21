package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"
)

func main() {
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("hi lol"))
	})

	server := http.Server{
		Addr:    ":9080",
		Handler: handler,
	}

	var wg sync.WaitGroup
	wg.Add(1)

	httpCh := make(chan error)
	go func() {
		defer wg.Done()
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			httpCh <- err
		}
	}()

	exitCh := make(chan os.Signal, 1)
	signal.Notify(exitCh, os.Interrupt, syscall.SIGTERM)

	select {
	case err := <-httpCh:
		log.Fatal("http error", err)
	case <-exitCh:
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), time.Second*5)
	defer cancel()

	server.Shutdown(shutdownCtx)

	wg.Wait()
}
