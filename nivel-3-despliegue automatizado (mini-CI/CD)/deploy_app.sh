#!/usr/bin/env bash
set -u
REPO_URL="https://github.com/rayner-villalba-coderoad-com/clash-of-clan.git"
DEPLOY_DIR="/var/www/clash-of-clan"
LOGFILE="/var/log/deploy_app.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')
mkdir -p "$DEPLOY_DIR"
GIT_OUTPUT=""
GIT_STATUS=0
if [ -d "$DEPLOY_DIR/.git" ]; then
  cd "$DEPLOY_DIR"
  GIT_OUTPUT=$(git fetch --all 2>&1 && git reset --hard origin/$(git rev-parse --abbrev-ref HEAD) 2>&1 || git pull 2>&1)
  GIT_STATUS=$?
else
  GIT_OUTPUT=$(git clone "$REPO_URL" "$DEPLOY_DIR" 2>&1)
  GIT_STATUS=$?
fi
echo "$TS GIT_EXIT:$GIT_STATUS" >> "$LOGFILE"
echo "$TS GIT_OUTPUT_START" >> "$LOGFILE"
printf "%s\n" "$GIT_OUTPUT" >> "$LOGFILE"
echo "$TS GIT_OUTPUT_END" >> "$LOGFILE"
RESTART_OUTPUT=""
RESTART_STATUS=0
if command -v systemctl >/dev/null 2>&1; then
  RESTART_OUTPUT=$(systemctl restart nginx 2>&1)
  RESTART_STATUS=$?
  RESTART_METHOD="systemctl nginx"
elif command -v service >/dev/null 2>&1; then
  RESTART_OUTPUT=$(service nginx restart 2>&1)
  RESTART_STATUS=$?
  RESTART_METHOD="service nginx"
elif command -v pm2 >/dev/null 2>&1; then
  RESTART_OUTPUT=$(pm2 restart all 2>&1)
  RESTART_STATUS=$?
  RESTART_METHOD="pm2"
else
  RESTART_OUTPUT="no supported service manager found"
  RESTART_STATUS=127
  RESTART_METHOD="none"
fi
echo "$TS RESTART_METHOD:$RESTART_METHOD RESTART_EXIT:$RESTART_STATUS" >> "$LOGFILE"
echo "$TS RESTART_OUTPUT_START" >> "$LOGFILE"
printf "%s\n" "$RESTART_OUTPUT" >> "$LOGFILE"
echo "$TS RESTART_OUTPUT_END" >> "$LOGFILE"
exit $GIT_STATUS
