# Nivel 1 - Fundamentos del scripting en Bash
Ejercicio: check_service

Descripción:
Script que recibe el nombre de un servicio como parámetro, verifica su estado,
lanza una alerta si no está activo y guarda el resultado en service_status.log.

Uso:
./check_service.sh nginx

Nota:
En contenedores mínimos puede no existir systemd; el script usa fallbacks (service/pgrep).
