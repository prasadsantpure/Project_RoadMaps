#!/usr/bin/env bash
# Basic Linux server health summary.  No root privileges are required.

set -u
export LC_ALL=C

hr() { printf '%*s\n' 72 '' | tr ' ' '='; }
section() { printf '\n%s\n' "$1"; printf '%*s\n' "${#1}" '' | tr ' ' '-'; }

human_kib() {
  awk -v kib="$1" 'BEGIN {
    split("KiB MiB GiB TiB PiB", u, " "); i=1;
    while (kib >= 1024 && i < 5) { kib /= 1024; i++ }
    printf "%.1f %s", kib, u[i]
  }'
}

cpu_snapshot() {
  awk '/^cpu / { print $2, $3, $4, $5, $6, $7, $8, $9; exit }' /proc/stat
}

cpu_usage() {
  local first second
  first=$(cpu_snapshot)
  sleep 1
  second=$(cpu_snapshot)

  awk -v a="$first" -v b="$second" 'BEGIN {
    split(a, x, " "); split(b, y, " ");
    for (i = 1; i <= 8; i++) { d = y[i] - x[i]; total += d }
    idle = (y[4] - x[4]) + (y[5] - x[5]);
    if (total > 0) printf "%.1f", (total - idle) * 100 / total; else print "0.0"
  }'
}

memory_usage() {
  awk '
    /^MemTotal:/ { total=$2 }
    /^MemAvailable:/ { available=$2 }
    END {
      used=total-available
      if (total > 0) printf "%d %d %d %.1f", total, used, available, used*100/total
    }
  ' /proc/meminfo
}

disk_usage() {
  # -k makes all input values KiB. tmpfs/devtmpfs are RAM-backed and excluded.
  df -P -k -x tmpfs -x devtmpfs 2>/dev/null | awk '
    NR > 1 { total += $2; used += $3; available += $4 }
    END {
      if (total > 0) printf "%d %d %d %.1f", total, used, available, used*100/total
    }
  '
}

if [[ ! -r /proc/stat || ! -r /proc/meminfo ]]; then
  echo "Error: this script requires a Linux system with procfs mounted." >&2
  exit 1
fi

hr
printf 'SERVER PERFORMANCE REPORT — %s\n' "$(hostname 2>/dev/null || echo unknown-host)"
printf 'Generated: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
hr

section "System"
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  printf 'OS: %s\n' "${PRETTY_NAME:-${NAME:-Unknown}}"
fi
printf 'Kernel: %s\n' "$(uname -r)"
printf 'Uptime: %s\n' "$(uptime -p 2>/dev/null || uptime)"
printf 'Load average (1/5/15 min): %s\n' "$(awk '{print $1, $2, $3}' /proc/loadavg)"
printf 'Logged-in users: %s\n' "$(who 2>/dev/null | wc -l | tr -d ' ')"

section "CPU"
printf 'Total CPU usage: %s%% (sampled over 1 second)\n' "$(cpu_usage)"

section "Memory"
read -r mem_total mem_used mem_free mem_pct <<< "$(memory_usage)"
printf 'Total: %s | Used: %s (%s%%) | Free: %s\n' \
  "$(human_kib "$mem_total")" "$(human_kib "$mem_used")" "$mem_pct" "$(human_kib "$mem_free")"

section "Disk (all non-temporary mounted filesystems)"
read -r disk_total disk_used disk_free disk_pct <<< "$(disk_usage)"
printf 'Total: %s | Used: %s (%s%%) | Free: %s\n' \
  "$(human_kib "$disk_total")" "$(human_kib "$disk_used")" "$disk_pct" "$(human_kib "$disk_free")"

section "Top 5 Processes by CPU Usage"
ps -eo pid,user,comm,%cpu --sort=-%cpu | head -n 6

section "Top 5 Processes by Memory Usage"
ps -eo pid,user,comm,%mem --sort=-%mem | head -n 6
