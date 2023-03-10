package relay

import (
	"context"
	"testing"
	"time"

	"github.com/chronicleprotocol/infestor"
	"github.com/chronicleprotocol/infestor/origin"

	"github.com/stretchr/testify/suite"

	e2e "github.com/makerdao/setzer-e2e"
)

const contractAddress = "0x9b637fDF5482340C823930366464c146f318b896"

func TestRelayBaseBehaviourE2ESuite(t *testing.T) {
	suite.Run(t, new(RelayBaseBehaviourE2ESuite))
}

type RelayBaseBehaviourE2ESuite struct {
	e2e.SmockerAPISuite

	rpc *e2e.EthRPC
}

func (s *RelayBaseBehaviourE2ESuite) SetupSuite() {
	var err error

	s.SmockerAPISuite.SetupSuite()

	s.rpc, err = e2e.NewEthRPC()
	s.Require().NoError(err)

	price, err := s.rpc.GetPrice(context.Background(), contractAddress)
	s.Require().NoError(err)
	s.Require().Equal(0.0, price)

	// Setup price for BTC/USD
	err = infestor.NewMocksBuilder().
		Reset().
		Add(origin.NewExchange("binance_us").WithSymbol("BTC/USD").WithPrice(0.4)).
		Add(origin.NewExchange("bitstamp").WithSymbol("BTC/USD").WithPrice(0.4)).
		Add(origin.NewExchange("bittrex").WithSymbol("BTC/USD").WithPrice(0.4)).
		Add(origin.NewExchange("coinbase").WithSymbol("BTC/USD").WithPrice(0.4)).
		Add(origin.NewExchange("gemini").WithSymbol("BTC/USD").WithPrice(0.4)).
		Add(origin.NewExchange("kraken").WithSymbol("XXBT/ZUSD").WithPrice(0.4)).
		Deploy(s.API)

	s.Require().NoError(err)
}

func (s *RelayBaseBehaviourE2ESuite) TestRelayUpdatesPrice() {
	s.Omnia = e2e.NewOmniaRelayProcess(s.Ctx)

	s.Require().NoError(s.Transport.Truncate()) // TODO: need to truncate ?

	msg, err := e2e.NewOmniaMessage("BTC/USD", 0.4)
	s.Require().NoError(err)
	s.Require().NotNil(msg)

	err = e2e.WriteOmniaMessage(msg)
	s.Require().NoError(err)

	err = s.Omnia.Start()
	s.Require().NoError(err)

	block, err := s.rpc.WaitNextBlock(s.Ctx, 30*time.Second)
	s.Require().NoError(err)
	s.Require().Greater(block, uint64(0))

	price, err := s.rpc.GetPrice(context.Background(), contractAddress)
	s.Require().NoError(err)
	s.Require().Greater(price, 0.0)
}

func (s *RelayBaseBehaviourE2ESuite) TestExpiredMessage() {
	s.Omnia = e2e.NewOmniaRelayProcess(s.Ctx)

	s.Require().NoError(s.Transport.Truncate())

	msg, err := e2e.NewOmniaMessage("BTC/USD", 0.4)
	s.Require().NoError(err)
	s.Require().NotNil(msg)

	// 1 hour delay
	msg.Time = time.Now().Add(-1 * time.Hour).Unix()

	err = e2e.WriteOmniaMessage(msg)
	s.Require().NoError(err)

	err = s.Omnia.Start()
	s.Require().NoError(err)

	startBlock, err := s.rpc.GetLastBlockNumber(s.Ctx)
	s.Require().NoError(err)
	s.Require().Greater(startBlock, uint64(0))

	_, err = s.rpc.WaitNextBlock(s.Ctx, 30*time.Second)
	s.Require().Error(err)

	// No new block should be mined
	block, err := s.rpc.GetLastBlockNumber(s.Ctx)
	s.Require().NoError(err)
	s.Require().Equal(startBlock, block)

	price, err := s.rpc.GetPrice(context.Background(), contractAddress)
	s.Require().NoError(err)
	s.Require().Equal(0.0, price)
}

func (s *RelayBaseBehaviourE2ESuite) TestInvalidPriceMessage() {
	s.Omnia = e2e.NewOmniaRelayProcess(s.Ctx)

	s.Require().NoError(s.Transport.Truncate())

	msg, err := e2e.NewOmniaMessage("BTC/USD", 0.4)
	s.Require().NoError(err)
	s.Require().NotNil(msg)

	msg.Price = -1.0

	err = e2e.WriteOmniaMessage(msg)
	s.Require().NoError(err, err)

	err = s.Omnia.Start()
	s.Require().NoError(err)

	startBlock, err := s.rpc.GetLastBlockNumber(s.Ctx)
	s.Require().NoError(err)
	s.Require().Greater(startBlock, uint64(0))

	_, err = s.rpc.WaitNextBlock(s.Ctx, 30*time.Second)
	s.Require().Error(err)

	// No new block should be mined
	block, err := s.rpc.GetLastBlockNumber(s.Ctx)
	s.Require().NoError(err)
	s.Require().Equal(startBlock, block)

	price, err := s.rpc.GetPrice(context.Background(), contractAddress)
	s.Require().NoError(err)
	s.Require().Equal(0.0, price)
}

func (s *RelayBaseBehaviourE2ESuite) TestInvalidMessageSignature() {
	s.Omnia = e2e.NewOmniaRelayProcess(s.Ctx)

	s.Require().NoError(s.Transport.Truncate())

	msg, err := e2e.NewOmniaMessage("BTC/USD", 0.4)
	s.Require().NoError(err)
	s.Require().NotNil(msg)

	msg.Signature = "invalid"

	err = e2e.WriteOmniaMessage(msg)
	s.Require().NoError(err)

	err = s.Omnia.Start()
	s.Require().NoError(err)

	startBlock, err := s.rpc.GetLastBlockNumber(s.Ctx)
	s.Require().NoError(err)
	s.Require().Greater(startBlock, uint64(0))

	_, err = s.rpc.WaitNextBlock(s.Ctx, 30*time.Second)
	s.Require().Error(err)

	// No new block should be mined
	block, err := s.rpc.GetLastBlockNumber(s.Ctx)
	s.Require().NoError(err)
	s.Require().Equal(startBlock, block)

	price, err := s.rpc.GetPrice(context.Background(), contractAddress)
	s.Require().NoError(err)
	s.Require().Equal(0.0, price)
}
