#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "ERROR - $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "falta '$1'"
}

need docker
need curl

wait_for_url() {
  local label="$1"
  local url="$2"
  local output="$3"
  local max_attempts="${4:-36}"
  local sleep_seconds="${5:-5}"

  for attempt in $(seq 1 "$max_attempts"); do
    if curl -fsS "$url" > "$output"; then
      return 0
    fi
    echo "  ${label}: esperando servicio (${attempt}/${max_attempts})..."
    sleep "$sleep_seconds"
  done

  fail "${label} no respondio despues de $((max_attempts * sleep_seconds)) segundos"
}

echo "Chequeando contenedores..."
docker compose ps >/dev/null

echo "Chequeando Postgres/3D CityDB..."
docker compose exec -T citydb pg_isready -U postgres -d laboratorio >/dev/null

COUNTS=$(docker compose exec -T citydb psql -U postgres -d laboratorio -t -A -F, -c "
select 'zona_analytics', count(*) from public.zona_analytics
union all
select 'v_lod2_buildings_3dtiles', count(*) from public.v_lod2_buildings_3dtiles
union all
select 'mappluto', count(*) from public.mappluto;
")

echo "$COUNTS"

echo "$COUNTS" | grep -q '^zona_analytics,5395$' \
  || fail "conteo inesperado para public.zona_analytics"
echo "$COUNTS" | grep -q '^v_lod2_buildings_3dtiles,5392$' \
  || fail "conteo inesperado para public.v_lod2_buildings_3dtiles"
echo "$COUNTS" | grep -q '^mappluto,4086$' \
  || fail "conteo inesperado para public.mappluto"

echo "Chequeando visor Cesium..."
wait_for_url "Visor Cesium" "http://localhost:8081/" "/tmp/lab_viewer.html"
grep -q 'Sombra solar 3D' /tmp/lab_viewer.html \
  || fail "el visor no contiene el panel de sombra solar"
grep -q 'LoD2 Real 3D' /tmp/lab_viewer.html \
  || fail "el visor no contiene el modo LoD2"

echo "Chequeando GeoServer/WFS..."
wait_for_url \
  "GeoServer WFS" \
  "http://localhost:8080/geoserver/tsig/ows?service=WFS&version=2.0.0&request=GetFeature&typeName=tsig:zona_analytics&outputFormat=application%2Fjson&srsName=EPSG:4326&count=1" \
  "/tmp/lab_wfs.json"
grep -q '"FeatureCollection"' /tmp/lab_wfs.json \
  || fail "GeoServer WFS no devolvio FeatureCollection"

echo "Chequeando 3D Tiles LoD2..."
TILESET=$(curl -fsS http://localhost:8081/tiles/lod2/tileset.json)
echo "$TILESET" | grep -q '"region"' \
  || fail "tileset.json no tiene boundingVolume.region"
echo "$TILESET" | grep -q '0.0' \
  || fail "tileset.json no parece estar normalizado a z=0"

echo "Chequeando queries parametrizables..."
QUERY_LIMIT=1 ./scripts/run_queries.sh >/tmp/lab_queries_smoke.log
grep -q 'Q12 - Outliers de altura respecto al entorno' /tmp/lab_queries_smoke.log \
  || fail "queries_simulacion.sql no llego hasta Q12"

echo "OK - VM lista para evaluacion."
