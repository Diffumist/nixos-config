package systeminfo

import (
	"os"
	"path/filepath"
	"testing"
)

func TestReadMemoryBytes(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "meminfo")
	if err := os.WriteFile(path, []byte("MemTotal:       1048576 kB\nMemFree: 1 kB\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	value, err := readMemoryBytes(path)
	if err != nil {
		t.Fatal(err)
	}
	if value != 1_073_741_824 {
		t.Fatalf("unexpected memory bytes: %d", value)
	}
}

func TestReadVector(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "tcp_rmem")
	if err := os.WriteFile(path, []byte("4096 131072 6291456\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	minimum, defaultValue, maximum := readVector(path)
	if minimum != 4096 || defaultValue != 131072 || maximum != 6291456 {
		t.Fatalf("unexpected vector: %d %d %d", minimum, defaultValue, maximum)
	}
}

func TestInterfaceForDestinationUsesKernelRoute(t *testing.T) {
	interfaceName, err := InterfaceForDestination("127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if interfaceName != "lo" {
		t.Fatalf("unexpected loopback route interface: %s", interfaceName)
	}
}

func TestInterfaceForDestinationRejectsInvalidIP(t *testing.T) {
	t.Parallel()

	if _, err := InterfaceForDestination("not-an-ip"); err == nil {
		t.Fatal("expected invalid destination to fail")
	}
}
