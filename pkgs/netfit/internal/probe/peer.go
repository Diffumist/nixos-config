package probe

import (
	"context"
	"fmt"
	"net"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

type Peer struct {
	Host     string  `json:"host"`
	Region   string  `json:"region,omitempty"`
	Provider string  `json:"provider,omitempty"`
	Ports    []int   `json:"ports"`
	MaxMbps  float64 `json:"maxProbeMbps,omitempty"`
}

type IPFamily string

const (
	IPFamilyAuto IPFamily = "auto"
	IPFamily4    IPFamily = "4"
	IPFamily6    IPFamily = "6"
)

type SelectedPeer struct {
	Peer
	Port          int      `json:"port"`
	ConnectMillis float64  `json:"connectMillis"`
	RemoteIP      string   `json:"remoteIp,omitempty"`
	IPFamily      IPFamily `json:"ipFamily"`
}

var BuiltinPeers = []Peer{
	{Host: "speedtest.hkg12.hk.leaseweb.net", Region: "Hong Kong", Provider: "Leaseweb", Ports: portRange(5201, 5210), MaxMbps: 1_000},
	{Host: "speedtest.tyo11.jp.leaseweb.net", Region: "Tokyo", Provider: "Leaseweb", Ports: portRange(5201, 5210), MaxMbps: 1_000},
	{Host: "sgp.proof.ovh.net", Region: "Singapore", Provider: "OVHcloud", Ports: portRange(5201, 5210), MaxMbps: 1_000},
	{Host: "speedtest.fra1.de.leaseweb.net", Region: "Frankfurt", Provider: "Leaseweb", Ports: portRange(5201, 5210), MaxMbps: 1_000},
	{Host: "speedtest.lax12.us.leaseweb.net", Region: "Los Angeles", Provider: "Leaseweb", Ports: portRange(5201, 5210), MaxMbps: 1_000},
	{Host: "speedtest.chi11.us.leaseweb.net", Region: "Chicago", Provider: "Leaseweb", Ports: portRange(5201, 5210), MaxMbps: 1_000},
}

func ParsePeer(value string) (Peer, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return Peer{}, fmt.Errorf("peer cannot be empty")
	}
	if strings.HasPrefix(value, "[") {
		host, portText, err := net.SplitHostPort(value)
		if err != nil {
			return Peer{}, fmt.Errorf("parse peer: %w", err)
		}
		port, err := parsePort(portText)
		if err != nil {
			return Peer{}, err
		}
		return applyBuiltinPolicy(Peer{Host: host, Ports: []int{port}}), nil
	}
	if strings.Count(value, ":") == 1 {
		host, portText, _ := strings.Cut(value, ":")
		if portText != "" {
			if host == "" {
				return Peer{}, fmt.Errorf("peer host cannot be empty")
			}
			port, err := parsePort(portText)
			if err != nil {
				return Peer{}, err
			}
			return applyBuiltinPolicy(Peer{Host: host, Ports: []int{port}}), nil
		}
		return Peer{}, fmt.Errorf("peer port cannot be empty")
	}
	for _, builtin := range BuiltinPeers {
		if strings.EqualFold(value, builtin.Host) {
			return builtin, nil
		}
	}
	return Peer{Host: value, Ports: []int{5201}}, nil
}

func applyBuiltinPolicy(peer Peer) Peer {
	for _, builtin := range BuiltinPeers {
		if !strings.EqualFold(peer.Host, builtin.Host) {
			continue
		}
		peer.Region = builtin.Region
		peer.Provider = builtin.Provider
		peer.MaxMbps = builtin.MaxMbps
		return peer
	}
	return peer
}

func ParseIPFamily(value string) (IPFamily, error) {
	family := IPFamily(strings.ToLower(strings.TrimSpace(value)))
	switch family {
	case IPFamilyAuto, IPFamily4, IPFamily6:
		return family, nil
	default:
		return "", fmt.Errorf("IP family must be auto, 4, or 6")
	}
}

func SelectPeer(ctx context.Context, peers []Peer, family IPFamily) (SelectedPeer, error) {
	type result struct {
		peer SelectedPeer
		err  error
	}

	results := make(chan result, len(peers))
	var group sync.WaitGroup
	for _, candidate := range peers {
		candidate := candidate
		group.Add(1)
		go func() {
			defer group.Done()
			selected, err := measurePeer(ctx, candidate, family)
			results <- result{peer: selected, err: err}
		}()
	}
	group.Wait()
	close(results)

	available := make([]SelectedPeer, 0, len(peers))
	for result := range results {
		if result.err == nil {
			available = append(available, result.peer)
		}
	}
	if len(available) == 0 {
		return SelectedPeer{}, fmt.Errorf("no iperf3 peer accepted a TCP connection")
	}
	sort.Slice(available, func(i, j int) bool {
		return available[i].ConnectMillis < available[j].ConnectMillis
	})
	return available[0], nil
}

func measurePeer(ctx context.Context, peer Peer, family IPFamily) (SelectedPeer, error) {
	dialer := net.Dialer{Timeout: 2 * time.Second}
	for _, port := range peer.Ports {
		start := time.Now()
		connection, err := dialer.DialContext(ctx, family.network(), net.JoinHostPort(peer.Host, strconv.Itoa(port)))
		if err != nil {
			continue
		}
		remoteIP := ""
		if remote, ok := connection.RemoteAddr().(*net.TCPAddr); ok {
			remoteIP = remote.IP.String()
		}
		_ = connection.Close()
		selectedFamily, err := familyForIP(remoteIP)
		if err != nil {
			continue
		}
		return SelectedPeer{
			Peer:          peer,
			Port:          port,
			ConnectMillis: float64(time.Since(start).Microseconds()) / 1_000,
			RemoteIP:      remoteIP,
			IPFamily:      selectedFamily,
		}, nil
	}
	return SelectedPeer{}, fmt.Errorf("peer %s is unreachable", peer.Host)
}

func (family IPFamily) network() string {
	switch family {
	case IPFamily4:
		return "tcp4"
	case IPFamily6:
		return "tcp6"
	default:
		return "tcp"
	}
}

func familyForIP(value string) (IPFamily, error) {
	address := net.ParseIP(value)
	if address == nil {
		return "", fmt.Errorf("invalid resolved peer address %q", value)
	}
	if address.To4() != nil {
		return IPFamily4, nil
	}
	return IPFamily6, nil
}

func parsePort(value string) (int, error) {
	port, err := strconv.Atoi(value)
	if err != nil || port < 1 || port > 65_535 {
		return 0, fmt.Errorf("invalid peer port %q", value)
	}
	return port, nil
}

func portRange(first, last int) []int {
	ports := make([]int, 0, last-first+1)
	for port := first; port <= last; port++ {
		ports = append(ports, port)
	}
	return ports
}
