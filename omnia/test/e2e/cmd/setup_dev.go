package main

import (
	"fmt"
	"os"

	"github.com/chronicleprotocol/infestor"
	"github.com/chronicleprotocol/infestor/origin"
	"github.com/chronicleprotocol/infestor/smocker"
)

const smockerPort = 8081

func main() {
	smockerHost, exist := os.LookupEnv("SMOCKER_HOST")
	if !exist {
		smockerHost = "http://localhost"
	}

	api := smocker.API{
		fmt.Sprintf("%s:%d", smockerHost, smockerPort),
	}

	err := infestor.NewMocksBuilder().
		Reset().
		Add(origin.NewExchange("bitstamp").WithSymbol("BTC/USD").WithPrice(0.4)).
		Add(origin.NewExchange("bittrex").WithSymbol("BTC/USD").WithPrice(0.4)).
		Add(origin.NewExchange("coinbase").WithSymbol("BTC/USD").WithPrice(0.4)).
		Add(origin.NewExchange("gemini").WithSymbol("BTC/USD").WithPrice(0.4)).
		Add(origin.NewExchange("kraken").WithSymbol("XXBT/ZUSD").WithPrice(0.4)).
		Deploy(api)

	if err != nil {
		fmt.Println(err)
		panic(err)
	}
}
