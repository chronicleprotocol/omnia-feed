package e2e

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestRPC(t *testing.T) {
	rpc, err := NewEthRPC()
	require.NoError(t, err)

	price, err := rpc.GetPrice(context.Background(), "0x9b637fDF5482340C823930366464c146f318b896")
	require.NoError(t, err)
	require.Equal(t, float64(0), price)
}

func TestSignMessage(t *testing.T) {
	msg, err := SignMessage("BTC/USD", "0.4")

	require.NoError(t, err)
	require.NotEmpty(t, msg)
}

func TestWriteOmniaMessage(t *testing.T) {
	msg, err := NewOmniaMessage("BTC/USD", 0.4)
	require.NoError(t, err)
	require.NotEmpty(t, msg)

	err = WriteOmniaMessage(msg)
	require.NoError(t, err)
}
