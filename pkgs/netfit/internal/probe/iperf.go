package probe

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"sort"
	"strconv"
	"time"
)

var ErrSampleTimeout = errors.New("iperf3 sample timed out")

type Runner struct {
	Binary        string
	Duration      int
	Omit          int
	SampleTimeout time.Duration
}

type TCPResult struct {
	Port              int     `json:"port"`
	TargetMbps        float64 `json:"targetMbps,omitempty"`
	SenderMbps        float64 `json:"senderMbps"`
	ReceiverMbps      float64 `json:"receiverMbps"`
	Retransmits       int64   `json:"retransmits"`
	RetransmitsPerGiB float64 `json:"retransmitsPerGiB"`
	MeanRTTMillis     float64 `json:"meanRTTMillis,omitempty"`
}

func (runner Runner) RunTCP(ctx context.Context, peer SelectedPeer, targetMbps float64) (TCPResult, error) {
	var lastError error
	for _, port := range orderedPorts(peer) {
		arguments := runner.commonArguments(peer, port)
		if targetMbps > 0 {
			arguments = append(arguments,
				"--bitrate", formatMbps(targetMbps),
				"--pacing-timer", "250",
			)
		}
		payload, err := runner.execute(ctx, arguments)
		if err != nil {
			lastError = err
			continue
		}
		result, err := parseTCP(payload)
		if err != nil {
			lastError = err
			continue
		}
		result.Port = port
		result.TargetMbps = targetMbps
		return result, nil
	}
	return TCPResult{}, fmt.Errorf("TCP iperf3 failed for %s: %w", peer.Host, lastError)
}

func (runner Runner) commonArguments(peer SelectedPeer, port int) []string {
	arguments := []string{
		"--client", iperfTarget(peer),
		"--port", strconv.Itoa(port),
		"--json",
		"--time", strconv.Itoa(runner.Duration),
		"--omit", strconv.Itoa(runner.Omit),
		"--parallel", "1",
		"--connect-timeout", "5000",
	}
	if peer.IPFamily == IPFamily4 || peer.IPFamily == IPFamily6 {
		arguments = append(arguments, "-"+string(peer.IPFamily))
	}
	return arguments
}

func (runner Runner) execute(ctx context.Context, arguments []string) ([]byte, error) {
	binary := runner.Binary
	if binary == "" {
		binary = "iperf3"
	}
	timeout := runner.effectiveSampleTimeout()
	sampleContext, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	command := exec.CommandContext(sampleContext, binary, arguments...)
	payload, err := command.Output()
	if err != nil {
		if contextError := ctx.Err(); contextError != nil {
			return nil, contextError
		}
		if errors.Is(sampleContext.Err(), context.DeadlineExceeded) {
			return nil, fmt.Errorf("%w after %s", ErrSampleTimeout, timeout)
		}
		var exitError *exec.ExitError
		if !errors.As(err, &exitError) {
			return nil, err
		}
		if len(exitError.Stderr) > 0 {
			return nil, fmt.Errorf("%s", exitError.Stderr)
		}
		return nil, err
	}
	return payload, nil
}

func (runner Runner) effectiveSampleTimeout() time.Duration {
	if runner.SampleTimeout > 0 {
		return runner.SampleTimeout
	}
	return time.Duration(runner.Duration+runner.Omit+15) * time.Second
}

type iperfDocument struct {
	Error string `json:"error"`
	End   struct {
		SumSent     iperfSummary `json:"sum_sent"`
		SumReceived iperfSummary `json:"sum_received"`
		Streams     []struct {
			Sender iperfSummary `json:"sender"`
		} `json:"streams"`
	} `json:"end"`
}

type iperfSummary struct {
	Bytes         uint64  `json:"bytes"`
	BitsPerSecond float64 `json:"bits_per_second"`
	Retransmits   *int64  `json:"retransmits"`
	MeanRTT       float64 `json:"mean_rtt"`
}

func parseTCP(payload []byte) (TCPResult, error) {
	document, err := parseDocument(payload)
	if err != nil {
		return TCPResult{}, err
	}
	sender := document.End.SumSent
	if sender.BitsPerSecond <= 0 && len(document.End.Streams) > 0 {
		sender = document.End.Streams[0].Sender
	}
	if sender.BitsPerSecond <= 0 || sender.Bytes == 0 {
		return TCPResult{}, fmt.Errorf("iperf3 JSON has no TCP sender summary")
	}
	if sender.Retransmits == nil || *sender.Retransmits < 0 {
		return TCPResult{}, fmt.Errorf("iperf3 JSON has no valid TCP retransmit count")
	}
	meanRTT := sender.MeanRTT
	if meanRTT <= 0 && len(document.End.Streams) > 0 {
		meanRTT = document.End.Streams[0].Sender.MeanRTT
	}
	receiver := document.End.SumReceived
	if receiver.BitsPerSecond <= 0 {
		return TCPResult{}, fmt.Errorf("iperf3 JSON has no TCP receiver summary")
	}
	retransmitsPerGiB := float64(*sender.Retransmits) / (float64(sender.Bytes) / float64(1<<30))
	return TCPResult{
		SenderMbps:        sender.BitsPerSecond / 1_000_000,
		ReceiverMbps:      receiver.BitsPerSecond / 1_000_000,
		Retransmits:       *sender.Retransmits,
		RetransmitsPerGiB: retransmitsPerGiB,
		MeanRTTMillis:     meanRTT / 1_000,
	}, nil
}

func parseDocument(payload []byte) (iperfDocument, error) {
	var document iperfDocument
	if err := json.Unmarshal(payload, &document); err != nil {
		return iperfDocument{}, fmt.Errorf("parse iperf3 JSON: %w", err)
	}
	if document.Error != "" {
		return iperfDocument{}, fmt.Errorf("iperf3: %s", document.Error)
	}
	return document, nil
}

func median(values []float64) float64 {
	copyOfValues := append([]float64(nil), values...)
	sort.Float64s(copyOfValues)
	middle := len(copyOfValues) / 2
	if len(copyOfValues)%2 == 1 {
		return copyOfValues[middle]
	}
	return (copyOfValues[middle-1] + copyOfValues[middle]) / 2
}

func formatMbps(value float64) string {
	return strconv.FormatFloat(value, 'f', 3, 64) + "M"
}

func iperfTarget(peer SelectedPeer) string {
	if peer.RemoteIP != "" {
		return peer.RemoteIP
	}
	return peer.Host
}

func orderedPorts(peer SelectedPeer) []int {
	ports := []int{peer.Port}
	for _, port := range peer.Ports {
		if port != peer.Port {
			ports = append(ports, port)
		}
	}
	return ports
}
