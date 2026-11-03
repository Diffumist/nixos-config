package systeminfo

import (
	"bufio"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strconv"
	"strings"

	"github.com/diffumist/nixos-config/pkgs/netfit/internal/model"
	"github.com/vishvananda/netlink"
)

type Facts struct {
	Interface      string               `json:"interface,omitempty"`
	InterfaceIndex int                  `json:"interfaceIndex,omitempty"`
	MTU            int                  `json:"mtu,omitempty"`
	Gateway        string               `json:"gateway,omitempty"`
	RoutePriority  int                  `json:"routePriority,omitempty"`
	Qdiscs         []string             `json:"qdiscs,omitempty"`
	LinkSpeedMbps  float64              `json:"linkSpeedMbps,omitempty"`
	MemoryBytes    uint64               `json:"memoryBytes"`
	PageSize       uint64               `json:"pageSize"`
	CPUs           int                  `json:"cpus"`
	Current        model.CurrentSysctls `json:"currentSysctls"`
	Warnings       []string             `json:"warnings,omitempty"`
}

func InterfaceForDestination(address string) (string, error) {
	destination := net.ParseIP(address)
	if destination == nil {
		return "", fmt.Errorf("invalid destination IP %q", address)
	}
	routes, err := netlink.RouteGet(destination)
	if err != nil {
		return "", fmt.Errorf("route lookup for %s: %w", address, err)
	}
	for _, route := range routes {
		if route.LinkIndex <= 0 {
			continue
		}
		link, err := netlink.LinkByIndex(route.LinkIndex)
		if err != nil {
			return "", fmt.Errorf("route interface for %s: %w", address, err)
		}
		return link.Attrs().Name, nil
	}
	return "", fmt.Errorf("route lookup for %s returned no interface", address)
}

func Detect() (Facts, error) {
	memoryBytes, err := readMemoryBytes("/proc/meminfo")
	if err != nil {
		return Facts{}, err
	}

	facts := Facts{
		MemoryBytes: memoryBytes,
		PageSize:    uint64(os.Getpagesize()),
		CPUs:        runtime.NumCPU(),
		Current:     readCurrentSysctls(),
	}

	route, alternatives, err := defaultRoute()
	if err != nil {
		facts.Warnings = append(facts.Warnings, "default route unavailable: "+err.Error())
		return facts, nil
	}
	if alternatives > 1 {
		facts.Warnings = append(facts.Warnings, fmt.Sprintf("%d default routes found; preferred IPv4, then the lowest metric", alternatives))
	}

	link, err := netlink.LinkByIndex(route.LinkIndex)
	if err != nil {
		facts.Warnings = append(facts.Warnings, "default-route interface unavailable: "+err.Error())
		return facts, nil
	}
	attrs := link.Attrs()
	facts.Interface = attrs.Name
	facts.InterfaceIndex = attrs.Index
	facts.MTU = attrs.MTU
	facts.RoutePriority = route.Priority
	if route.Gw != nil {
		facts.Gateway = route.Gw.String()
	}
	facts.LinkSpeedMbps = readLinkSpeed(attrs.Name)

	qdiscs, err := netlink.QdiscList(link)
	if err != nil {
		facts.Warnings = append(facts.Warnings, "qdisc inventory unavailable: "+err.Error())
	} else {
		seen := make(map[string]struct{}, len(qdiscs))
		for _, qdisc := range qdiscs {
			seen[qdisc.Type()] = struct{}{}
		}
		for qdisc := range seen {
			facts.Qdiscs = append(facts.Qdiscs, qdisc)
		}
		sort.Strings(facts.Qdiscs)
	}

	return facts, nil
}

func defaultRoute() (netlink.Route, int, error) {
	routes, err := netlink.RouteList(nil, netlink.FAMILY_ALL)
	if err != nil {
		return netlink.Route{}, 0, err
	}

	defaults := make([]netlink.Route, 0, 2)
	for _, route := range routes {
		if route.Dst == nil && route.LinkIndex > 0 && route.Table == 254 {
			defaults = append(defaults, route)
		}
	}
	if len(defaults) == 0 {
		return netlink.Route{}, 0, errors.New("no main-table default route")
	}
	sort.SliceStable(defaults, func(i, j int) bool {
		iIPv4 := defaults[i].Gw == nil || defaults[i].Gw.To4() != nil
		jIPv4 := defaults[j].Gw == nil || defaults[j].Gw.To4() != nil
		if iIPv4 != jIPv4 {
			return iIPv4
		}
		return defaults[i].Priority < defaults[j].Priority
	})
	return defaults[0], len(defaults), nil
}

func readMemoryBytes(path string) (uint64, error) {
	file, err := os.Open(path)
	if err != nil {
		return 0, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if len(fields) >= 2 && fields[0] == "MemTotal:" {
			kilobytes, err := strconv.ParseUint(fields[1], 10, 64)
			if err != nil {
				return 0, fmt.Errorf("parse MemTotal: %w", err)
			}
			return kilobytes * 1024, nil
		}
	}
	if err := scanner.Err(); err != nil {
		return 0, err
	}
	return 0, errors.New("MemTotal not found")
}

func readCurrentSysctls() model.CurrentSysctls {
	receiveMinimum, receiveDefault, receiveMaximum := readVector("/proc/sys/net/ipv4/tcp_rmem")
	sendMinimum, sendDefault, sendMaximum := readVector("/proc/sys/net/ipv4/tcp_wmem")
	return model.CurrentSysctls{
		CoreReceiveMaximum: readUintFile("/proc/sys/net/core/rmem_max"),
		CoreSendMaximum:    readUintFile("/proc/sys/net/core/wmem_max"),
		TCPReceiveMinimum:  receiveMinimum,
		TCPReceiveDefault:  receiveDefault,
		TCPReceiveMaximum:  receiveMaximum,
		TCPSendMinimum:     sendMinimum,
		TCPSendDefault:     sendDefault,
		TCPSendMaximum:     sendMaximum,
	}
}

func readUintFile(path string) uint64 {
	data, err := os.ReadFile(path)
	if err != nil {
		return 0
	}
	value, _ := strconv.ParseUint(strings.TrimSpace(string(data)), 10, 64)
	return value
}

func readVector(path string) (uint64, uint64, uint64) {
	data, err := os.ReadFile(path)
	if err != nil {
		return 0, 0, 0
	}
	fields := strings.Fields(string(data))
	if len(fields) != 3 {
		return 0, 0, 0
	}
	minimum, _ := strconv.ParseUint(fields[0], 10, 64)
	defaultValue, _ := strconv.ParseUint(fields[1], 10, 64)
	maximum, _ := strconv.ParseUint(fields[2], 10, 64)
	return minimum, defaultValue, maximum
}

func readLinkSpeed(interfaceName string) float64 {
	data, err := os.ReadFile(filepath.Join("/sys/class/net", interfaceName, "speed"))
	if err != nil {
		return 0
	}
	value, err := strconv.ParseFloat(strings.TrimSpace(string(data)), 64)
	if err != nil || value <= 0 {
		return 0
	}
	return value
}
