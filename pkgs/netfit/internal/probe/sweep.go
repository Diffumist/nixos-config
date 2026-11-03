package probe

import (
	"context"
	"fmt"
	"math"
	"sort"

	"github.com/diffumist/nixos-config/pkgs/netfit/internal/model"
)

type Options struct {
	NominalMbps float64
	Samples     int
	Progress    ProgressFunc
}

type ProgressEvent struct {
	Phase   string
	Current int
	Total   int
	Message string
}

type ProgressFunc func(ProgressEvent)

type MeasurementRunner interface {
	RunTCP(context.Context, SelectedPeer, float64) (TCPResult, error)
}

type TCPSweepOutcome string

const (
	TCPSweepKnee           TCPSweepOutcome = "knee"
	TCPSweepNoKnee         TCPSweepOutcome = "no-knee"
	TCPSweepOutOfRange     TCPSweepOutcome = "out-of-range"
	TCPSweepPeerBottleneck TCPSweepOutcome = "peer-bottleneck"
)

type TCPPoint struct {
	TargetMbps            float64 `json:"targetMbps"`
	Stage                 string  `json:"stage"`
	ReceiverMbps          float64 `json:"receiverMbps"`
	RetransmitsPerGiB     float64 `json:"retransmitsPerGiB"`
	DeliveryPasses        int     `json:"deliveryPasses"`
	RetransmitSpikePasses int     `json:"retransmitSpikePasses,omitempty"`
	SampleCount           int     `json:"sampleCount"`
}

type Report struct {
	Peer             SelectedPeer    `json:"peer"`
	TCPBaseline      TCPResult       `json:"tcpBaseline"`
	TCPSweep         []TCPPoint      `json:"tcpSweep"`
	TCPSweepOutcome  TCPSweepOutcome `json:"tcpSweepOutcome"`
	TCPScannedToMbps float64         `json:"tcpScannedToMbps"`
	TCPKneeMbps      float64         `json:"tcpKneeMbps,omitempty"`
	TCPShapeMbps     float64         `json:"tcpShapeMbps,omitempty"`
	Warnings         []string        `json:"warnings,omitempty"`
}

func Run(ctx context.Context, runner MeasurementRunner, peer SelectedPeer, options Options) (Report, error) {
	if options.Samples < 1 || options.Samples > 9 || options.Samples%2 == 0 {
		return Report{}, fmt.Errorf("samples must be an odd number between 1 and 9")
	}
	if math.IsNaN(options.NominalMbps) || math.IsInf(options.NominalMbps, 0) || options.NominalMbps < 0 {
		return Report{}, fmt.Errorf("nominal bandwidth must be finite and non-negative")
	}

	baselineTarget := 0.0
	if peer.MaxMbps > 0 {
		baselineTarget = peer.MaxMbps
		if options.NominalMbps > 0 {
			baselineTarget = math.Min(baselineTarget, options.NominalMbps*1.30)
		}
	}
	options.emit(ProgressEvent{Phase: "tcp", Message: "running baseline"})
	baseline, err := runner.RunTCP(ctx, peer, baselineTarget)
	if err != nil {
		return Report{}, err
	}
	peer.Port = baseline.Port
	report := Report{Peer: peer, TCPBaseline: baseline}
	options.emit(ProgressEvent{
		Phase: "tcp",
		Message: fmt.Sprintf("baseline %.2f Mbps, %.2f retransmits/GiB, RTT %.2f ms",
			baseline.ReceiverMbps, baseline.RetransmitsPerGiB, baseline.MeanRTTMillis),
	})

	anchor := options.NominalMbps
	if anchor <= 0 {
		anchor = baseline.ReceiverMbps
	} else if baseline.ReceiverMbps < anchor*0.70 {
		report.Warnings = append(report.Warnings,
			fmt.Sprintf("TCP baseline %.2f Mbps is below 70%% of nominal %.2f Mbps; the peer or path may be the bottleneck", baseline.ReceiverMbps, anchor))
		anchor = baseline.ReceiverMbps
	}
	if anchor <= 0 {
		return Report{}, fmt.Errorf("TCP baseline returned zero throughput")
	}
	upperFactor := tcpSweepUpperFactor(baseline.RetransmitsPerGiB)
	if peer.MaxMbps > 0 && anchor*upperFactor > peer.MaxMbps {
		report.Warnings = append(report.Warnings,
			fmt.Sprintf("TCP probing was capped at %.2f Mbps for the built-in public peer", peer.MaxMbps))
	}
	tcpRates := scaledRates(anchor, sweepFactors(0.90, upperFactor, 0.10), peer.MaxMbps)
	baseRetransmits := 0.0
	lastStable := 0.0
	coarseKnee := 0.0
	peerBottleneck := false
	for index, rate := range tcpRates {
		point, results, err := sampleTCP(ctx, runner, peer, rate, options.Samples, func(sample int) {
			options.emit(ProgressEvent{
				Phase:   "tcp",
				Current: index + 1,
				Total:   len(tcpRates),
				Message: fmt.Sprintf("%.0f Mbps, sample %d/%d", rate, sample, options.Samples),
			})
		})
		if err != nil {
			return Report{}, err
		}
		point.Stage = "coarse"
		options.emit(ProgressEvent{
			Phase:   "tcp",
			Current: index + 1,
			Total:   len(tcpRates),
			Message: fmt.Sprintf("%.0f Mbps result: %.2f Mbps, %.2f retransmits/GiB",
				rate, point.ReceiverMbps, point.RetransmitsPerGiB),
		})
		if index == 0 {
			baseRetransmits = point.RetransmitsPerGiB
		} else {
			spikeFloor := math.Max(100, baseRetransmits*10)
			point.RetransmitSpikePasses = countTCPRetransmitSpikes(results, spikeFloor)
		}
		report.TCPSweep = append(report.TCPSweep, point)
		report.TCPScannedToMbps = math.Max(report.TCPScannedToMbps, rate)
		if index > 0 && majority(point.RetransmitSpikePasses, options.Samples) {
			coarseKnee = rate
			break
		}
		if !majority(point.DeliveryPasses, options.Samples) {
			report.Warnings = append(report.Warnings, "TCP peer or path could not sustain the requested pacing rate; no drop knee was inferred")
			peerBottleneck = true
			break
		}
		lastStable = rate
	}

	if coarseKnee > 0 {
		refinedKnee := coarseKnee
		refinedStable := lastStable
		fineRates := refinementRates(lastStable, coarseKnee)
		for index, rate := range fineRates {
			point, results, err := sampleTCP(ctx, runner, peer, rate, options.Samples, func(sample int) {
				options.emit(ProgressEvent{
					Phase:   "tcp-refine",
					Current: index + 1,
					Total:   len(fineRates),
					Message: fmt.Sprintf("%.0f Mbps, sample %d/%d", rate, sample, options.Samples),
				})
			})
			if err != nil {
				return Report{}, err
			}
			point.Stage = "fine"
			point.RetransmitSpikePasses = countTCPRetransmitSpikes(results, math.Max(100, baseRetransmits*10))
			options.emit(ProgressEvent{
				Phase:   "tcp-refine",
				Current: index + 1,
				Total:   len(fineRates),
				Message: fmt.Sprintf("%.0f Mbps result: %.2f Mbps, %.2f retransmits/GiB",
					rate, point.ReceiverMbps, point.RetransmitsPerGiB),
			})
			report.TCPSweep = append(report.TCPSweep, point)
			if majority(point.RetransmitSpikePasses, options.Samples) {
				refinedKnee = rate
				break
			}
			if !majority(point.DeliveryPasses, options.Samples) {
				report.Warnings = append(report.Warnings,
					"TCP peer or path could not sustain a fine-scan rate; the confirmed coarse knee was retained")
				break
			}
			refinedStable = rate
		}
		report.TCPSweepOutcome = TCPSweepKnee
		report.TCPKneeMbps = refinedKnee
		if refinedStable > 0 {
			report.TCPShapeMbps = math.Max(1, refinedStable-model.ShapeMargin(refinedStable))
		}
		options.emit(ProgressEvent{Phase: "tcp", Message: fmt.Sprintf("retransmission knee %.2f Mbps, shaping recommendation %.2f Mbps", report.TCPKneeMbps, report.TCPShapeMbps)})
	} else if peerBottleneck {
		report.TCPSweepOutcome = TCPSweepPeerBottleneck
		options.emit(ProgressEvent{Phase: "tcp", Message: "peer or path bottleneck prevented knee detection"})
	} else if baseline.RetransmitsPerGiB > math.Max(100, baseRetransmits*10) {
		report.TCPSweepOutcome = TCPSweepOutOfRange
		report.Warnings = append(report.Warnings,
			fmt.Sprintf("TCP baseline retransmission rate was elevated, but no knee was found through %.2f Mbps; the knee may be above the scanned range", report.TCPScannedToMbps))
		options.emit(ProgressEvent{Phase: "tcp", Message: "retransmission knee may be above the scanned range"})
	} else {
		report.TCPSweepOutcome = TCPSweepNoKnee
		report.Warnings = append(report.Warnings, "No TCP retransmission knee was observed; this does not exclude a lossless shaper")
		options.emit(ProgressEvent{Phase: "tcp", Message: "no retransmission knee observed"})
	}

	return report, nil
}

func sampleTCP(ctx context.Context, runner MeasurementRunner, peer SelectedPeer, rate float64, samples int, onSample func(int)) (TCPPoint, []TCPResult, error) {
	throughputs := make([]float64, 0, samples)
	retransmits := make([]float64, 0, samples)
	results := make([]TCPResult, 0, samples)
	deliveryPasses := 0
	for sample := 1; sample <= samples; sample++ {
		onSample(sample)
		result, err := runner.RunTCP(ctx, peer, rate)
		if err != nil {
			return TCPPoint{}, nil, err
		}
		results = append(results, result)
		throughputs = append(throughputs, result.ReceiverMbps)
		retransmits = append(retransmits, result.RetransmitsPerGiB)
		if result.ReceiverMbps >= rate*0.70 {
			deliveryPasses++
		}
	}
	return TCPPoint{
		TargetMbps:        rate,
		ReceiverMbps:      median(throughputs),
		RetransmitsPerGiB: median(retransmits),
		DeliveryPasses:    deliveryPasses,
		SampleCount:       samples,
	}, results, nil
}

func (options Options) emit(event ProgressEvent) {
	if options.Progress != nil {
		options.Progress(event)
	}
}

func scaledRates(anchor float64, factors []float64, maximum float64) []float64 {
	rates := make([]float64, 0, len(factors))
	for _, factor := range factors {
		rate := math.Max(1, math.Round(anchor*factor))
		if maximum > 0 {
			rate = math.Min(rate, maximum)
		}
		if len(rates) == 0 || rates[len(rates)-1] != rate {
			rates = append(rates, rate)
		}
	}
	sort.Float64s(rates)
	return rates
}

func tcpSweepUpperFactor(retransmitsPerGiB float64) float64 {
	const tcpPayloadBytes = 1_448
	retransmittedFraction := retransmitsPerGiB * tcpPayloadBytes / float64(1<<30)
	return math.Min(2.50, math.Max(1.30, 1.30+2*retransmittedFraction))
}

func sweepFactors(lower, upper, step float64) []float64 {
	factors := make([]float64, 0, int(math.Ceil((upper-lower)/step))+1)
	for factor := lower; factor < upper-1e-9; factor += step {
		factors = append(factors, factor)
	}
	return append(factors, upper)
}

func refinementRates(lower, upper float64) []float64 {
	if upper-lower <= 1 {
		return nil
	}
	rates := make([]float64, 0, 3)
	for part := 1; part < 4; part++ {
		rate := math.Round(lower + (upper-lower)*float64(part)/4)
		if rate <= lower || rate >= upper || len(rates) > 0 && rates[len(rates)-1] == rate {
			continue
		}
		rates = append(rates, rate)
	}
	return rates
}

func countTCPRetransmitSpikes(results []TCPResult, threshold float64) int {
	count := 0
	for _, result := range results {
		if result.RetransmitsPerGiB > threshold {
			count++
		}
	}
	return count
}

func majority(passes, samples int) bool {
	return passes > samples/2
}
