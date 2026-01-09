package main

import (
	"log"
	"net/http"
	"time"

	"observer/internal/chain"
	"observer/internal/config"
	"observer/internal/metrics"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	// 1. 환경 변수 로딩
	cfg := config.LoadConfig()

	// 2. Prometheus 메트릭 등록
	prometheus.MustRegister(metrics.BitcoinRPCUp)
	prometheus.MustRegister(metrics.BitcoinRPCLatency)
	prometheus.MustRegister(metrics.BitcoinRPCErrors)

	// 3. 주기적으로 관측! 
	go func() {
		for {
			chain.CheckBitcoinRPC(
				cfg.BitcoinRPCURL, 
				cfg.BitcoinRPCUser, 
				cfg.BitcoinRPCPassword,
			)

			chain.CheckExternalBitcoinAPI() // 외부 기준 API 확인

			// 주기마다 한 번 상태를 수집
			// 추후 ticker로 변경 고려 
			time.Sleep(time.Duration(cfg.IntervalSec) * time.Second) 
		}	
	}()

	// 4. Prometheus가 긁어갈 endpoint 제공
	http.Handle("/metrics", promhttp.Handler())

	log.Println("Bitcoin Observer running on", cfg.MetricsAddr)
	
	// 5. 서버 실행
	log.Fatal(http.ListenAndServe(cfg.MetricsAddr, nil))
}