package e2e

import (
	"encoding/json"
	"fmt"
)

type OmniaMessage struct {
	Type      string            `json:"type"`
	Version   string            `json:"version"`
	Price     float64           `json:"price"`
	PriceHex  string            `json:"priceHex"`
	Time      int64             `json:"time"`
	Hash      string            `json:"hash"`
	Signature string            `json:"signature"`
	Sources   map[string]string `json:"sources"`
}

func NewOmniaMessage(pair string, price float64) (*OmniaMessage, error) {
	msgStr, err := SignMessage(pair, fmt.Sprintf("%f", price))
	if err != nil {
		return nil, fmt.Errorf("failed to sign message: %v", err)
	}
	var msg OmniaMessage
	err = json.Unmarshal([]byte(msgStr), &msg)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal message: %v", err)
	}

	return &msg, nil
}

func WriteOmniaMessage(msg *OmniaMessage) error {
	b, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}
	_, _, err = call("transport-e2e", "publish", string(b))
	return err
}
