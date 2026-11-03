package render

import (
	"encoding/json"
	"fmt"
	"io"
	"strconv"
	"strings"

	"github.com/diffumist/nixos-config/pkgs/netfit/internal/model"
)

type Format string

const (
	FormatText Format = "text"
	FormatJSON Format = "json"
	FormatNix  Format = "nix"
	FormatTC   Format = "tc"
)

func ParseFormat(value string) (Format, error) {
	format := Format(value)
	switch format {
	case FormatText, FormatJSON, FormatNix, FormatTC:
		return format, nil
	default:
		return "", fmt.Errorf("format must be text, json, nix, or tc")
	}
}

func Recommendation(writer io.Writer, recommendation model.Recommendation, format Format) error {
	switch format {
	case FormatText:
		return writeText(writer, recommendation)
	case FormatJSON:
		encoder := json.NewEncoder(writer)
		encoder.SetIndent("", "  ")
		return encoder.Encode(recommendation)
	case FormatNix:
		return writeNix(writer, recommendation)
	case FormatTC:
		return writeTC(writer, recommendation)
	default:
		return fmt.Errorf("unsupported format %q", format)
	}
}

func JSON(writer io.Writer, value any) error {
	encoder := json.NewEncoder(writer)
	encoder.SetIndent("", "  ")
	return encoder.Encode(value)
}

func writeText(writer io.Writer, recommendation model.Recommendation) error {
	lines := []string{
		"netfit recommendation",
		fmt.Sprintf("  profile             %s", recommendation.Inputs.Profile),
		fmt.Sprintf("  bandwidth           %.2f Mbps", recommendation.Inputs.BandwidthMbps),
		fmt.Sprintf("  RTT                 %.2f ms (%s)", recommendation.Inputs.RTTMillis, recommendation.Inputs.RTTSource),
		fmt.Sprintf("  confidence          %s", recommendation.Confidence),
		"",
		"TCP",
		fmt.Sprintf("  BDP                 %s", humanBytes(recommendation.TCP.BDPBytes)),
		fmt.Sprintf("  receive maximum     %s", humanBytes(recommendation.TCP.ReceiveMaximum)),
		fmt.Sprintf("  send maximum        %s", humanBytes(recommendation.TCP.SendMaximum)),
		fmt.Sprintf("  congestion/qdisc    %s/%s", recommendation.TCP.Congestion, recommendation.TCP.DefaultQdisc),
	}
	if shaping := recommendation.TCP.Shaping; shaping != nil {
		lines = append(lines,
			fmt.Sprintf("  shaping             %.2f Mbps on %s (%s)", shaping.RateMbps, shaping.Interface, shaping.Source),
			fmt.Sprintf("  shaping tree        %s root -> %s leaf", shaping.RootQdisc, shaping.LeafQdisc),
			fmt.Sprintf("  shaping scope       %s", shaping.Scope),
		)
	}
	lines = append(lines, "", "Sysctls")
	for _, key := range model.SortedSysctlKeys(recommendation.Sysctls) {
		lines = append(lines, fmt.Sprintf("  %-40s %s", key, recommendation.Sysctls[key]))
	}
	if len(recommendation.Warnings) > 0 {
		lines = append(lines, "", "Warnings")
		for _, warning := range recommendation.Warnings {
			lines = append(lines, "  - "+warning)
		}
	}
	_, err := fmt.Fprintln(writer, strings.Join(lines, "\n"))
	return err
}

func writeNix(writer io.Writer, recommendation model.Recommendation) error {
	header := "{"
	if recommendation.TCP.Shaping != nil {
		header = "{ pkgs, ... }:\n{"
	}
	if _, err := fmt.Fprintln(writer, header); err != nil {
		return err
	}
	if len(recommendation.KernelModules) > 0 {
		if _, err := fmt.Fprint(writer, "  boot.kernelModules = ["); err != nil {
			return err
		}
		for _, module := range recommendation.KernelModules {
			if _, err := fmt.Fprintf(writer, " %q", module); err != nil {
				return err
			}
		}
		if _, err := fmt.Fprintln(writer, " ];"); err != nil {
			return err
		}
	}
	if _, err := fmt.Fprintln(writer, "  boot.kernel.sysctl = {"); err != nil {
		return err
	}
	for _, key := range model.SortedSysctlKeys(recommendation.Sysctls) {
		value := nixValue(recommendation.Sysctls[key])
		if _, err := fmt.Fprintf(writer, "    %q = %s;\n", key, value); err != nil {
			return err
		}
	}
	if _, err := fmt.Fprintln(writer, "  };"); err != nil {
		return err
	}
	if len(recommendation.Warnings) > 0 {
		if _, err := fmt.Fprintln(writer, "\n  # Warnings:"); err != nil {
			return err
		}
		for _, warning := range recommendation.Warnings {
			if _, err := fmt.Fprintf(writer, "  # - %s\n", strings.Join(strings.Fields(warning), " ")); err != nil {
				return err
			}
		}
	}
	if shaping := recommendation.TCP.Shaping; shaping != nil {
		commands := tcShapingCommands(shaping)
		if _, err := fmt.Fprintln(writer, "\n  # This service owns the root qdisc and shapes all egress traffic on the interface."); err != nil {
			return err
		}
		if _, err := fmt.Fprintln(writer, "  systemd.services.netfit-egress-shaping = {"); err != nil {
			return err
		}
		if _, err := fmt.Fprintln(writer, "    description = \"Apply netfit aggregate egress shaping\";"); err != nil {
			return err
		}
		if _, err := fmt.Fprintln(writer, "    wants = [ \"network-online.target\" ];\n    after = [ \"network-online.target\" ];\n    wantedBy = [ \"multi-user.target\" ];"); err != nil {
			return err
		}
		if _, err := fmt.Fprintln(writer, "    path = [ pkgs.iproute2 ];\n    serviceConfig = {\n      Type = \"oneshot\";\n      RemainAfterExit = true;\n    };"); err != nil {
			return err
		}
		if _, err := fmt.Fprintln(writer, "    script = ''"); err != nil {
			return err
		}
		if _, err := fmt.Fprintln(writer, "      set -eu\n      rollback() {\n        tc qdisc replace dev "+shaping.Interface+" root fq\n      }\n      trap rollback ERR"); err != nil {
			return err
		}
		for _, command := range commands {
			if _, err := fmt.Fprintf(writer, "      %s\n", command); err != nil {
				return err
			}
		}
		if _, err := fmt.Fprintln(writer, "      trap - ERR"); err != nil {
			return err
		}
		if _, err := fmt.Fprintln(writer, "    '';\n    preStop = ''"); err != nil {
			return err
		}
		if _, err := fmt.Fprintf(writer, "      %s\n", tcRollbackCommand(shaping)); err != nil {
			return err
		}
		if _, err := fmt.Fprintln(writer, "    '';\n  };"); err != nil {
			return err
		}
	}
	_, err := fmt.Fprintln(writer, "}")
	return err
}

func writeTC(writer io.Writer, recommendation model.Recommendation) error {
	shaping := recommendation.TCP.Shaping
	if shaping == nil {
		return fmt.Errorf("no shaping rate available; use --shape-rate or an active TCP measurement that detects a knee")
	}
	lines := []string{
		"#!/usr/bin/env bash",
		"set -eu",
		"",
		"# Replaces the current root qdisc and shapes all egress traffic on the interface.",
		"rollback() {",
		fmt.Sprintf("  %s", tcRollbackCommand(shaping)),
		"}",
		"trap rollback ERR",
	}
	lines = append(lines, tcShapingCommands(shaping)...)
	lines = append(lines,
		"trap - ERR",
		"",
		"# Explicit rollback to the recommended unshaped fq root; this cannot restore an unknown previous qdisc.",
		"# "+tcRollbackCommand(shaping),
	)
	_, err := fmt.Fprintln(writer, strings.Join(lines, "\n"))
	return err
}

func tcRollbackCommand(shaping *model.TCPShapingRecommendation) string {
	return fmt.Sprintf("tc qdisc replace dev %s root fq", shaping.Interface)
}

func tcShapingCommands(shaping *model.TCPShapingRecommendation) []string {
	rate := strconv.FormatFloat(shaping.RateMbps, 'f', -1, 64) + "Mbit"
	return []string{
		fmt.Sprintf("tc qdisc replace dev %s root handle %s %s default 10", shaping.Interface, shaping.RootHandle, shaping.RootQdisc),
		fmt.Sprintf("tc class replace dev %s parent %s classid %s htb rate %s ceil %s", shaping.Interface, shaping.RootHandle, shaping.ClassID, rate, rate),
		fmt.Sprintf("tc qdisc replace dev %s parent %s handle %s %s", shaping.Interface, shaping.ClassID, shaping.LeafHandle, shaping.LeafQdisc),
	}
}

func nixValue(value string) string {
	if _, err := strconv.ParseUint(value, 10, 64); err == nil {
		return value
	}
	return strconv.Quote(value)
}

func humanBytes(value uint64) string {
	const mebibyte = float64(1024 * 1024)
	return fmt.Sprintf("%.2f MiB", float64(value)/mebibyte)
}
