#!/usr/bin/env bash
set -euo pipefail

mkdir -p outputs

QUERY_LIMIT="${QUERY_LIMIT:-20}"
VECINOS_RADIO_M="${VECINOS_RADIO_M:-30}"
DESARROLLO_RADIO_M="${DESARROLLO_RADIO_M:-25}"
FAR_DISPONIBLE_MIN="${FAR_DISPONIBLE_MIN:-0.5}"
AREA_MIN_M2="${AREA_MIN_M2:-200}"
SOLAR_AREA_MIN_M2="${SOLAR_AREA_MIN_M2:-100}"
HISTORICO_ANIO_MAX="${HISTORICO_ANIO_MAX:-1940}"

OUT="outputs/queries_simulacion_$(date +%Y%m%d_%H%M%S).txt"

echo "Ejecutando queries_simulacion.sql..."
echo "Salida: $OUT"
echo ""
echo "Parametros:"
echo "  QUERY_LIMIT=$QUERY_LIMIT"
echo "  VECINOS_RADIO_M=$VECINOS_RADIO_M"
echo "  DESARROLLO_RADIO_M=$DESARROLLO_RADIO_M"
echo "  FAR_DISPONIBLE_MIN=$FAR_DISPONIBLE_MIN"
echo "  AREA_MIN_M2=$AREA_MIN_M2"
echo "  SOLAR_AREA_MIN_M2=$SOLAR_AREA_MIN_M2"
echo "  HISTORICO_ANIO_MAX=$HISTORICO_ANIO_MAX"
echo ""

docker compose exec -T citydb psql \
  -U postgres \
  -d laboratorio \
  -v ON_ERROR_STOP=1 \
  -v query_limit="$QUERY_LIMIT" \
  -v vecinos_radio_m="$VECINOS_RADIO_M" \
  -v desarrollo_radio_m="$DESARROLLO_RADIO_M" \
  -v far_disponible_min="$FAR_DISPONIBLE_MIN" \
  -v area_min_m2="$AREA_MIN_M2" \
  -v solar_area_min_m2="$SOLAR_AREA_MIN_M2" \
  -v historico_anio_max="$HISTORICO_ANIO_MAX" \
  < queries_simulacion.sql | tee "$OUT"
