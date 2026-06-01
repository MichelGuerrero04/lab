#!/usr/bin/env bash
set -euo pipefail

mkdir -p datos-nyc

BUILDINGS_BASE="https://www.3dcitydb.org/3dcitydb/fileadmin/public/datasets/NYC/NYC_buildings_CityGML_LoD2"
STREETS_BASE="https://www.3dcitydb.org/3dcitydb/fileadmin/public/datasets/NYC/NYC_street_space_CityGML_LoD2"

curl -L -C - -o datos-nyc/NYC_Buildings_LoD2_CityGML.zip \
  "$BUILDINGS_BASE/NYC_Buildings_LoD2_CityGML.zip"

for file in \
  NYC_CityGML_LoD2_Roadbed.zip \
  NYC_CityGML_LoD2_Intersection.zip \
  NYC_CityGML_LoD2_Entrance.zip \
  NYC_CityGML_LoD2_Median_Grass.zip \
  NYC_CityGML_LoD2_Median_Painted.zip \
  NYC_CityGML_LoD2_Median_Raised.zip \
  NYC_CityGML_LoD2_Parking_Lot.zip \
  NYC_CityGML_LoD2_Plaza.zip \
  NYC_CityGML_LoD2_Track.zip
do
  curl -L -C - -o "datos-nyc/$file" "$STREETS_BASE/$file"
done

curl -L -C - -o datos-nyc/mappluto_26v1_shp.zip \
  "https://edm-publishing.nyc3.digitaloceanspaces.com/db-pluto/publish/26v1/mappluto/mappluto.shp.zip"

mkdir -p datos-nyc/mappluto_26v1
unzip -n datos-nyc/mappluto_26v1_shp.zip -d datos-nyc/mappluto_26v1
