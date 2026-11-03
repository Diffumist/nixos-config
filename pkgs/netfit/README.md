# netfit

只读的 Linux TCP 参数生成器。读取当前主机状态，可选调用
`iperf3` 做主动出口测量，最后输出文本、JSON、`tc` 配置或可直接粘贴的 NixOS 模块。

## 使用

纯模型模式需要显式给出目标路径带宽和 RTT：

```bash
netfit recommend --bandwidth 1000 --rtt 80 --profile balanced
netfit recommend --bandwidth 1000 --rtt 80 --format nix
```

显式生成 950 Mbps 聚合出口整形：

```bash
netfit recommend --bandwidth 1000 --rtt 80 \
  --shape-rate 950 --interface ens3 --format tc
netfit recommend --bandwidth 1000 --rtt 80 \
  --shape-rate 950 --interface ens3 --format nix > netfit.nix
```

省略 `--interface` 时，主动模式使用内核对已解析 peer IP 的实际 route lookup；纯模型模式
才回退到 main-table 默认路由接口。`--format tc` 输出可审阅的三条
`tc` 命令；Nix 输出生成 oneshot 服务，在启动时安装相同配置，停用时把根 qdisc 明确
重置为无整形的 `fq`。netfit 不会尝试伪造“恢复旧配置”：应用整形会替换当前根 qdisc，
未知旧 qdisc 只有在外部完整快照存在时才能恢复。

这里的 HTB 是接口级聚合整形：`HTB root -> fq leaf` 会限制选定接口的**全部出口流量**，
包括 TCP、UDP 和 ICMP；“TCP 整形”仅表示限速值由 TCP 探测拐点推导，不表示只匹配 TCP。
显式 `--shape-rate` 优先于探测值；没有显式值时，仅在主动 TCP 扫描确认重传拐点后生成
整形配置。没有速率时请求 `--format tc` 会报错，不会拿 nominal bandwidth 猜一个限速值。
自动测得 shape rate 但仍无法确定接口时，Nix/text/JSON 会保留其余建议并输出 warning，
不会再中止整份报告；只有显式 `--shape-rate` 或只请求 `--format tc` 时才强制要求接口。

主动测量为显式 opt-in：

```bash
netfit peers
netfit recommend --peer auto --bandwidth 1000 --profile balanced --format json
netfit recommend --peer iperf.example.net:5201 --bandwidth 10000 --rtt 40
netfit recommend --peer auto --ip-family 6 --bandwidth 1000 --format nix
```

`--ip-family auto|4|6` 控制主动测试的地址族。netfit 会记录预检实际连接的字面 IP，随后让
iperf3 和 path-specific route lookup 复用同一个地址，避免双栈 DNS 在不同阶段选择不同
协议族或出口接口。

公共 `--peer auto` 的低延迟只代表到最近测速节点的路径，不能代表实际业务用户。因此没有
显式 `--rtt` 时，自动公共节点使用并明确标记 `150 ms (assumed)`；`--rtt` 始终优先。
自建 peer 默认使用 iperf3 测得的 RTT，因为它可以部署在实际业务路径上。

主动测试默认把进度写到 `stderr`，不会污染重定向到文件的 Nix、JSON 或 `tc` 输出：

```text
netfit: [peer] selected speedtest.example.net:5201, connect 18.42 ms
netfit: [probe] per-sample watchdog 22s
netfit: [tcp] running baseline
netfit: [tcp 2/5] 1000 Mbps, sample 1/3
```

脚本环境不需要进度时添加 `--quiet`。

每次 iperf3 默认有 `duration + omit + 15s` 的独立 watchdog，默认参数下为 22 秒；它独立于
整个主动扫描的 `--timeout`。

`--peer auto` 从 6 个内置公共端点中选择 TCP 建连时间最低者。公共端点会变化、可能繁忙，
生产判断优先使用自己控制、且位于真实业务路径上的 iperf3 服务端。公共端点的主动扫档目标
最多为 1 Gbps，自定义端点不施加此限制。主动测试只覆盖本机出口，会实际消耗流量。内置
端点还强制 `duration <= 10`、`omit <= 5`、`samples <= 3`、`timeout <= 10m`；需要更长或
更高速的测试时必须使用自建端点。

其他命令：

```bash
netfit facts --format json
netfit peers --format json
netfit version
```

## 模型

- TCP BDP：`bandwidth × RTT / 8`。`proxy`、`balanced`、`bulk` 分别使用
  `2×`、`2×`、`4×` BDP 作为自动调优上限目标，再受物理内存比例和绝对上限约束。
- TCP 输出包含 `fq`、BBR、`tcp_moderate_rcvbuf`、core socket 上限及
  `tcp_rmem`/`tcp_wmem`；已读取到的现有 socket 上限和三元组不会被降低。提供显式整形
  速率或主动探测确认拐点时，额外输出 `HTB root -> fq leaf` 聚合整形树。
- `tcp_mem` 保持内核管理。它使用页为单位，启动时默认值依赖可用 buffer pages，不能仅由
  物理内存可靠重建。

默认 profile：

| profile | TCP headroom | 单 socket 内存上限 |
| --- | ---: | ---: |
| `proxy` | 2× BDP | min(RAM/64, 16 MiB) |
| `balanced` | 2× BDP | min(RAM/32, 64 MiB) |
| `bulk` | 4× BDP | min(RAM/16, 256 MiB) |

主动 TCP 扫描用奇数次样本中位数比较单位传输量的重传数，并按单次结果多数表决，
不把重传段数伪称为丢包率。粗扫发现首个重传拐点后，会在最后稳定档和首个坏档之间增加
三个细扫档；如果细扫全干净，仍保留粗扫已经确认的坏点。高重传 baseline 会扩大自建 peer
的扫描上界。JSON 结果明确区分 `knee`、`no-knee`、`out-of-range` 和
`peer-bottleneck`。

单个公共端点仍可能成为瓶颈，因此主动测量结果最高只标记为 `medium` confidence。

## 开发

```bash
go test ./...
go vet ./...
nix build path:../..#netfit --no-link
```
