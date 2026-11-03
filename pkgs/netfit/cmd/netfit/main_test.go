package main

import (
	"bytes"
	"context"
	"strings"
	"testing"

	"github.com/diffumist/nixos-config/pkgs/netfit/internal/probe"
)

func TestHelpDoesNotInspectTheSystem(t *testing.T) {
	t.Parallel()

	var stdout bytes.Buffer
	if err := run(context.Background(), []string{"--help"}, &stdout, &bytes.Buffer{}); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(stdout.String(), "never writes sysctls") {
		t.Fatalf("unexpected help output: %s", stdout.String())
	}
}

func TestRecommendRejectsNonFiniteInputBeforeDetection(t *testing.T) {
	t.Parallel()

	err := run(context.Background(), []string{"recommend", "--bandwidth", "NaN", "--rtt", "20"}, &bytes.Buffer{}, &bytes.Buffer{})
	if err == nil || !strings.Contains(err.Error(), "bandwidth") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRecommendRequiresOddSamples(t *testing.T) {
	t.Parallel()

	err := run(context.Background(), []string{"recommend", "--bandwidth", "100", "--rtt", "20", "--samples", "2"}, &bytes.Buffer{}, &bytes.Buffer{})
	if err == nil || !strings.Contains(err.Error(), "odd number") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRecommendRejectsUnknownIPFamilyBeforeDetection(t *testing.T) {
	t.Parallel()

	err := run(context.Background(), []string{
		"recommend", "--bandwidth", "100", "--rtt", "20", "--ip-family", "dual",
	}, &bytes.Buffer{}, &bytes.Buffer{})
	if err == nil || !strings.Contains(err.Error(), "IP family") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRecommendRejectsRemovedUDPFlags(t *testing.T) {
	t.Parallel()

	err := run(context.Background(), []string{
		"recommend", "--bandwidth", "100", "--rtt", "20", "--udp-loss", "1",
	}, &bytes.Buffer{}, &bytes.Buffer{})
	if err == nil || !strings.Contains(err.Error(), "flag provided but not defined") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRecommendationRTTDoesNotTreatAutomaticPeerAsWorkloadPath(t *testing.T) {
	t.Parallel()

	report := probe.Report{
		Peer:        probe.SelectedPeer{ConnectMillis: 2},
		TCPBaseline: probe.TCPResult{MeanRTTMillis: 3},
	}
	rtt, source := recommendationRTT("auto", 0, report)
	if rtt != automaticPublicRTTMS || source != "assumed" {
		t.Fatalf("unexpected automatic RTT: %.2f %s", rtt, source)
	}
	rtt, source = recommendationRTT("iperf.example.net", 0, report)
	if rtt != 3 || source != "measured" {
		t.Fatalf("unexpected custom peer RTT: %.2f %s", rtt, source)
	}
	rtt, source = recommendationRTT("auto", 80, report)
	if rtt != 80 || source != "explicit" {
		t.Fatalf("explicit RTT was ignored: %.2f %s", rtt, source)
	}
}

func TestRecommendRejectsNonFiniteShapingRateBeforeDetection(t *testing.T) {
	t.Parallel()

	err := run(context.Background(), []string{
		"recommend", "--bandwidth", "100", "--rtt", "20", "--shape-rate", "NaN",
	}, &bytes.Buffer{}, &bytes.Buffer{})
	if err == nil || !strings.Contains(err.Error(), "shaping rate") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestCommandsRejectTrailingArguments(t *testing.T) {
	t.Parallel()

	err := run(context.Background(), []string{"peers", "typo"}, &bytes.Buffer{}, &bytes.Buffer{})
	if err == nil || !strings.Contains(err.Error(), "unexpected arguments") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestProgressLoggerUsesStderrFriendlyLines(t *testing.T) {
	t.Parallel()

	var output bytes.Buffer
	progressLogger(&output, false)(probe.ProgressEvent{
		Phase: "tcp", Current: 2, Total: 5, Message: "1000 Mbps, sample 1/3",
	})
	if output.String() != "netfit: [tcp 2/5] 1000 Mbps, sample 1/3\n" {
		t.Fatalf("unexpected progress output: %q", output.String())
	}

	output.Reset()
	progressLogger(&output, true)(probe.ProgressEvent{Phase: "tcp", Message: "hidden"})
	if output.Len() != 0 {
		t.Fatalf("quiet progress wrote output: %q", output.String())
	}
}
