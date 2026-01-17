package main

import (
	"log"
	"net/http"
	"time"

	"observer/internal/chain"
	"observer/internal/config"
	"observer/internal/metrics"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	// 1. 환경 변수 로딩
	cfg := config.LoadConfig()

	// 2. Prometheus 메트릭 등록
	metrics.RegisterMetrics() 

	// 3. 주기적으로 관측 : time.Sleep대신 ticker()로 
	ticker := time.NewTicker(time.Duration(cfg.IntervalSec) * time.Second)
	defer ticker.Stop()

	go func() {
	for range ticker.C {
		chain.CheckBitcoinRPC(cfg.BitcoinRPCURL, cfg.BitcoinRPCUser, cfg.BitcoinRPCPassword)
		chain.CheckExternalBitcoinAPI()
	}
	}()

	// 4. Prometheus가 긁어갈 endpoint 제공
	http.Handle("/metrics", promhttp.Handler())

	log.Println("observer version 0.1.1", cfg.MetricsAddr)
	log.Fatal(http.ListenAndServe(cfg.MetricsAddr, nil))
}