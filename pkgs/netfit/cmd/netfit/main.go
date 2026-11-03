package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"math"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/diffumist/nixos-config/pkgs/netfit/internal/model"
	"github.com/diffumist/nixos-config/pkgs/netfit/internal/probe"
	"github.com/diffumist/nixos-config/pkgs/netfit/internal/render"
	"github.com/diffumist/nixos-config/pkgs/netfit/internal/systeminfo"
)

const (
	version              = "0.4.1"
	automaticPublicRTTMS = 150
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, os.Args[1:], os.Stdout, os.Stderr); err != nil {
		fmt.Fprintln(os.Stderr, "netfit:", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, arguments []string, stdout, stderr io.Writer) error {
	if len(arguments) == 0 || arguments[0] == "--help" || arguments[0] == "-h" || arguments[0] == "help" {
		writeUsage(stdout)
		return nil
	}

	switch arguments[0] {
	case "version", "--version":
		if len(arguments) != 1 {
			return fmt.Errorf("version does not accept arguments")
		}
		_, err := fmt.Fprintf(stdout, "netfit %s\n", version)
		return err
	case "facts":
		return runFacts(arguments[1:], stdout, stderr)
	case "peers":
		return runPeers(arguments[1:], stdout, stderr)
	case "recommend":
		return runRecommend(ctx, arguments[1:], stdout, stderr)
	default:
		return fmt.Errorf("unknown command %q; use --help", arguments[0])
	}
}

func runFacts(arguments []string, stdout, stderr io.Writer) error {
	flags := flag.NewFlagSet("facts", flag.ContinueOnError)
	flags.SetOutput(stderr)
	formatValue := flags.String("format", "text", "text or json")
	if err := flags.Parse(arguments); err != nil {
		return err
	}
	if flags.NArg() != 0 {
		return fmt.Errorf("unexpected arguments: %s", strings.Join(flags.Args(), " "))
	}

	facts, err := systeminfo.Detect()
	if err != nil {
		return err
	}
	if *formatValue == "json" {
		return render.JSON(stdout, facts)
	}
	if *formatValue != "text" {
		return fmt.Errorf("facts format must be text or json")
	}
	_, err = fmt.Fprintf(stdout,
		"interface: %s\nmtu: %d\ngateway: %s\nqdiscs: %s\nlink speed: %.2f Mbps\nmemory: %d bytes\npage size: %d\ncpus: %d\n",
		facts.Interface, facts.MTU, facts.Gateway, strings.Join(facts.Qdiscs, ","), facts.LinkSpeedMbps,
		facts.MemoryBytes, facts.PageSize, facts.CPUs)
	if err != nil {
		return err
	}
	for _, warning := range facts.Warnings {
		if _, err := fmt.Fprintln(stdout, "warning:", warning); err != nil {
			return err
		}
	}
	return nil
}

func runPeers(arguments []string, stdout, stderr io.Writer) error {
	flags := flag.NewFlagSet("peers", flag.ContinueOnError)
	flags.SetOutput(stderr)
	formatValue := flags.String("format", "text", "text or json")
	if err := flags.Parse(arguments); err != nil {
		return err
	}
	if flags.NArg() != 0 {
		return fmt.Errorf("unexpected arguments: %s", strings.Join(flags.Args(), " "))
	}
	if *formatValue == "json" {
		return render.JSON(stdout, probe.BuiltinPeers)
	}
	if *formatValue != "text" {
		return fmt.Errorf("peers format must be text or json")
	}
	for _, peer := range probe.BuiltinPeers {
		if _, err := fmt.Fprintf(stdout, "%-42s %-14s %s\n", peer.Host, peer.Region, peer.Provider); err != nil {
			return err
		}
	}
	return nil
}

func runRecommend(ctx context.Context, arguments []string, stdout, stderr io.Writer) error {
	flags := flag.NewFlagSet("recommend", flag.ContinueOnError)
	flags.SetOutput(stderr)
	bandwidth := flags.Float64("bandwidth", 0, "target bandwidth in Mbps")
	rtt := flags.Float64("rtt", 0, "target path RTT in milliseconds")
	profileValue := flags.String("profile", "balanced", "proxy, balanced, or bulk")
	peerValue := flags.String("peer", "", "iperf3 peer host[:port], or auto")
	ipFamilyValue := flags.String("ip-family", "auto", "iperf3 address family: auto, 4, or 6")
	duration := flags.Int("duration", 5, "seconds per iperf3 sample")
	omit := flags.Int("omit", 2, "iperf3 warm-up seconds to omit")
	samples := flags.Int("samples", 3, "samples per paced rate")
	shapeRate := flags.Float64("shape-rate", 0, "explicit aggregate egress shaping rate in Mbps")
	interfaceName := flags.String("interface", "", "interface to shape; defaults to the main-table default route")
	formatValue := flags.String("format", "text", "text, json, nix, or tc")
	probeTimeout := flags.Duration("timeout", 10*time.Minute, "overall active measurement timeout")
	quiet := flags.Bool("quiet", false, "suppress active measurement progress on stderr")
	if err := flags.Parse(arguments); err != nil {
		return err
	}
	if flags.NArg() != 0 {
		return fmt.Errorf("unexpected arguments: %s", strings.Join(flags.Args(), " "))
	}
	if *duration < 1 || *duration > 300 || *omit < 0 || *omit > 60 {
		return fmt.Errorf("duration must be 1-300 and omit must be 0-60 seconds")
	}
	if *samples < 1 || *samples > 9 || *samples%2 == 0 {
		return fmt.Errorf("samples must be an odd number between 1 and 9")
	}
	if !finite(*bandwidth) || *bandwidth < 0 || *bandwidth > 1_000_000 {
		return fmt.Errorf("bandwidth must be between 0 and 1000000 Mbps")
	}
	if !finite(*rtt) || *rtt < 0 || *rtt > 60_000 {
		return fmt.Errorf("RTT must be between 0 and 60000 ms")
	}
	if !finite(*shapeRate) || *shapeRate < 0 || *shapeRate > 1_000_000 {
		return fmt.Errorf("shaping rate must be between 0 and 1000000 Mbps")
	}
	if *probeTimeout <= 0 {
		return fmt.Errorf("timeout must be positive")
	}

	profile, err := model.ParseProfile(*profileValue)
	if err != nil {
		return err
	}
	format, err := render.ParseFormat(*formatValue)
	if err != nil {
		return err
	}
	ipFamily, err := probe.ParseIPFamily(*ipFamilyValue)
	if err != nil {
		return err
	}
	facts, err := systeminfo.Detect()
	if err != nil {
		return err
	}

	measurements := model.Measurements{}
	var activeReport *probe.Report
	peerInterface := ""
	peerRouteWarning := ""
	rttSource := model.RTTSourceExplicit
	if *peerValue != "" {
		activeContext, cancel := context.WithTimeout(ctx, *probeTimeout)
		defer cancel()
		progress := progressLogger(stderr, *quiet)
		progress(probe.ProgressEvent{Phase: "peer", Message: "selecting iperf3 endpoint"})
		selected, err := resolvePeer(activeContext, *peerValue, ipFamily)
		if err != nil {
			return err
		}
		progress(probe.ProgressEvent{Phase: "peer", Message: fmt.Sprintf("selected %s:%d via IPv%s %s, connect %.2f ms", selected.Host, selected.Port, selected.IPFamily, selected.RemoteIP, selected.ConnectMillis)})
		if selected.RemoteIP == "" {
			peerRouteWarning = "selected peer did not expose its resolved IP; path-specific interface lookup was skipped"
		} else {
			peerInterface, err = systeminfo.InterfaceForDestination(selected.RemoteIP)
			if err != nil {
				peerRouteWarning = err.Error()
				progress(probe.ProgressEvent{Phase: "route", Message: "interface lookup failed: " + peerRouteWarning})
			} else {
				progress(probe.ProgressEvent{Phase: "route", Message: fmt.Sprintf("%s reaches %s", peerInterface, selected.RemoteIP)})
			}
		}
		if selected.MaxMbps > 0 && (*duration > 10 || *omit > 5 || *samples > 3 || *probeTimeout > 10*time.Minute) {
			return errors.New("built-in public peers require duration <= 10, omit <= 5, samples <= 3, and timeout <= 10m")
		}
		sampleTimeout := time.Duration(*duration+*omit+15) * time.Second
		progress(probe.ProgressEvent{Phase: "probe", Message: fmt.Sprintf("per-sample watchdog %s", sampleTimeout)})
		report, err := probe.Run(activeContext, probe.Runner{
			Binary: "iperf3", Duration: *duration, Omit: *omit, SampleTimeout: sampleTimeout,
		}, selected, probe.Options{
			NominalMbps: *bandwidth,
			Samples:     *samples,
			Progress:    progress,
		})
		if err != nil {
			return err
		}
		activeReport = &report
		measurements = model.Measurements{
			Peer:                 fmt.Sprintf("%s:%d", report.Peer.Host, report.Peer.Port),
			TCPBaselineMbps:      report.TCPBaseline.ReceiverMbps,
			TCPRetransmitsPerGiB: report.TCPBaseline.RetransmitsPerGiB,
			TCPKneeMbps:          report.TCPKneeMbps,
			TCPShapeMbps:         report.TCPShapeMbps,
		}
		if *bandwidth <= 0 {
			*bandwidth = report.TCPBaseline.ReceiverMbps
		}
		*rtt, rttSource = recommendationRTT(*peerValue, *rtt, report)
	}

	if *bandwidth <= 0 {
		return errors.New("bandwidth is path-specific; provide --bandwidth or --peer")
	}
	if *rtt <= 0 {
		return errors.New("RTT is path-specific; provide --rtt or --peer")
	}

	selectedShapeRate := *shapeRate
	shapeSource := "explicit"
	if selectedShapeRate == 0 && measurements.TCPShapeMbps > 0 {
		selectedShapeRate = measurements.TCPShapeMbps
		shapeSource = "measured"
	}
	var shaping *model.ShapingInput
	shapingWarning := ""
	if selectedShapeRate > 0 {
		selectedInterface := *interfaceName
		if selectedInterface == "" {
			selectedInterface = peerInterface
		}
		if selectedInterface == "" {
			selectedInterface = facts.Interface
		}
		if selectedInterface == "" {
			if *shapeRate > 0 || format == render.FormatTC {
				return errors.New("shaping requires an interface; provide --interface")
			}
			shapingWarning = fmt.Sprintf("Measured shaping rate %.2f Mbps was omitted because the egress interface could not be determined; provide --interface to generate shaping", selectedShapeRate)
		} else {
			shaping = &model.ShapingInput{
				Interface: selectedInterface,
				RateMbps:  selectedShapeRate,
				Source:    shapeSource,
			}
		}
	}

	recommendation, err := model.Recommend(model.Inputs{
		BandwidthMbps: *bandwidth,
		RTTMillis:     *rtt,
		RTTSource:     rttSource,
		MemoryBytes:   facts.MemoryBytes,
		PageSize:      facts.PageSize,
		Profile:       profile,
		Current:       facts.Current,
		Shaping:       shaping,
	}, measurements)
	if err != nil {
		return err
	}
	if activeReport != nil {
		recommendation.Warnings = append(recommendation.Warnings, activeReport.Warnings...)
	}
	if peerRouteWarning != "" {
		recommendation.Warnings = append(recommendation.Warnings, "Path-specific interface lookup failed: "+peerRouteWarning)
	}
	if shapingWarning != "" {
		recommendation.Warnings = append(recommendation.Warnings, shapingWarning)
	}
	recommendation.Warnings = append(recommendation.Warnings, facts.Warnings...)
	if format == render.FormatJSON && activeReport != nil {
		return render.JSON(stdout, struct {
			Recommendation model.Recommendation `json:"recommendation"`
			Probe          probe.Report         `json:"probe"`
		}{Recommendation: recommendation, Probe: *activeReport})
	}
	return render.Recommendation(stdout, recommendation, format)
}

func resolvePeer(ctx context.Context, value string, family probe.IPFamily) (probe.SelectedPeer, error) {
	if value == "auto" {
		return probe.SelectPeer(ctx, probe.BuiltinPeers, family)
	}
	peer, err := probe.ParsePeer(value)
	if err != nil {
		return probe.SelectedPeer{}, err
	}
	selected, err := probe.SelectPeer(ctx, []probe.Peer{peer}, family)
	if err != nil {
		return probe.SelectedPeer{}, err
	}
	return selected, nil
}

func recommendationRTT(peerValue string, explicit float64, report probe.Report) (float64, model.RTTSource) {
	if explicit > 0 {
		return explicit, model.RTTSourceExplicit
	}
	if peerValue == "auto" {
		return automaticPublicRTTMS, model.RTTSourceAssumed
	}
	if report.TCPBaseline.MeanRTTMillis > 0 {
		return report.TCPBaseline.MeanRTTMillis, model.RTTSourceMeasured
	}
	return report.Peer.ConnectMillis, model.RTTSourceMeasured
}

func writeUsage(writer io.Writer) {
	fmt.Fprintln(writer, `netfit is a read-only TCP tuning recommender.

Usage:
  netfit facts [--format text|json]
  netfit peers [--format text|json]
  netfit recommend --bandwidth Mbps --rtt ms [options]
  netfit recommend --peer auto|host[:port] [--ip-family auto|4|6] [options]
  netfit recommend --bandwidth Mbps --rtt ms --shape-rate Mbps [--interface IFACE] --format tc|nix
  netfit version

netfit never writes sysctls, routes, or qdiscs. Active measurement is opt-in
through --peer and uses iperf3 JSON output. Generated HTB shaping owns the
selected interface's root qdisc and applies to all egress traffic. Active
progress is written to stderr; use --quiet to suppress it.`)
}

func finite(value float64) bool {
	return !math.IsNaN(value) && !math.IsInf(value, 0)
}

func progressLogger(writer io.Writer, quiet bool) probe.ProgressFunc {
	return func(event probe.ProgressEvent) {
		if quiet {
			return
		}
		if event.Current > 0 && event.Total > 0 {
			fmt.Fprintf(writer, "netfit: [%s %d/%d] %s\n", event.Phase, event.Current, event.Total, event.Message)
			return
		}
		fmt.Fprintf(writer, "netfit: [%s] %s\n", event.Phase, event.Message)
	}
}
