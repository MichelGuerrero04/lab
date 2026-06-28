#!/usr/bin/env bash
set -euo pipefail

# Importa el caso de estudio real usado por el visor:
# 1. recorta el CityGML enorme a la bbox del laboratorio,
# 2. importa edificios LoD2 en 3D CityDB,
# 3. carga MapPLUTO recortado para zoning/FAR,
# 4. crea vistas analiticas,
# 5. genera 3D Tiles LoD2 con Z normalizada,
# 6. publica capas WFS en GeoServer.

BBOX_CITYDB="308000 60500 309500 62000"
MAPPLUTO_SPAT="1010496.6666666667 198490.4166666667 1015417.9166666667 203411.6666666667"
BUILDINGS_ZIP="datos-nyc/NYC_Buildings_LoD2_CityGML.zip"
BUILDINGS_GML="datos-nyc/NYC_Buildings_LoD2_bbox.gml"
MAPPLUTO_ZIP="datos-nyc/mappluto_26v1_shp.zip"
PG_CONN="PG:host=localhost port=5432 dbname=laboratorio user=postgres password=postgres"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: falta '$1'." >&2
    exit 1
  fi
}

need docker
need 7z
need python3
need ogr2ogr
need curl

if [ ! -f "$BUILDINGS_ZIP" ] || [ ! -f "$MAPPLUTO_ZIP" ]; then
  echo "ERROR: faltan datos en datos-nyc/."
  echo "Ejecuta primero: ./download_real_data.sh"
  exit 1
fi

echo "Levantando servicios Docker..."
docker compose up -d

echo "Esperando a que Postgres/3D CityDB este listo..."
for i in $(seq 1 30); do
  if docker compose exec -T citydb pg_isready -U postgres -d laboratorio >/dev/null 2>&1; then
    break
  fi
  if [ "$i" = "30" ]; then
    echo "ERROR: Postgres no quedo listo." >&2
    exit 1
  fi
  sleep 2
done

if [ ! -f "$BUILDINGS_GML" ]; then
  echo "Generando CityGML recortado por bbox..."
  7z x -so "$BUILDINGS_ZIP" NYC_Buildings_LoD2_CityGML.gml \
    | python3 scripts/filter_citygml_bbox.py \
        --bbox $BBOX_CITYDB \
        --output "$BUILDINGS_GML"
else
  echo "CityGML recortado ya existe: $BUILDINGS_GML"
fi

FEATURE_COUNT=$(docker compose exec -T citydb psql -U postgres -d laboratorio -t -A -c "select count(*) from citydb.feature;")
if [ "$FEATURE_COUNT" = "0" ]; then
  echo "Importando edificios LoD2 en 3D CityDB..."
  docker run --rm \
    --network lab_default \
    -v "$PWD/datos-nyc:/data:ro" \
    3dcitydb/citydb-tool:latest \
    import citygml --compute-extent \
    -H citydb -d laboratorio -u postgres -p postgres \
    "/data/$(basename "$BUILDINGS_GML")"
else
  echo "3D CityDB ya tiene $FEATURE_COUNT features; se omite import CityGML."
  echo "Para empezar limpio: docker compose down -v && docker compose up -d"
fi

echo "Cargando MapPLUTO recortado y reproyectado a EPSG:32118..."
ogr2ogr \
  -f PostgreSQL \
  "$PG_CONN" \
  "/vsizip/$PWD/$MAPPLUTO_ZIP/mappluto.shp" \
  -nln public.mappluto \
  -overwrite \
  -lco GEOMETRY_NAME=geom \
  -lco FID=gid \
  -nlt MULTIPOLYGON \
  -t_srs EPSG:32118 \
  -spat $MAPPLUTO_SPAT

echo "Preparando indices de MapPLUTO..."
docker compose exec -T citydb psql -U postgres -d laboratorio -v ON_ERROR_STOP=1 <<'SQL'
CREATE INDEX IF NOT EXISTS mappluto_geom_idx ON public.mappluto USING GIST (geom);
CREATE INDEX IF NOT EXISTS mappluto_bbl_idx ON public.mappluto (bbl);
CREATE INDEX IF NOT EXISTS mappluto_zonedist1_idx ON public.mappluto (zonedist1);
ANALYZE public.mappluto;
SQL

echo "Eliminando relaciones demo si existieran..."
docker compose exec -T citydb psql -U postgres -d laboratorio -v ON_ERROR_STOP=1 <<'SQL'
DROP TABLE IF EXISTS public.zona_analytics CASCADE;
DROP TABLE IF EXISTS public.zona_buildings CASCADE;
DROP TABLE IF EXISTS public.zona_roads CASCADE;
DROP TABLE IF EXISTS public.v_buildings_3d CASCADE;
SQL

echo "Creando vistas analiticas..."
docker compose exec -T citydb psql -U postgres -d laboratorio -v ON_ERROR_STOP=1 < vistas_sql.sql

echo "Creando vista LoD2 normalizada para 3D Tiles..."
docker compose exec -T citydb psql -U postgres -d laboratorio -v ON_ERROR_STOP=1 < create_lod2_tiles_view.sql

echo "Regenerando 3D Tiles LoD2..."
rm -rf web/tiles/lod2/*
docker compose run --rm pg2b3dm-converter

echo "Publicando capas en GeoServer..."
bash geoserver-setup.sh

echo ""
echo "Listo. Verifica conteos con:"
echo "docker compose exec -T citydb psql -U postgres -d laboratorio -c \"select count(*) from public.zona_analytics;\""
echo ""
echo "Abre el visor:"
echo "http://localhost:8081"
