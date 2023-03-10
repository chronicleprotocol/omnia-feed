package e2e

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

type EthRPC struct {
	client *ethclient.Client
}

func NewEthRPC() (*EthRPC, error) {
	url, ok := os.LookupEnv("GETH_RPC_URL")
	if !ok || url == "" {
		return nil, fmt.Errorf("GETH_RPC_URL not set")
	}

	client, err := ethclient.Dial(url)
	if err != nil {
		return nil, err
	}
	return &EthRPC{client: client}, nil
}

func (rpc *EthRPC) GetPrice(ctx context.Context, address string) (float64, error) {
	res, err := rpc.client.StorageAt(ctx, common.HexToAddress(address), common.HexToHash("0x1"), nil)
	if err != nil {
		return 0, err
	}
	s := common.Bytes2Hex(res)
	wei, err := strconv.ParseInt(s, 16, 64)
	if wei == 0 {
		return 0, nil
	}
	return float64(wei / 1000000000000000000), nil
}

func (rpc *EthRPC) GetLastBlockNumber(ctx context.Context) (uint64, error) {
	block, err := rpc.client.BlockNumber(ctx)
	if err != nil {
		return 0, err
	}
	return block, nil
}

func (rpc *EthRPC) WaitNextBlock(ctx context.Context, timeout time.Duration) (uint64, error) {
	lastBlock, err := rpc.GetLastBlockNumber(ctx)
	if err != nil {
		return 0, err
	}

	done := make(chan bool)
	defer close(done)

	ch := make(chan uint64)
	defer close(ch)

	go func() {
		for {
			select {
			case <-done:
				return
			default:
				block, err := rpc.GetLastBlockNumber(ctx)
				if err != nil {
					continue
				}
				if block > lastBlock {
					ch <- block
					return
				}
				time.Sleep(time.Millisecond * 50)
			}
		}
	}()

	for {
		select {
		case num := <-ch:
			return num, nil
		case <-ctx.Done():
			return 0, ctx.Err()
		case <-time.After(timeout):
			done <- true
			return 0, fmt.Errorf("timeout waiting for next block")
		}
	}
}
