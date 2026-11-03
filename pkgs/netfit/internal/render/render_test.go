package render

import (
	"bytes"
	"strings"
	"testing"

	"github.com/diffumist/nixos-config/pkgs/netfit/internal/model"
)

func TestNixOutputIsPasteableModuleShape(t *testing.T) {
	t.Parallel()

	recommendation, err := model.Recommend(model.Inputs{
		BandwidthMbps: 100,
		RTTMillis:     20,
		MemoryBytes:   512 * 1024 * 1024,
		PageSize:      4_096,
		Profile:       model.ProfileProxy,
	}, model.Measurements{})
	if err != nil {
		t.Fatal(err)
	}

	var output bytes.Buffer
	if err := Recommendation(&output, recommendation, FormatNix); err != nil {
		t.Fatal(err)
	}
	for _, expected := range []string{
		"boot.kernel.sysctl",
		`"net.ipv4.tcp_rmem" = "4096 131072 4194304";`,
		"# Warnings:",
		"No active measurement was supplied",
	} {
		if !strings.Contains(output.String(), expected) {
			t.Fatalf("missing %q in:\n%s", expected, output.String())
		}
	}
	if strings.Contains(output.String(), "UDP") || strings.Contains(output.String(), "SO_RCVBUF") {
		t.Fatalf("unexpected UDP output:\n%s", output.String())
	}
	if strings.Contains(output.String(), "boot.kernelModules") || strings.Contains(output.String(), "tcp_bbr") {
		t.Fatalf("unexpected explicit BBR module load:\n%s", output.String())
	}
}

func TestJSONOmitsAbsentMeasurements(t *testing.T) {
	t.Parallel()

	recommendation, err := model.Recommend(model.Inputs{
		BandwidthMbps: 100,
		RTTMillis:     20,
		MemoryBytes:   512 * 1024 * 1024,
		PageSize:      4_096,
		Profile:       model.ProfileProxy,
	}, model.Measurements{})
	if err != nil {
		t.Fatal(err)
	}

	var output bytes.Buffer
	if err := Recommendation(&output, recommendation, FormatJSON); err != nil {
		t.Fatal(err)
	}
	if strings.Contains(output.String(), "measurements") {
		t.Fatalf("unexpected empty measurements in:\n%s", output.String())
	}
	if strings.Contains(output.String(), `"udp"`) {
		t.Fatalf("unexpected UDP recommendation in:\n%s", output.String())
	}
}

func TestTCOutputBuildsHTBWithFQLeaf(t *testing.T) {
	t.Parallel()

	recommendation := shapingRecommendation(t)
	var output bytes.Buffer
	if err := Recommendation(&output, recommendation, FormatTC); err != nil {
		t.Fatal(err)
	}
	for _, expected := range []string{
		"trap rollback ERR",
		"tc qdisc replace dev ens3 root handle 1: htb default 10",
		"tc class replace dev ens3 parent 1: classid 1:10 htb rate 950Mbit ceil 950Mbit",
		"tc qdisc replace dev ens3 parent 1:10 handle 10: fq",
		"# tc qdisc replace dev ens3 root fq",
	} {
		if !strings.Contains(output.String(), expected) {
			t.Fatalf("missing %q in:\n%s", expected, output.String())
		}
	}
}

func TestNixOutputOwnsAndResetsRootQdiscExplicitly(t *testing.T) {
	t.Parallel()

	recommendation := shapingRecommendation(t)
	var output bytes.Buffer
	if err := Recommendation(&output, recommendation, FormatNix); err != nil {
		t.Fatal(err)
	}
	for _, expected := range []string{
		"{ pkgs, ... }:\n{",
		`boot.kernelModules = [ "sch_htb" "sch_fq" ];`,
		"systemd.services.netfit-egress-shaping",
		"trap rollback ERR",
		"tc qdisc replace dev ens3 root handle 1: htb default 10",
		"tc qdisc replace dev ens3 root fq",
	} {
		if !strings.Contains(output.String(), expected) {
			t.Fatalf("missing %q in:\n%s", expected, output.String())
		}
	}
}

func TestTCOutputRequiresShapingRecommendation(t *testing.T) {
	t.Parallel()

	recommendation, err := model.Recommend(model.Inputs{
		BandwidthMbps: 100,
		RTTMillis:     20,
		MemoryBytes:   512 * 1024 * 1024,
		PageSize:      4_096,
		Profile:       model.ProfileProxy,
	}, model.Measurements{})
	if err != nil {
		t.Fatal(err)
	}
	if err := Recommendation(&bytes.Buffer{}, recommendation, FormatTC); err == nil {
		t.Fatal("expected tc output without shaping to fail")
	}
}

func shapingRecommendation(t *testing.T) model.Recommendation {
	t.Helper()
	recommendation, err := model.Recommend(model.Inputs{
		BandwidthMbps: 1_000,
		RTTMillis:     20,
		MemoryBytes:   1024 * 1024 * 1024,
		PageSize:      4_096,
		Profile:       model.ProfileBalanced,
		Shaping: &model.ShapingInput{
			Interface: "ens3",
			RateMbps:  950,
			Source:    "explicit",
		},
	}, model.Measurements{})
	if err != nil {
		t.Fatal(err)
	}
	return recommendation
}
