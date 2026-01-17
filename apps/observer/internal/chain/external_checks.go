package chain

import (
	"log"

	"observer/internal/external"
	"observer/internal/metrics"
	"observer/internal/price"
)

func CheckExternalBitcoinAPI() {
	// 1. 블록 높이
	height, err := external.FetchBlockHeight()
	if err != nil {
		log.Println("[External API] block height failed:", err)
		return
	}
	metrics.ExternalBlockHeight.Set(float64(height))
	log.Println("[External API] Bitcoin block height:", height)

	// 2) 비트코인 시세 (USD/KRW)
	usd, krw, err := price.FetchBTCPriceUSDKRW()
	if err != nil {
		log.Println("[External API] bitcoin price failed:", err)
		return
	}
	metrics.BitcoinPriceUSD.Set(usd)
	metrics.BitcoinPriceKRW.Set(krw)
	log.Println("[External API] Bitcoin price:", "USD", usd, "KRW", krw)
}
