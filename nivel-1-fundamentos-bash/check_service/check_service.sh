#!/usr/bin/env bash
# check_service.sh - Verifica si un servicio está activo, alerta si no lo está y escribe un log.
# Uso: ./check_service.sh nginx

set -u

SERVICE="${1:-}"
LOGFILE="service_status.log"
TIMESTAMP(){ date +"%Y-%m-%d %H:%M:%S"; }

if [[ -z "$SERVICE" ]]; then
  echo "Uso: $0 <nombre_del_servicio>"
  exit 2
fi

STATUS="unknown"


if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
    STATUS="active"
  else
    STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null || echo "inactive")
  fi


elif command -v service >/dev/null 2>&1; then
  if service "$SERVICE" status >/dev/null 2>&1; then
    STATUS="active"
  else
    
    if command -v pgrep >/dev/null 2>&1 && pgrep -f "$SERVICE" >/dev/null 2>&1; then
      STATUS="active"
    else
      STATUS="inactive"
    fi
  fi


else
  if command -v pgrep >/dev/null 2>&1 && pgrep -f "$SERVICE" >/dev/null 2>&1; then
    STATUS="active"
  else
    STATUS="inactive"
  fi
fi


if [[ "$STATUS" != "active" ]]; then
  echo "[ALERTA] $(TIMESTAMP): El servicio '$SERVICE' NO está activo (estado: $STATUS)." >&2
else
  echo "[OK] $(TIMESTAMP): El servicio '$SERVICE' está activo."
fi


echo "$(TIMESTAMP)  $SERVICE  $STATUS" >> "$LOGFILE"


if [[ "$STATUS" == "active" ]]; then
  exit 0
else
  exit 1
fi
