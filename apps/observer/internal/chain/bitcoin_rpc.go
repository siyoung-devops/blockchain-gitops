package chain

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"observer/internal/metrics"
)

const rpcTimeout = 5 * time.Second

func CheckBitcoinRPC(rpcURL, rpcUser, rpcPassword string) {
	start := time.Now()

	payload := map[string]interface{}{
		"jsonrpc": "1.0",
		"id":      "observer",
		"method":  "getblockchaininfo",
		"params":  []interface{}{},
	}

	body, err := json.Marshal(payload)
	if err != nil {
		metrics.BitcoinRPCUp.Set(0)
		metrics.BitcoinRPCErrors.Inc()
		log.Println("Bitcoin RPC failed to marshal payload:", err)
		return
	}

	req, err := http.NewRequest("POST", rpcURL, bytes.NewBuffer(body))
	if err != nil {
		metrics.BitcoinRPCUp.Set(0)
		metrics.BitcoinRPCErrors.Inc()
		log.Println("Bitcoin RPC failed to create request:", err)
		return
	}

	req.SetBasicAuth(rpcUser, rpcPassword)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: rpcTimeout}
	resp, err := client.Do(req)

	// 1. RPC - 응답 성공/실패와 상관없이 지연시간 기록
	metrics.BitcoinRPCLatency.Observe(time.Since(start).Seconds())

	if err != nil {
		metrics.BitcoinRPCUp.Set(0)
		metrics.BitcoinRPCErrors.Inc()
		log.Println("Bitcoin RPC request failed:", err)
		return
	}
	defer resp.Body.Close()

	// 2. RPC - "요청이 닿았는지" 기준으로 UP 처리
	metrics.BitcoinRPCUp.Set(1)

	// 3. RPC - 200이 아니면 에러율만 증가
	if resp.StatusCode != http.StatusOK {
		metrics.BitcoinRPCErrors.Inc()
		log.Println("Bitcoin RPC returned non-200:", resp.StatusCode)
	}
}
