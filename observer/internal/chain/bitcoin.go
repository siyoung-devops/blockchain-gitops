package chain

import (
	"encoding/json"
	"log"
	"time"
	"net/http"
	"bytes"
	
	"observer/internal/metrics"
)

const TIMEOUT = 5

func CheckBitcoinRPC(rpcURL, rpcUser, rpcPassword string) {
	start := time.Now()

	// JSON-RPC 요청 바디 생성
	payload := map[string]interface{}{
		"jsonrpc": "1.0",
		"id":      "observer",
		"method":  "getblockchaininfo",
		"params":  []interface{}{},
	}
	body, _:= json.Marshal(payload)

	// 1. RPC 요청 생성
	req, err := http.NewRequest("POST", rpcURL, bytes.NewBuffer(body))
	if err != nil {
		metrics.BitcoinRPCUp.Set(0)
		metrics.BitcoinRPCErrors.Inc()
		log.Println(" Bitcoin RPC failed to create request: ", err)
		return 
	}	
	req.SetBasicAuth(rpcUser, rpcPassword) 
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: TIMEOUT * time.Second}

	// 2. 지연시간 측정 시작
	resp, err := client.Do(req)
	metrics.BitcoinRPCLatency.Observe(time.Since(start).Seconds())
	if err != nil {
		metrics.BitcoinRPCUp.Set(0)
		metrics.BitcoinRPCErrors.Inc()
		log.Println(" Bitcoin RPC request failed: ", err)
		return 
	}
	defer resp.Body.Close() 

	// 3. 응답 상태 코드 확인
	if resp.StatusCode != http.StatusOK {
		metrics.BitcoinRPCUp.Set(0)
		metrics.BitcoinRPCErrors.Inc()
		log.Println(" Bitcoin RPC non-200 status: ", resp.StatusCode)
		return
	}

	// 모든 체크 통과시 정상으로 간주
	metrics.BitcoinRPCUp.Set(1)
}


func CheckExternalBitcoinAPI() {
	resp, err := http.Get("https://blockstream.info/api/blocks/tip/height")
	if err != nil {
		log.Println("[External API] request failed:", err)
		return 
	}
	defer resp.Body.Close() 

	var height int
	if err := json.NewDecoder(resp.Body).Decode(&height); err != nil { 
		log.Println("External API decode failed: ", err)
		return 
	}
	log.Println("External API Bitcoin block height: ", height)

	// Prometheus metric에 값 기록 ! 
	metrics.ExternalBlockHeight.Set(float64(height))
}
