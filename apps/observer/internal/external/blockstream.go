package external

import (
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"
)

const (
	blockstreamTipHeightURL = "https://blockstream.info/api/blocks/tip/height"
	timeout                 = 5 * time.Second
)

func FetchBlockHeight() (int, error) {
	client := &http.Client{Timeout: timeout}

	resp, err := client.Get(blockstreamTipHeightURL)
	if err != nil {
		return 0, fmt.Errorf("blockstream request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("blockstream non-200: %d", resp.StatusCode)
	}

	b, err := io.ReadAll(resp.Body)
	if err != nil {
		return 0, fmt.Errorf("blockstream read failed: %w", err)
	}

	s := strings.TrimSpace(string(b))
	h, err := strconv.Atoi(s)
	if err != nil {
		return 0, fmt.Errorf("blockstream parse int failed (body=%q): %w", s, err)
	}

	return h, nil
}
