package config

DEFAULT_INTERVAL_SEC = 10

import (
	"log"
	"os"
)

type Config struct {
	BitcoinRPCURL 		string // 비트코인 RPC 주소
	BitcoinRPCUser 		string // RPC 인증 유저
	BitcoinRPCPassword 	string // RPC 인증 비밀번호
	MetricsAddr 		string // Prometheus metrics 노출 주소
	IntervalSec 		int    // 관측 주기
}


func LoadConfig() *Config {
	// RPC URL
	rpcURL := os.Getenv("BITCOIN_RPC_URL")
	if rpcURL == "" {
		log.Fatal("BITCOIN_RPC_URL is not set")
	}

	// RPC 유저명
	rpcUser := os.Getenv("BITCOIN_RPC_USER")
	if rpcUser == "" {
		log.Fatal("BITCOIN_RPC_USER is not set")
	}

	// RPC 비밀번호
	rpcPassword := os.Getenv("BITCOIN_RPC_PASSWORD")
	if rpcPassword == "" {
		log.Fatal("BITCOIN_RPC_PASSWORD is not set")
	}

	// metrics 서버 주소
	metricsAddr := os.Getenv("METRICS_ADDR")
	if metricsAddr == "" {
		metricsAddr = ":9100" // 기본 포트 9100, 추후 변경
	}

	interval := DEFAULT_INTERVAL_SEC

	return &Config{
		BitcoinRPCURL:  rpcURL,
		BitcoinRPCUser: rpcUser,
		BitcoinRPCPassword: rpcPassword,
		MetricsAddr:    metricsAddr,
		IntervalSec:    interval,
	}
}