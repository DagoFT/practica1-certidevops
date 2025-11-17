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

# 1) Intentar systemctl (si está disponible)
if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
    STATUS="active"
  else
    STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null || echo "inactive")
  fi

# 2) Si no hay systemctl, intentar 'service' (SysV/Upstart), pero si falla, intentar pgrep
elif command -v service >/dev/null 2>&1; then
  if service "$SERVICE" status >/dev/null 2>&1; then
    STATUS="active"
  else
    # Si 'service' falla, intentar detectar con pgrep en la línea de comando
    if command -v pgrep >/dev/null 2>&1 && pgrep -f "$SERVICE" >/dev/null 2>&1; then
      STATUS="active"
    else
      STATUS="inactive"
    fi
  fi

# 3) Fallback: buscar proceso con pgrep (útil en contenedores)
else
  if command -v pgrep >/dev/null 2>&1 && pgrep -f "$SERVICE" >/dev/null 2>&1; then
    STATUS="active"
  else
    STATUS="inactive"
  fi
fi

# Mensaje por consola (alerta a stderr si inactivo)
if [[ "$STATUS" != "active" ]]; then
  echo "[ALERTA] $(TIMESTAMP): El servicio '$SERVICE' NO está activo (estado: $STATUS)." >&2
else
  echo "[OK] $(TIMESTAMP): El servicio '$SERVICE' está activo."
fi

# Guardar resultado en el log (timestamp, servicio, estado)
echo "$(TIMESTAMP)  $SERVICE  $STATUS" >> "$LOGFILE"

# Código de salida: 0 si activo, 1 si inactivo
if [[ "$STATUS" == "active" ]]; then
  exit 0
else
  exit 1
fi
