package probe

import (
	"context"
	"net"
	"testing"
)

func TestParsePeer(t *testing.T) {
	t.Parallel()

	tests := []struct {
		input string
		host  string
		port  int
	}{
		{input: "example.com", host: "example.com", port: 5201},
		{input: "example.com:5202", host: "example.com", port: 5202},
		{input: "[2001:db8::1]:5203", host: "2001:db8::1", port: 5203},
	}
	for _, test := range tests {
		peer, err := ParsePeer(test.input)
		if err != nil {
			t.Fatalf("parse %q: %v", test.input, err)
		}
		if peer.Host != test.host || peer.Ports[0] != test.port {
			t.Fatalf("unexpected peer for %q: %#v", test.input, peer)
		}
	}
}

func TestParsePeerRejectsMissingHostOrPort(t *testing.T) {
	t.Parallel()

	for _, value := range []string{":5201", "example.com:"} {
		if _, err := ParsePeer(value); err == nil {
			t.Fatalf("expected %q to fail", value)
		}
	}
}

func TestParsePeerPreservesBuiltinPolicy(t *testing.T) {
	t.Parallel()

	peer, err := ParsePeer("speedtest.hkg12.hk.leaseweb.net:5202")
	if err != nil {
		t.Fatal(err)
	}
	if peer.MaxMbps != 1_000 || peer.Provider != "Leaseweb" {
		t.Fatalf("builtin policy was lost: %#v", peer)
	}
}

func TestParseIPFamily(t *testing.T) {
	t.Parallel()

	for _, value := range []string{"auto", "4", "6"} {
		family, err := ParseIPFamily(value)
		if err != nil || string(family) != value {
			t.Fatalf("parse %q: family=%q err=%v", value, family, err)
		}
	}
	if _, err := ParseIPFamily("dual"); err == nil {
		t.Fatal("expected invalid IP family to fail")
	}
}

func TestMeasurePeerRecordsResolvedRemoteIP(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()

	done := make(chan struct{})
	go func() {
		connection, acceptError := listener.Accept()
		if acceptError == nil {
			_ = connection.Close()
		}
		close(done)
	}()

	port := listener.Addr().(*net.TCPAddr).Port
	selected, err := measurePeer(context.Background(), Peer{Host: "127.0.0.1", Ports: []int{port}}, IPFamilyAuto)
	if err != nil {
		t.Fatal(err)
	}
	<-done
	if selected.RemoteIP != "127.0.0.1" || selected.IPFamily != IPFamily4 {
		t.Fatalf("unexpected resolved remote IP: %#v", selected)
	}
}
