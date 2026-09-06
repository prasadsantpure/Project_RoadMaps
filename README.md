# Server Stats Script

`server-stats.sh` is a lightweight Bash script for viewing basic performance statistics on a Linux server. It does not require root privileges or additional packages on a typical Linux installation.

## Metrics reported

- Total CPU usage, sampled over one second
- Memory total, used, free, and used percentage
- Aggregate disk total, used, free, and used percentage for non-temporary mounted filesystems
- Top 5 processes by CPU usage
- Top 5 processes by memory usage
- OS name, kernel version, uptime, load average, and logged-in user count

## Requirements

- Linux with `/proc` mounted
- Bash
- Standard system utilities: `awk`, `df`, `ps`, `uptime`, `who`, and `head`

The process sorting options used by the script are provided by the usual `procps` implementation of `ps` found on most Linux distributions.

## Usage

Make the script executable once:

```bash
chmod +x server-stats.sh
```

Run it:

```bash
./server-stats.sh
```

Or run it explicitly with Bash:

```bash
bash server-stats.sh
```

## Example output

```text
========================================================================
SERVER PERFORMANCE REPORT — app-server-01
Generated: 2026-09-06 09:40:00 UTC
========================================================================

System
------
OS: Ubuntu 24.04.1 LTS
Kernel: 6.8.0-48-generic
Uptime: up 3 days, 4 hours, 12 minutes
Load average (1/5/15 min): 0.15 0.10 0.08
Logged-in users: 1

CPU
---
Total CPU usage: 12.4% (sampled over 1 second)

Memory
------
Total: 15.5 GiB | Used: 5.8 GiB (37.4%) | Free: 9.7 GiB

Disk (all non-temporary mounted filesystems)
---------------------------------------------
Total: 120.0 GiB | Used: 48.0 GiB (40.0%) | Free: 72.0 GiB
```

## Notes

- The memory “Free” value uses Linux `MemAvailable`, which includes memory that can be reclaimed by the kernel. This is generally more useful than the raw `MemFree` value.
- Disk totals exclude `tmpfs` and `devtmpfs`, because they are RAM-backed temporary filesystems.
- CPU usage is calculated from the difference between two `/proc/stat` samples taken one second apart.
