{ pkgs, lib, ... }:
{
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "vdso32=0"
    "vsyscall=none"
    "cfi=kcfi"
    "hardened_usercopy=1"
    "hash_pointers=always"
    "randomize_kstack_offset=on"
    "spec_store_bypass_disable=on"
    "page_alloc.shuffle=1"
  ];
  # Ref: https://github.com/k4yt3x/sysctl/blob/master/sysctl.conf
  boot.kernel.sysctl = {
    # --- Network Optimization ---
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_synack_retries" = 5;
    # Connection queues (scaled down for 1-2GB RAM)
    "net.core.somaxconn" = 4096;
    "net.core.netdev_max_backlog" = 4096;
    "net.ipv4.tcp_max_syn_backlog" = 4096;
    "net.core.rmem_default" = 262144;
    "net.core.wmem_default" = 262144;
    "net.core.rmem_max" = 8388608;
    "net.core.wmem_max" = 8388608;
    "net.core.optmem_max" = 65535;
    "net.ipv4.tcp_rmem" = "4096 131072 8388608";
    "net.ipv4.tcp_wmem" = "4096 16384 8388608";
    "net.ipv4.udp_mem" = "8192 16384 32768";
    "net.ipv4.tcp_keepalive_time" = 300;
    "net.ipv4.tcp_keepalive_probes" = 5;
    "net.ipv4.tcp_keepalive_intvl" = 15;
    "net.ipv4.ip_local_port_range" = "20480 65535";
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.tcp_notsent_lowat" = 16384;
    # --- Hardening (Kernel & File System) ---
    "kernel.yama.ptrace_scope" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.kexec_load_disabled" = 1;
    "kernel.panic" = 10;
    "fs.suid_dumpable" = 0;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    # --- Memory Management (VM) ---
    "vm.swappiness" = 10;
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;
    "vm.unprivileged_userfaultfd" = 0;
    # --- Network Security / Anti-Spoofing (IPv4) ---
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.conf.all.arp_announce" = 2;
    "net.ipv4.conf.default.arp_announce" = 2;
    "net.ipv4.conf.all.arp_ignore" = 1;
    "net.ipv4.conf.default.arp_ignore" = 1;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.drop_gratuitous_arp" = 1;
    "net.ipv4.conf.default.drop_gratuitous_arp" = 1;
    "net.ipv4.conf.all.shared_media" = 0;
    "net.ipv4.conf.default.shared_media" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    # --- Network Security / Anti-Spoofing (IPv6) ---
    # ignore IPv6 ICMP redirect messages
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    # do not accept packets with SRR option
    "net.ipv6.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
  };

}
