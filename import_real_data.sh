#!/usr/bin/env bash
set -euo pipefail

# Requiere que docker compose este levantado.
# Importa los primeros 50.000 features, que en la guia alcanzan para la zona
# de analisis Queens/Brooklyn.

docker run --rm \
  --network lab_default \
  -v "$PWD/datos-nyc:/data:ro" \
  3dcitydb/citydb-tool:latest \
  import citygml --limit 50000 \
  -H citydb -d laboratorio -u postgres -p postgres \
  "/data/NYC_Buildings_LoD2_CityGML.zip" \
  "/data/NYC_CityGML_LoD2_Roadbed.zip" \
  "/data/NYC_CityGML_LoD2_Intersection.zip" \
  "/data/NYC_CityGML_LoD2_Entrance.zip" \
  "/data/NYC_CityGML_LoD2_Median_Grass.zip" \
  "/data/NYC_CityGML_LoD2_Median_Painted.zip" \
  "/data/NYC_CityGML_LoD2_Median_Raised.zip" \
  "/data/NYC_CityGML_LoD2_Parking_Lot.zip" \
  "/data/NYC_CityGML_LoD2_Plaza.zip" \
  "/data/NYC_CityGML_LoD2_Track.zip"

ogr2ogr \
  -f "PostgreSQL" \
  "PG:host=localhost port=5432 dbname=laboratorio user=postgres password=postgres" \
  datos-nyc/mappluto_26v1/mappluto.shp \
  -nln public.mappluto \
  -nlt MULTIPOLYGON \
  -t_srs EPSG:32118 \
  -s_srs EPSG:2263 \
  -lco GEOMETRY_NAME=geom \
  -lco FID=gid \
  -overwrite \
  --config PG_USE_COPY YES

psql "host=localhost port=5432 dbname=laboratorio user=postgres password=postgres" <<'SQL'
CREATE INDEX IF NOT EXISTS mappluto_geom_idx ON public.mappluto USING GIST (geom);
CREATE INDEX IF NOT EXISTS mappluto_bbl_idx ON public.mappluto (bbl);
CREATE INDEX IF NOT EXISTS mappluto_zonedist1_idx ON public.mappluto (zonedist1);
ANALYZE public.mappluto;
SQL

psql "host=localhost port=5432 dbname=laboratorio user=postgres password=postgres" \
  -f vistas_sql.sql
