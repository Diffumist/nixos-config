package probe

import (
	"context"
	"errors"
	"math"
	"strings"
	"testing"
	"time"
)

func TestParseTCP(t *testing.T) {
	t.Parallel()

	payload := []byte(`{
  "end": {
    "sum_sent": {"bytes": 1073741824, "bits_per_second": 800000000, "retransmits": 25, "mean_rtt": 12345},
    "sum_received": {"bytes": 1050000000, "bits_per_second": 780000000}
  }
}`)
	result, err := parseTCP(payload)
	if err != nil {
		t.Fatal(err)
	}
	if result.SenderMbps != 800 || result.ReceiverMbps != 780 {
		t.Fatalf("unexpected TCP throughput: %#v", result)
	}
	if result.RetransmitsPerGiB != 25 || math.Abs(result.MeanRTTMillis-12.345) > 0.001 {
		t.Fatalf("unexpected TCP metrics: %#v", result)
	}
}

func TestParseTCPRejectsMissingRetransmits(t *testing.T) {
	t.Parallel()

	payload := []byte(`{
  "end": {
    "sum_sent": {"bytes": 1073741824, "bits_per_second": 800000000},
    "sum_received": {"bytes": 1050000000, "bits_per_second": 780000000}
  }
}`)
	if _, err := parseTCP(payload); err == nil {
		t.Fatal("expected missing TCP retransmits to fail")
	}
}

func TestMajority(t *testing.T) {
	t.Parallel()

	if !majority(2, 3) || majority(1, 3) {
		t.Fatal("unexpected majority decision")
	}
}

func TestScaledRatesDeduplicatesLowRates(t *testing.T) {
	t.Parallel()

	rates := scaledRates(1, []float64{0.5, 0.7, 1, 1.2}, 0)
	if len(rates) != 1 || rates[0] != 1 {
		t.Fatalf("unexpected rates: %#v", rates)
	}
}

func TestScaledRatesEnforcesMaximum(t *testing.T) {
	t.Parallel()

	rates := scaledRates(1_000, []float64{0.9, 1, 1.1, 1.3}, 1_000)
	if len(rates) != 2 || rates[0] != 900 || rates[1] != 1_000 {
		t.Fatalf("unexpected capped rates: %#v", rates)
	}
}

func TestIperfArgumentsPinResolvedAddressAndFamily(t *testing.T) {
	t.Parallel()

	arguments := (Runner{Duration: 5, Omit: 2}).commonArguments(SelectedPeer{
		Peer:     Peer{Host: "dual-stack.example.net"},
		RemoteIP: "2001:db8::10",
		IPFamily: IPFamily6,
	}, 5202)
	joined := strings.Join(arguments, " ")
	if !strings.Contains(joined, "--client 2001:db8::10") || !strings.Contains(joined, "-6") ||
		strings.Contains(joined, "dual-stack.example.net") {
		t.Fatalf("iperf3 target was not pinned: %q", joined)
	}
}

func TestSampleTimeoutIncludesRuntimeHeadroom(t *testing.T) {
	t.Parallel()

	runner := Runner{Duration: 5, Omit: 2}
	if runner.effectiveSampleTimeout() != 22*time.Second {
		t.Fatalf("unexpected automatic timeout: %s", runner.effectiveSampleTimeout())
	}
	runner.SampleTimeout = 10 * time.Second
	if runner.effectiveSampleTimeout() != 10*time.Second {
		t.Fatalf("explicit timeout was ignored: %s", runner.effectiveSampleTimeout())
	}
}

func TestExecuteEnforcesSampleTimeout(t *testing.T) {
	t.Parallel()

	runner := Runner{Binary: "bash", SampleTimeout: 20 * time.Millisecond}
	_, err := runner.execute(context.Background(), []string{"-c", "sleep 5"})
	if !errors.Is(err, ErrSampleTimeout) {
		t.Fatalf("unexpected timeout error: %v", err)
	}
}

func TestRunReportsTCPProgress(t *testing.T) {
	t.Parallel()

	messages := make([]string, 0)
	report, err := Run(context.Background(), progressTestRunner{}, SelectedPeer{
		Peer: Peer{Host: "iperf.example.net"},
		Port: 5201,
	}, Options{
		NominalMbps: 100,
		Samples:     1,
		Progress: func(event ProgressEvent) {
			messages = append(messages, event.Message)
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	if report.TCPSweepOutcome != TCPSweepKnee || report.TCPKneeMbps != 110 || report.TCPShapeMbps != 103 {
		t.Fatalf("unexpected sweep result: %#v", report)
	}
	finePoints := 0
	for _, point := range report.TCPSweep {
		if point.Stage == "fine" {
			finePoints++
		}
	}
	if finePoints != 3 {
		t.Fatalf("expected three fine-scan points: %#v", report.TCPSweep)
	}
	joined := strings.Join(messages, "\n")
	if !strings.Contains(joined, "running baseline") ||
		!strings.Contains(joined, "90 Mbps, sample 1/1") ||
		!strings.Contains(joined, "retransmission knee 110.00 Mbps") {
		t.Fatalf("missing progress messages:\n%s", joined)
	}
}

func TestRunExpandsRangeAndReportsOutOfRange(t *testing.T) {
	t.Parallel()

	report, err := Run(context.Background(), outOfRangeRunner{}, SelectedPeer{
		Peer: Peer{Host: "iperf.example.net"},
		Port: 5201,
	}, Options{
		NominalMbps: 100,
		Samples:     1,
	})
	if err != nil {
		t.Fatal(err)
	}
	if report.TCPSweepOutcome != TCPSweepOutOfRange || report.TCPScannedToMbps <= 130 {
		t.Fatalf("unexpected expanded sweep: %#v", report)
	}
}

func TestRunDistinguishesNoKneeFromPeerBottleneck(t *testing.T) {
	t.Parallel()

	options := Options{NominalMbps: 100, Samples: 1}
	peer := SelectedPeer{Peer: Peer{Host: "iperf.example.net"}, Port: 5201}

	clean, err := Run(context.Background(), steadyRunner{}, peer, options)
	if err != nil {
		t.Fatal(err)
	}
	if clean.TCPSweepOutcome != TCPSweepNoKnee {
		t.Fatalf("unexpected clean outcome: %#v", clean)
	}

	limited, err := Run(context.Background(), bottleneckRunner{}, peer, options)
	if err != nil {
		t.Fatal(err)
	}
	if limited.TCPSweepOutcome != TCPSweepPeerBottleneck {
		t.Fatalf("unexpected bottleneck outcome: %#v", limited)
	}
}

type progressTestRunner struct{}

func (progressTestRunner) RunTCP(_ context.Context, _ SelectedPeer, targetMbps float64) (TCPResult, error) {
	if targetMbps == 0 {
		return TCPResult{Port: 5201, ReceiverMbps: 100, RetransmitsPerGiB: 1, MeanRTTMillis: 10}, nil
	}
	retransmits := 1.0
	if targetMbps >= 110 {
		retransmits = 1_000
	}
	return TCPResult{Port: 5201, ReceiverMbps: targetMbps, RetransmitsPerGiB: retransmits}, nil
}

type outOfRangeRunner struct{}

func (outOfRangeRunner) RunTCP(_ context.Context, _ SelectedPeer, targetMbps float64) (TCPResult, error) {
	if targetMbps == 0 {
		return TCPResult{Port: 5201, ReceiverMbps: 100, RetransmitsPerGiB: 200_000, MeanRTTMillis: 10}, nil
	}
	return TCPResult{Port: 5201, ReceiverMbps: targetMbps, RetransmitsPerGiB: 1}, nil
}

type steadyRunner struct{}

func (steadyRunner) RunTCP(_ context.Context, _ SelectedPeer, targetMbps float64) (TCPResult, error) {
	if targetMbps == 0 {
		targetMbps = 100
	}
	return TCPResult{Port: 5201, ReceiverMbps: targetMbps, RetransmitsPerGiB: 1, MeanRTTMillis: 10}, nil
}

type bottleneckRunner struct{ steadyRunner }

func (bottleneckRunner) RunTCP(_ context.Context, _ SelectedPeer, targetMbps float64) (TCPResult, error) {
	if targetMbps == 0 {
		return TCPResult{Port: 5201, ReceiverMbps: 100, RetransmitsPerGiB: 1, MeanRTTMillis: 10}, nil
	}
	return TCPResult{Port: 5201, ReceiverMbps: targetMbps * 0.5, RetransmitsPerGiB: 1}, nil
}
