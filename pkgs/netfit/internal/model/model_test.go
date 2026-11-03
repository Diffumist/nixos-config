package model

import (
	"math"
	"strings"
	"testing"
)

func TestRecommendBalanced(t *testing.T) {
	t.Parallel()

	recommendation, err := Recommend(Inputs{
		BandwidthMbps: 1_000,
		RTTMillis:     100,
		MemoryBytes:   2 * 1024 * 1024 * 1024,
		PageSize:      4_096,
		Profile:       ProfileBalanced,
	}, Measurements{})
	if err != nil {
		t.Fatal(err)
	}

	if recommendation.TCP.BDPBytes != 12_500_000 {
		t.Fatalf("unexpected BDP: %d", recommendation.TCP.BDPBytes)
	}
	if recommendation.TCP.ReceiveMaximum != 25_001_984 {
		t.Fatalf("unexpected TCP maximum: %d", recommendation.TCP.ReceiveMaximum)
	}
	if recommendation.Sysctls["net.core.rmem_max"] != "25001984" {
		t.Fatalf("unexpected core receive maximum: %s", recommendation.Sysctls["net.core.rmem_max"])
	}
	if recommendation.Sysctls["net.ipv4.tcp_mem"] != "" {
		t.Fatal("tcp_mem must remain kernel-managed")
	}
}

func TestRecommendRecordsAssumedRTT(t *testing.T) {
	t.Parallel()

	recommendation, err := Recommend(Inputs{
		BandwidthMbps: 100,
		RTTMillis:     150,
		RTTSource:     RTTSourceAssumed,
		MemoryBytes:   512 * 1024 * 1024,
		PageSize:      4_096,
		Profile:       ProfileProxy,
	}, Measurements{Peer: "public.example.net:5201"})
	if err != nil {
		t.Fatal(err)
	}
	if recommendation.Inputs.RTTSource != RTTSourceAssumed ||
		!strings.Contains(strings.Join(recommendation.Warnings, "\n"), "override it with --rtt") {
		t.Fatalf("assumed RTT was not exposed: %#v", recommendation)
	}
}

func TestRecommendNeverLowersCurrentLimits(t *testing.T) {
	t.Parallel()

	recommendation, err := Recommend(Inputs{
		BandwidthMbps: 100,
		RTTMillis:     10,
		MemoryBytes:   1024 * 1024 * 1024,
		PageSize:      4_096,
		Profile:       ProfileProxy,
		Current: CurrentSysctls{
			CoreReceiveMaximum: 32 * 1024 * 1024,
			CoreSendMaximum:    32 * 1024 * 1024,
			TCPReceiveMinimum:  8 * 1024,
			TCPReceiveDefault:  512 * 1024,
			TCPReceiveMaximum:  16 * 1024 * 1024,
			TCPSendMinimum:     16 * 1024,
			TCPSendDefault:     256 * 1024,
			TCPSendMaximum:     8 * 1024 * 1024,
		},
	}, Measurements{})
	if err != nil {
		t.Fatal(err)
	}

	if recommendation.TCP.ReceiveMaximum != 16*1024*1024 || recommendation.TCP.SendMaximum != 8*1024*1024 {
		t.Fatalf("current TCP limits were lowered: %#v", recommendation.TCP)
	}
	if recommendation.TCP.ReceiveMinimum != 8*1024 || recommendation.TCP.ReceiveDefault != 512*1024 ||
		recommendation.TCP.SendMinimum != 16*1024 || recommendation.TCP.SendDefault != 256*1024 {
		t.Fatalf("current TCP minimum/default values were lowered: %#v", recommendation.TCP)
	}
	if recommendation.Sysctls["net.core.rmem_max"] != "33554432" || recommendation.Sysctls["net.core.wmem_max"] != "33554432" {
		t.Fatalf("current core limits were lowered: %#v", recommendation.Sysctls)
	}
}

func TestRecommendDoesNotExceedUnalignedMemoryCap(t *testing.T) {
	t.Parallel()

	const memory = 65 * 1024 * 1024
	recommendation, err := Recommend(Inputs{
		BandwidthMbps: 100_000,
		RTTMillis:     500,
		MemoryBytes:   memory,
		PageSize:      65_536,
		Profile:       ProfileProxy,
	}, Measurements{})
	if err != nil {
		t.Fatal(err)
	}

	if recommendation.TCP.ReceiveMaximum > memory/64 {
		t.Fatalf("TCP maximum exceeds memory policy: %d", recommendation.TCP.ReceiveMaximum)
	}
}

func TestRecommendCapsBuffersByMemoryPolicy(t *testing.T) {
	t.Parallel()

	recommendation, err := Recommend(Inputs{
		BandwidthMbps: 100_000,
		RTTMillis:     500,
		MemoryBytes:   128 * 1024 * 1024,
		PageSize:      4_096,
		Profile:       ProfileProxy,
	}, Measurements{})
	if err != nil {
		t.Fatal(err)
	}

	if recommendation.TCP.ReceiveMaximum != 2*1024*1024 {
		t.Fatalf("unexpected capped maximum: %d", recommendation.TCP.ReceiveMaximum)
	}
}

func TestParseProfileRejectsUnknownValue(t *testing.T) {
	t.Parallel()

	if _, err := ParseProfile("server"); err == nil {
		t.Fatal("expected an invalid profile error")
	}
}

func TestRecommendRejectsNonFiniteInput(t *testing.T) {
	t.Parallel()

	_, err := Recommend(Inputs{
		BandwidthMbps: math.NaN(),
		RTTMillis:     20,
		MemoryBytes:   512 * 1024 * 1024,
		PageSize:      4_096,
		Profile:       ProfileProxy,
	}, Measurements{})
	if err == nil {
		t.Fatal("expected non-finite bandwidth to fail")
	}
}

func TestRecommendBuildsAggregateShapingTree(t *testing.T) {
	t.Parallel()

	recommendation, err := Recommend(Inputs{
		BandwidthMbps: 1_000,
		RTTMillis:     20,
		MemoryBytes:   1024 * 1024 * 1024,
		PageSize:      4_096,
		Profile:       ProfileBalanced,
		Shaping: &ShapingInput{
			Interface: "ens3",
			RateMbps:  950,
			Source:    "explicit",
		},
	}, Measurements{})
	if err != nil {
		t.Fatal(err)
	}

	shaping := recommendation.TCP.Shaping
	if shaping == nil {
		t.Fatal("missing shaping recommendation")
	}
	if shaping.Scope != "all-egress" || shaping.RootQdisc != "htb" || shaping.LeafQdisc != "fq" {
		t.Fatalf("unexpected shaping tree: %#v", shaping)
	}
	if len(recommendation.KernelModules) != 2 {
		t.Fatalf("unexpected shaping modules: %#v", recommendation.KernelModules)
	}
}

func TestRecommendRejectsUnsafeShapingInterface(t *testing.T) {
	t.Parallel()

	_, err := Recommend(Inputs{
		BandwidthMbps: 100,
		RTTMillis:     20,
		MemoryBytes:   512 * 1024 * 1024,
		PageSize:      4_096,
		Profile:       ProfileProxy,
		Shaping: &ShapingInput{
			Interface: "eth0;reboot",
			RateMbps:  95,
			Source:    "explicit",
		},
	}, Measurements{})
	if err == nil {
		t.Fatal("expected unsafe interface to fail")
	}
}
