package e2e

import (
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/hpcloud/tail"
)

type PriceValue struct {
	Wat string
	Val string
	Age int64
	R   string
	S   string
	V   string
}
type PriceMessage struct {
	Price PriceValue
	Trace map[string]string
}

func NewPriceMessage(pair, price string) *PriceMessage {
	return &PriceMessage{
		Price: PriceValue{
			Wat: pair,
			Val: price,
			Age: time.Now().Unix(),
			R:   "0",
			S:   "0",
			V:   "0",
		},
		Trace: map[string]string{
			"source": "test",
		},
	}
}

type Transport struct {
	filePath string
	tail     *tail.Tail
	ch       chan string
}

func NewTransport() (*Transport, error) {
	filePath, ok := os.LookupEnv("OMNIA_TRANSPORT_E2E_FILE")
	if !ok || filePath == "" {
		return nil, fmt.Errorf("OMNIA_TRANSPORT_E2E_FILE is not set")
	}

	if _, err := os.Stat(filePath); errors.Is(err, os.ErrNotExist) {
		if _, fErr := os.Create(filePath); fErr != nil {
			return nil, fmt.Errorf("failed to create transport file: %w", fErr)
		}
	}

	err := os.Truncate(filePath, 0)
	if err != nil {
		return nil, fmt.Errorf("failed to truncate file: %w", err)
	}

	return &Transport{
		filePath: filePath,
	}, nil
}

func (t *Transport) Close() error {
	if t.tail == nil {
		return nil
	}
	err := t.tail.Stop()
	if err == nil {
		t.tail = nil
	}
	close(t.ch)
	t.ch = nil

	return err
}

func (t *Transport) IsEmpty() (bool, error) {
	if t.filePath == "" {
		return false, fmt.Errorf("IsEmpty: file path is not set")
	}

	content, err := os.ReadFile(t.filePath)
	if err != nil {
		return false, fmt.Errorf("IsEmpty: failed to check content: %w", err)
	}
	return len(content) == 0, nil
}

func (t *Transport) ReadChan() (chan string, error) {
	var err error

	if t.tail == nil {
		t.tail, err = tail.TailFile(t.filePath, tail.Config{Follow: true, MustExist: true, ReOpen: true})
		if err != nil {
			return nil, fmt.Errorf("failed to read file: %w", err)
		}
	}
	if t.ch == nil {
		t.ch = make(chan string)
	}
	go func() {
		for line := range t.tail.Lines {
			if t.ch == nil {
				return
			}
			t.ch <- line.Text
		}
	}()
	return t.ch, nil
}

func (t *Transport) WaitMsg(timeout time.Duration) (string, error) {
	if t.ch == nil {
		_, err := t.ReadChan()
		if err != nil {
			return "", fmt.Errorf("failed to create read channel: %w", err)
		}
	}
	select {
	case msg := <-t.ch:
		return msg, nil
	case <-time.After(timeout):
		return "", fmt.Errorf("timeout waiting for message")
	}
}

func (t *Transport) Truncate() error {
	if t.filePath == "" {
		return fmt.Errorf("Truncate: file path is not set")
	}
	return os.Truncate(t.filePath, 0)
}

func (t *Transport) WriteMsg(msg []byte) error {
	if t.filePath == "" {
		return fmt.Errorf("WriteMsg: file path is not set")
	}
	err := os.WriteFile(t.filePath, msg, 0644)
	if err != nil {
		return fmt.Errorf("failed to open file: %w", err)
	}
	return nil
}
