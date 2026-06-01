#!/usr/bin/env bash
set -euo pipefail

mkdir -p datos-nyc

BUILDINGS_BASE="https://www.3dcitydb.org/3dcitydb/fileadmin/public/datasets/NYC/NYC_buildings_CityGML_LoD2"

echo "Descargando CityGML NYC Buildings LoD2..."
curl -L -C - -o datos-nyc/NYC_Buildings_LoD2_CityGML.zip \
  "$BUILDINGS_BASE/NYC_Buildings_LoD2_CityGML.zip"

echo "Descargando MapPLUTO 26v1..."
curl -L -C - -o datos-nyc/mappluto_26v1_shp.zip \
  "https://edm-publishing.nyc3.digitaloceanspaces.com/db-pluto/publish/26v1/mappluto/mappluto.shp.zip"

echo ""
echo "Datos descargados en datos-nyc/."
echo "No se descomprime el CityGML completo porque el GML pesa mas de 31 GB."
