package price

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

const (
	coingeckoURL = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd%2Ckrw"
	timeout      = 5 * time.Second
)

type coingeckoResp struct {
	Bitcoin struct {
		USD float64 `json:"usd"`
		KRW float64 `json:"krw"`
	} `json:"bitcoin"`
}

// BTC 가격 - USD and KRW
func FetchBTCPriceUSDKRW() (usd float64, krw float64, err error) {
	client := &http.Client{Timeout: timeout}

	resp, err := client.Get(coingeckoURL)
	if err != nil {
		return 0, 0, fmt.Errorf("coingecko request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return 0, 0, fmt.Errorf("coingecko non-200: %d", resp.StatusCode)
	}

	var r coingeckoResp
	if err := json.NewDecoder(resp.Body).Decode(&r); err != nil {
		return 0, 0, fmt.Errorf("coingecko decode failed: %w", err)
	}

	usd = r.Bitcoin.USD
	krw = r.Bitcoin.KRW
	if usd <= 0 || krw <= 0 {
		return 0, 0, fmt.Errorf("coingecko invalid price usd=%v krw=%v", usd, krw)
	}
	return usd, krw, nil
}
