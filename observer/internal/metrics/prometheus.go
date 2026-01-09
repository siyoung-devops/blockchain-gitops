package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
)

// ============================
// Prometheus Metrics 정의
// ============================

// 비트코인 살아있는지 체크 (1 = 정상, 0 = 장애)
var BitcoinRPCUp = prometheus.NewGauge(
	prometheus.GaugeOpts{
		Namespace: "blockchain",
		Subsystem: "bitcoin",
		Name:      "rpc_up",
		Help:      "Bitcoin RPC health status (1 = up, 0 = down)",
	},
)

// 외부 API 블록 높이
var ExternalBlockHeight = prometheus.NewGauge(
	prometheus.GaugeOpts{
		Namespace: "blockchain",
		Subsystem: "external",
		Name:      "block_height",
		Help:      "Block height from external API",
	},
)

// RPC 응답 지연 시간
var BitcoinRPCLatency = prometheus.NewHistogram(
	prometheus.HistogramOpts{
		Namespace: "blockchain",
		Subsystem: "bitcoin",
		Name:      "rpc_latency_seconds",
		Help:      "Latency of Bitcoin RPC requests",
		Buckets:   prometheus.DefBuckets,
	},
)

// RPC 에러 횟수
var BitcoinRPCErrors = prometheus.NewCounter(
	prometheus.CounterOpts{
		Namespace: "blockchain",
		Subsystem: "bitcoin",
		Name:      "rpc_errors_total",
		Help:      "Total number of Bitcoin RPC errors",
	},
)

// ============================
// Metrics 등록 함수
// ============================
func RegisterMetrics() {
	prometheus.MustRegister(BitcoinRPCUp)
	prometheus.MustRegister(ExternalBlockHeight)
	prometheus.MustRegister(BitcoinRPCLatency)
	prometheus.MustRegister(BitcoinRPCErrors)
}