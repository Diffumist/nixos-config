package model

import (
	"fmt"
	"math"
	"sort"
	"strconv"
	"strings"
)

const SchemaVersion = 4

type Profile string

type RTTSource string

const (
	ProfileProxy    Profile = "proxy"
	ProfileBalanced Profile = "balanced"
	ProfileBulk     Profile = "bulk"

	RTTSourceExplicit RTTSource = "explicit"
	RTTSourceMeasured RTTSource = "measured"
	RTTSourceAssumed  RTTSource = "assumed"
)

type Inputs struct {
	BandwidthMbps float64        `json:"bandwidthMbps"`
	RTTMillis     float64        `json:"rttMillis"`
	RTTSource     RTTSource      `json:"rttSource"`
	MemoryBytes   uint64         `json:"memoryBytes"`
	PageSize      uint64         `json:"pageSize"`
	Profile       Profile        `json:"profile"`
	Current       CurrentSysctls `json:"currentSysctls"`
	Shaping       *ShapingInput  `json:"shaping,omitempty"`
}

type ShapingInput struct {
	Interface string  `json:"interface"`
	RateMbps  float64 `json:"rateMbps"`
	Source    string  `json:"source"`
}

type CurrentSysctls struct {
	CoreReceiveMaximum uint64 `json:"coreReceiveMaximumBytes,omitempty"`
	CoreSendMaximum    uint64 `json:"coreSendMaximumBytes,omitempty"`
	TCPReceiveMinimum  uint64 `json:"tcpReceiveMinimumBytes,omitempty"`
	TCPReceiveDefault  uint64 `json:"tcpReceiveDefaultBytes,omitempty"`
	TCPReceiveMaximum  uint64 `json:"tcpReceiveMaximumBytes,omitempty"`
	TCPSendMinimum     uint64 `json:"tcpSendMinimumBytes,omitempty"`
	TCPSendDefault     uint64 `json:"tcpSendDefaultBytes,omitempty"`
	TCPSendMaximum     uint64 `json:"tcpSendMaximumBytes,omitempty"`
}

type Measurements struct {
	Peer                 string  `json:"peer,omitempty"`
	TCPBaselineMbps      float64 `json:"tcpBaselineMbps,omitempty"`
	TCPRetransmitsPerGiB float64 `json:"tcpRetransmitsPerGiB,omitempty"`
	TCPKneeMbps          float64 `json:"tcpKneeMbps,omitempty"`
	TCPShapeMbps         float64 `json:"tcpShapeMbps,omitempty"`
}

type TCPRecommendation struct {
	BDPBytes       uint64                    `json:"bdpBytes"`
	ReceiveMinimum uint64                    `json:"receiveMinimumBytes"`
	ReceiveDefault uint64                    `json:"receiveDefaultBytes"`
	ReceiveMaximum uint64                    `json:"receiveMaximumBytes"`
	SendMinimum    uint64                    `json:"sendMinimumBytes"`
	SendDefault    uint64                    `json:"sendDefaultBytes"`
	SendMaximum    uint64                    `json:"sendMaximumBytes"`
	Congestion     string                    `json:"congestionControl"`
	DefaultQdisc   string                    `json:"defaultQdisc"`
	Shaping        *TCPShapingRecommendation `json:"shaping,omitempty"`
}

type TCPShapingRecommendation struct {
	Interface    string  `json:"interface"`
	RateMbps     float64 `json:"rateMbps"`
	Source       string  `json:"source"`
	Scope        string  `json:"scope"`
	RootQdisc    string  `json:"rootQdisc"`
	RootHandle   string  `json:"rootHandle"`
	ClassID      string  `json:"classId"`
	LeafQdisc    string  `json:"leafQdisc"`
	LeafHandle   string  `json:"leafHandle"`
	StopBehavior string  `json:"stopBehavior"`
}

type Recommendation struct {
	SchemaVersion int               `json:"schemaVersion"`
	Inputs        Inputs            `json:"inputs"`
	Measurements  *Measurements     `json:"measurements,omitempty"`
	TCP           TCPRecommendation `json:"tcp"`
	KernelModules []string          `json:"kernelModules"`
	Sysctls       map[string]string `json:"sysctls"`
	KernelManaged []string          `json:"kernelManaged"`
	Omitted       map[string]string `json:"omitted"`
	Confidence    string            `json:"confidence"`
	Warnings      []string          `json:"warnings,omitempty"`
}

type profilePolicy struct {
	tcpHeadroom   uint64
	bufferDivisor uint64
	absoluteCap   uint64
}

func ParseProfile(value string) (Profile, error) {
	profile := Profile(value)
	switch profile {
	case ProfileProxy, ProfileBalanced, ProfileBulk:
		return profile, nil
	default:
		return "", fmt.Errorf("profile must be proxy, balanced, or bulk")
	}
}

func Recommend(inputs Inputs, measurements Measurements) (Recommendation, error) {
	if !finite(inputs.BandwidthMbps) || inputs.BandwidthMbps <= 0 || inputs.BandwidthMbps > 1_000_000 {
		return Recommendation{}, fmt.Errorf("bandwidth must be between 0 and 1000000 Mbps")
	}
	if !finite(inputs.RTTMillis) || inputs.RTTMillis <= 0 || inputs.RTTMillis > 60_000 {
		return Recommendation{}, fmt.Errorf("RTT must be between 0 and 60000 ms")
	}
	if inputs.RTTSource == "" {
		inputs.RTTSource = RTTSourceExplicit
	}
	if inputs.RTTSource != RTTSourceExplicit && inputs.RTTSource != RTTSourceMeasured && inputs.RTTSource != RTTSourceAssumed {
		return Recommendation{}, fmt.Errorf("RTT source must be explicit, measured, or assumed")
	}
	if inputs.MemoryBytes < 64*mebibyte {
		return Recommendation{}, fmt.Errorf("memory must be at least 64 MiB")
	}
	if inputs.PageSize < 4_096 || inputs.PageSize > 65_536 || inputs.PageSize&(inputs.PageSize-1) != 0 {
		return Recommendation{}, fmt.Errorf("page size must be a power of two between 4096 and 65536")
	}
	if inputs.Shaping != nil {
		if !finite(inputs.Shaping.RateMbps) || inputs.Shaping.RateMbps <= 0 || inputs.Shaping.RateMbps > 1_000_000 {
			return Recommendation{}, fmt.Errorf("shaping rate must be between 0 and 1000000 Mbps")
		}
		if !validInterfaceName(inputs.Shaping.Interface) {
			return Recommendation{}, fmt.Errorf("shaping interface must be a valid Linux interface name")
		}
		if inputs.Shaping.Source != "explicit" && inputs.Shaping.Source != "measured" {
			return Recommendation{}, fmt.Errorf("shaping source must be explicit or measured")
		}
	}

	policy, err := policyFor(inputs.Profile)
	if err != nil {
		return Recommendation{}, err
	}
	if !validMeasurements(measurements) {
		return Recommendation{}, fmt.Errorf("measurements must be finite and non-negative")
	}

	bdp := bytesForWindow(inputs.BandwidthMbps, inputs.RTTMillis)
	memoryCap := inputs.MemoryBytes / policy.bufferDivisor
	if memoryCap > policy.absoluteCap {
		memoryCap = policy.absoluteCap
	}
	if memoryCap == 0 {
		return Recommendation{}, fmt.Errorf("memory policy produced a zero buffer cap")
	}
	floor := min(4*mebibyte, memoryCap)
	tcpTarget := saturatingMultiply(bdp, policy.tcpHeadroom)
	tcpDerived := pageAlignedClamp(tcpTarget, floor, memoryCap, inputs.PageSize)
	tcpReceiveMaximum := max(tcpDerived, inputs.Current.TCPReceiveMaximum)
	tcpSendMaximum := max(tcpDerived, inputs.Current.TCPSendMaximum)
	tcpReceiveDefault := max(min(131_072, tcpReceiveMaximum), inputs.Current.TCPReceiveDefault)
	tcpSendDefault := max(min(16_384, tcpSendMaximum), inputs.Current.TCPSendDefault)
	tcpReceiveMaximum = max(tcpReceiveMaximum, tcpReceiveDefault)
	tcpSendMaximum = max(tcpSendMaximum, tcpSendDefault)
	tcpReceiveMinimum := max(uint64(4_096), inputs.Current.TCPReceiveMinimum)
	tcpSendMinimum := max(uint64(4_096), inputs.Current.TCPSendMinimum)
	tcpReceiveDefault = max(tcpReceiveDefault, tcpReceiveMinimum)
	tcpSendDefault = max(tcpSendDefault, tcpSendMinimum)
	tcpReceiveMaximum = max(tcpReceiveMaximum, tcpReceiveDefault)
	tcpSendMaximum = max(tcpSendMaximum, tcpSendDefault)

	coreReceiveMaximum := max(tcpReceiveMaximum, inputs.Current.CoreReceiveMaximum)
	coreSendMaximum := max(tcpSendMaximum, inputs.Current.CoreSendMaximum)
	sysctls := map[string]string{
		"net.core.default_qdisc":          "fq",
		"net.core.rmem_max":               strconv.FormatUint(coreReceiveMaximum, 10),
		"net.core.wmem_max":               strconv.FormatUint(coreSendMaximum, 10),
		"net.ipv4.tcp_congestion_control": "bbr",
		"net.ipv4.tcp_moderate_rcvbuf":    "1",
		"net.ipv4.tcp_rmem":               fmt.Sprintf("%d %d %d", tcpReceiveMinimum, tcpReceiveDefault, tcpReceiveMaximum),
		"net.ipv4.tcp_wmem":               fmt.Sprintf("%d %d %d", tcpSendMinimum, tcpSendDefault, tcpSendMaximum),
	}

	warnings := []string{
		"tcp_mem remains kernel-managed because its boot-time default depends on available buffer pages.",
	}
	if tcpTarget > memoryCap {
		warnings = append(warnings, "TCP buffer maximum was capped by the selected memory policy.")
	}
	if measurements.Peer == "" {
		warnings = append(warnings, "No active measurement was supplied; confidence is model-only.")
	}
	if inputs.RTTSource == RTTSourceAssumed {
		warnings = append(warnings,
			fmt.Sprintf("RTT %.2f ms was assumed because an automatic public peer does not represent the target workload path; override it with --rtt.", inputs.RTTMillis))
	}

	confidence := "low"
	var measurementOutput *Measurements
	if measurements.Peer != "" {
		confidence = "medium"
		measurementOutput = &measurements
	}

	var shaping *TCPShapingRecommendation
	var kernelModules []string
	if inputs.Shaping != nil {
		shaping = &TCPShapingRecommendation{
			Interface:    inputs.Shaping.Interface,
			RateMbps:     inputs.Shaping.RateMbps,
			Source:       inputs.Shaping.Source,
			Scope:        "all-egress",
			RootQdisc:    "htb",
			RootHandle:   "1:",
			ClassID:      "1:10",
			LeafQdisc:    "fq",
			LeafHandle:   "10:",
			StopBehavior: "replace-root-with-fq",
		}
		kernelModules = append(kernelModules, "sch_htb", "sch_fq")
		warnings = append(warnings,
			"HTB is an aggregate root shaper and therefore limits all egress traffic on the selected interface, not only TCP.",
			"Applying the shaping output replaces the interface's current root qdisc; the previous qdisc cannot be restored without a complete external snapshot.",
			"Stopping the generated NixOS service replaces the root qdisc with unshaped fq.",
		)
		if inputs.Shaping.RateMbps > inputs.BandwidthMbps {
			warnings = append(warnings, "The shaping rate exceeds the modeled path bandwidth.")
		}
	}

	return Recommendation{
		SchemaVersion: SchemaVersion,
		Inputs:        inputs,
		Measurements:  measurementOutput,
		TCP: TCPRecommendation{
			BDPBytes:       bdp,
			ReceiveMinimum: tcpReceiveMinimum,
			ReceiveDefault: tcpReceiveDefault,
			ReceiveMaximum: tcpReceiveMaximum,
			SendMinimum:    tcpSendMinimum,
			SendDefault:    tcpSendDefault,
			SendMaximum:    tcpSendMaximum,
			Congestion:     "bbr",
			DefaultQdisc:   "fq",
			Shaping:        shaping,
		},
		KernelModules: kernelModules,
		Sysctls:       sysctls,
		KernelManaged: []string{"net.ipv4.tcp_mem"},
		Omitted: map[string]string{
			"net.core.rmem_default": "global default growth is not justified by a per-path measurement",
			"net.core.wmem_default": "global default growth is not justified by a per-path measurement",
		},
		Confidence: confidence,
		Warnings:   warnings,
	}, nil
}

func SortedSysctlKeys(sysctls map[string]string) []string {
	keys := make([]string, 0, len(sysctls))
	for key := range sysctls {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func ShapeMargin(bandwidthMbps float64) float64 {
	return math.Max(5, math.Min(40, math.Round(bandwidthMbps*0.02)))
}

func finite(value float64) bool {
	return !math.IsNaN(value) && !math.IsInf(value, 0)
}

func validInterfaceName(name string) bool {
	if len(name) == 0 || len(name) > 15 {
		return false
	}
	for _, character := range name {
		if character >= 'a' && character <= 'z' ||
			character >= 'A' && character <= 'Z' ||
			character >= '0' && character <= '9' ||
			strings.ContainsRune("_.:@-", character) {
			continue
		}
		return false
	}
	return true
}

func validMeasurements(measurements Measurements) bool {
	values := []float64{
		measurements.TCPBaselineMbps,
		measurements.TCPRetransmitsPerGiB,
		measurements.TCPKneeMbps,
		measurements.TCPShapeMbps,
	}
	for _, value := range values {
		if !finite(value) || value < 0 {
			return false
		}
	}
	return true
}

func policyFor(profile Profile) (profilePolicy, error) {
	switch profile {
	case ProfileProxy:
		return profilePolicy{tcpHeadroom: 2, bufferDivisor: 64, absoluteCap: 16 * mebibyte}, nil
	case ProfileBalanced:
		return profilePolicy{tcpHeadroom: 2, bufferDivisor: 32, absoluteCap: 64 * mebibyte}, nil
	case ProfileBulk:
		return profilePolicy{tcpHeadroom: 4, bufferDivisor: 16, absoluteCap: 256 * mebibyte}, nil
	default:
		return profilePolicy{}, fmt.Errorf("unsupported profile %q", profile)
	}
}

func bytesForWindow(mbps, millis float64) uint64 {
	value := mbps * 1_000_000 / 8 * millis / 1_000
	if value >= math.MaxUint64 {
		return math.MaxUint64
	}
	return uint64(math.Ceil(value))
}

func saturatingMultiply(value, factor uint64) uint64 {
	if factor != 0 && value > math.MaxUint64/factor {
		return math.MaxUint64
	}
	return value * factor
}

func clamp(value, minimum, maximum uint64) uint64 {
	if value < minimum {
		return minimum
	}
	if value > maximum {
		return maximum
	}
	return value
}

func roundUpToPage(value, pageSize uint64) uint64 {
	if value == 0 || value%pageSize == 0 {
		return value
	}
	if value > math.MaxUint64-(pageSize-value%pageSize) {
		return math.MaxUint64 - math.MaxUint64%pageSize
	}
	return value + pageSize - value%pageSize
}

func pageAlignedClamp(value, minimum, maximum, pageSize uint64) uint64 {
	value = roundUpToPage(clamp(value, minimum, maximum), pageSize)
	if value <= maximum {
		return value
	}
	return maximum - maximum%pageSize
}

func max(a, b uint64) uint64 {
	if a > b {
		return a
	}
	return b
}

func min(a, b uint64) uint64 {
	if a < b {
		return a
	}
	return b
}

const (
	kibibyte = uint64(1024)
	mebibyte = 1024 * kibibyte
)
