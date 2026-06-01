# Lab - visor Cesium + GeoServer + 3D CityDB

## Estado actual

El laboratorio queda levantado con Docker Compose:

- PostgreSQL/PostGIS + 3D CityDB: `localhost:5432`
- GeoServer: `http://localhost:8082/geoserver`
- Visor Cesium: `http://localhost:8081`

GeoServer usa `8082` porque `8080` estaba ocupado por otro servicio local.

## Comandos

Levantar servicios:

```bash
docker compose up -d
```

Cargar datos demo:

```bash
psql "host=localhost port=5432 dbname=laboratorio user=postgres password=postgres" \
  -f seed_demo_data.sql
```

Verificar WFS:

```bash
curl "http://localhost:8082/geoserver/tsig/ows?service=WFS&version=2.0.0&request=GetFeature&typeName=tsig:zona_analytics&outputFormat=application%2Fjson&srsName=EPSG:4326&count=1"
```

## Datos cargados ahora

El visor ya no usa la capa sintetica de 96 edificios. Quedo cargado un recorte real del caso NYC:

- CityGML NYC Buildings LoD2, importado en 3D CityDB.
- Recorte espacial: bbox `308000,60500,309500,62000` en `EPSG:32118`.
- MapPLUTO 26v1 recortado a la misma zona y reproyectado a `EPSG:32118`.
- Vista principal publicada por GeoServer: `tsig:zona_analytics`.

Conteos actuales:

- `citydb.feature`: 60937 features CityGML importadas.
- `public.mappluto`: 4086 lotes MapPLUTO.
- `public.v_buildings_3d`: 5392 edificios.
- `public.zona_buildings`: 5393 geometrias de base desde `GroundSurface`.
- `public.zona_analytics`: 5395 registros con metricas + zoning/FAR.
- `public.zona_roads`: 0, porque en esta corrida solo se importaron edificios, no calles CityGML.

Nota: la guia original menciona 1597 edificios como resultado esperado de otra corrida del dataset. En esta carga se filtro el CityGML real completo por la bbox del caso de estudio; por eso el conteo actual es mayor, pero sigue siendo dato real de NYC y no maqueta.

## Cargar datos reales desde cero

Descargar datos NYC:

```bash
./download_real_data.sh
```

Esto descarga aproximadamente:

- `NYC_Buildings_LoD2_CityGML.zip`: 2.46 GB
- `mappluto_26v1_shp.zip`: 142 MB

Como el ZIP de CityGML usa Deflate64 y el GML completo pesa mas de 31 GB descomprimido, conviene generar primero un recorte:

```bash
7z x -so datos-nyc/NYC_Buildings_LoD2_CityGML.zip NYC_Buildings_LoD2_CityGML.gml \
  | python3 scripts/filter_citygml_bbox.py \
      --bbox 308000 60500 309500 62000 \
      --output datos-nyc/NYC_Buildings_LoD2_bbox.gml
```

Importar el recorte a 3D CityDB:

```bash
docker run --rm --network lab_default -v "$PWD/datos-nyc:/data:ro" \
  3dcitydb/citydb-tool:latest import citygml --compute-extent \
  -H citydb -d laboratorio -u postgres -p postgres \
  /data/NYC_Buildings_LoD2_bbox.gml
```

Cargar MapPLUTO recortado:

```bash
ogr2ogr -f PostgreSQL \
  "PG:host=localhost port=5432 dbname=laboratorio user=postgres password=postgres" \
  /vsizip/$PWD/datos-nyc/mappluto_26v1_shp.zip/mappluto.shp \
  -nln public.mappluto -overwrite \
  -lco GEOMETRY_NAME=geom -lco FID=gid \
  -nlt MULTIPOLYGON -t_srs EPSG:32118 \
  -spat 1010496.6666666667 198490.4166666667 1015417.9166666667 203411.6666666667
```

Recrear vistas:

```bash
docker exec -i lab-citydb-1 psql -U postgres -d laboratorio < vistas_sql.sql
```

Luego abrir:

```text
http://localhost:8081
```
