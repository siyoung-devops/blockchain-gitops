package metrics

import "github.com/prometheus/client_golang/prometheus"

// 비트코인 살아있는지 체크 (1 = 정상, 0 = 장애)
var BitcoinRPCUp = prometheus.NewGauge(
	prometheus.GaugeOpts{
		Namespace: "blockchain",
		Subsystem: "bitcoin",
		Name:      "bitcoin_rpc_up",
		Help:      "Bitcoin RPC health status (1 = up, 0 = down)",
	},
)

// RPC 응답 지연 시간
var BitcoinRPCLatency = prometheus.NewHistogram(
	prometheus.HistogramOpts{
		Namespace: "blockchain",
		Subsystem: "bitcoin",
		Name:      "bitcoin_rpc_latency_seconds",
		Help:      "Latency of Bitcoin RPC requests",
		Buckets:   prometheus.DefBuckets,
	},
)

// RPC 에러 횟수
var BitcoinRPCErrors = prometheus.NewCounter(
	prometheus.CounterOpts{
		Namespace: "blockchain",
		Subsystem: "bitcoin",
		Name:      "bitcoin_rpc_errors_total",
		Help:      "Total number of Bitcoin RPC errors",
	},
)
