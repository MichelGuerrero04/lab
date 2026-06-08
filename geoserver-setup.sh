#!/bin/bash
# Configura GeoServer via REST API (idempotente — puede correrse multiples veces)
# 1. Crea workspace "tsig"
# 2. Crea datastore PostGIS "laboratorio" con conexion a citydb
# 3. Publica capas: zona_analytics, zona_roads, zona_buildings, v_buildings_3d

GS="http://localhost:8080/geoserver"
AUTH="admin:geoserver"
WS="tsig"
DS="laboratorio"

wait_geoserver() {
  echo "Esperando GeoServer (max 3 min)..."
  for i in $(seq 1 36); do
    code=$(curl -s -o /dev/null -w "%{http_code}" -u "$AUTH" "$GS/rest/workspaces" 2>/dev/null)
    if [ "$code" = "200" ]; then echo "GeoServer listo."; return 0; fi
    echo "  intento $i/36 (HTTP $code)..."
    sleep 5
  done
  echo "ERROR: GeoServer no respondio en 3min"; exit 1
}

wait_geoserver

# Workspace
echo -n "Workspace '$WS'... "
curl -s -u "$AUTH" -X POST "$GS/rest/workspaces" \
  -H "Content-Type: application/json" \
  -d "{\"workspace\":{\"name\":\"$WS\"}}" -o /dev/null -w "HTTP %{http_code}\n"

# Datastore ($ = value en kartoza/geoserver)
echo -n "Datastore '$DS'... "
# Delete first to ensure clean state
curl -s -u "$AUTH" -X DELETE "$GS/rest/workspaces/$WS/datastores/$DS?recurse=true" -o /dev/null 2>/dev/null
curl -s -u "$AUTH" -X POST "$GS/rest/workspaces/$WS/datastores" \
  -H "Content-Type: application/json" \
  -d '{
    "dataStore": {
      "name": "'"$DS"'",
      "type": "PostGIS",
      "enabled": true,
      "connectionParameters": {
        "entry": [
          {"@key":"host",     "$":"citydb"},
          {"@key":"port",     "$":"5432"},
          {"@key":"database", "$":"laboratorio"},
          {"@key":"user",     "$":"postgres"},
          {"@key":"passwd",   "$":"postgres"},
          {"@key":"dbtype",   "$":"postgis"},
          {"@key":"schema",   "$":"public"}
        ]
      }
    }
  }' -o /dev/null -w "HTTP %{http_code}\n"

# Capas
for TABLE in zona_analytics zona_roads zona_buildings v_buildings_3d; do
  echo -n "Capa '$TABLE'... "
  curl -s -u "$AUTH" -X POST \
    "$GS/rest/workspaces/$WS/datastores/$DS/featuretypes" \
    -H "Content-Type: application/json" \
    -d '{
      "featureType": {
        "name": "'"$TABLE"'",
        "nativeName": "'"$TABLE"'",
        "srs": "EPSG:4326",
        "nativeSRS": "EPSG:32118",
        "projectionPolicy": "REPROJECT_TO_DECLARED",
        "enabled": true
      }
    }' -o /dev/null -w "HTTP %{http_code}\n"
done

echo ""
echo "=== GeoServer configurado ==="
echo "Admin UI:     http://localhost:8080/geoserver/web"
echo "WFS endpoint: http://localhost:8080/geoserver/tsig/ows?service=WFS&version=2.0.0&request=GetCapabilities"
echo "WMS endpoint: http://localhost:8080/geoserver/tsig/wms?service=WMS&version=1.1.1&request=GetCapabilities"
echo ""
echo "Visor Cesium: http://localhost:8081"
