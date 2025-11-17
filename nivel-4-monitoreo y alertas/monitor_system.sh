#!/usr/bin/env bash
set -u
TH_CPU="${TH_CPU:-80}"
TH_MEM="${TH_MEM:-80}"
TH_DISK="${TH_DISK:-80}"
WEBHOOK="${WEBHOOK:-}"
MAILTO="${MAILTO:-}"
DATE=$(date +%Y%m%d)
TS=$(date '+%Y-%m-%d %H:%M:%S')
METRIC_FILE="/var/log/metrics_${DATE}.log"
ALERT_FILE="/var/log/alerts.log"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
CPU_USAGE=""
if command -v mpstat >/dev/null 2>&1; then
  CPU_IDLE=$(mpstat 1 1 | awk '/all/ {print $NF; exit}')
  if [ -z "$CPU_IDLE" ]; then CPU_IDLE=0; fi
  CPU_USAGE=$(printf "%.0f" "$(echo "100 - $CPU_IDLE" | bc -l)")
else
  CPU_IDLE=$(top -bn1 | awk -F'id,' -v OFS='' '{ if ($0 ~ /Cpu/){ split($1,parts,","); for(i in parts){ if (parts[i] ~ /id/){ gsub(/[^0-9.]/,"",parts[i]); print parts[i]; exit } } } }' | head -n1)
  if [ -z "$CPU_IDLE" ]; then CPU_IDLE=0; fi
  CPU_USAGE=$(printf "%.0f" "$(echo "100 - $CPU_IDLE" | bc -l)")
fi
MEM_PERC=$(free -m | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')
DISK_PERC=$(df -P / | awk 'NR==2 {gsub("%","",$5); printf "%.0f",$5}')
echo "${TS} CPU:${CPU_USAGE}% MEM:${MEM_PERC}% DISK:${DISK_PERC}%" >> "$METRIC_FILE"
ALERT=""
if [ "$CPU_USAGE" -ge "$TH_CPU" ]; then ALERT="${ALERT}CPU:${CPU_USAGE}% "; fi
if [ "$MEM_PERC" -ge "$TH_MEM" ]; then ALERT="${ALERT}MEM:${MEM_PERC}% "; fi
if [ "$DISK_PERC" -ge "$TH_DISK" ]; then ALERT="${ALERT}DISK:${DISK_PERC}% "; fi
if [ -n "$ALERT" ]; then
  MSG="${TS} ALERT ${ALERT}"
  echo "$MSG" >> "$ALERT_FILE"
  printf "${RED}%s${NC}\n" "$MSG"
  if [ -n "$WEBHOOK" ]; then
    curl -s -X POST -H "Content-Type: application/json" -d "{\"timestamp\":\"${TS}\",\"alert\":\"${ALERT}\"}" "$WEBHOOK" >/dev/null 2>&1 || true
  fi
  if [ -n "$MAILTO" ] && command -v mail >/dev/null 2>&1; then
    printf "%s\n" "$MSG" | mail -s "ALERT: System thresholds exceeded" "$MAILTO" || true
  fi
else
  MSG="${TS} OK CPU:${CPU_USAGE}% MEM:${MEM_PERC}% DISK:${DISK_PERC}%"
  printf "${GREEN}%s${NC}\n" "$MSG"
fi
exit 0
