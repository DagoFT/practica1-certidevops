#!/usr/bin/env bash
set -u
BACKUP_DIR="/backup/logs"
LOGFILE="/var/log/cleanup_logs.log"
TS=$(date +%Y%m%d_%H%M%S)
LIST="/tmp/cleanup_list_${TS}.txt"
mkdir -p "$BACKUP_DIR"
find /var/log -type f -mtime +7 -print0 > "$LIST"
if [ -s "$LIST" ]; then
  COUNT=$(find /var/log -type f -mtime +7 | wc -l)
  tar -czf "$BACKUP_DIR/logs-$TS.tar.gz" --null -T "$LIST"
  if [ $? -eq 0 ]; then
    xargs -0 rm -f -- < "$LIST" || true
    echo "$(date '+%Y-%m-%d %H:%M:%S') Archived $COUNT files to $BACKUP_DIR/logs-$TS.tar.gz" >> "$LOGFILE"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: tar failed for $BACKUP_DIR/logs-$TS.tar.gz" >> "$LOGFILE"
  fi
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') No files older than 7 days found" >> "$LOGFILE"
fi
rm -f "$LIST"
