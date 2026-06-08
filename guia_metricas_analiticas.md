# Guia de Metricas Analiticas Urbanas - NYC 3DCityDB
## Capa: zona_analytics (PostgreSQL/PostGIS -> QGIS)

---

## PARTE 1 - Preparacion del entorno y datos

> **IMPORTANTE — SRID 32118:**
> Todos los datos NYC estan en **EPSG:32118** (NAD83 / New York Long Island).
> El esquema 3DCityDB **debe** instalarse con este SRID o las geometrias apareceran
> en el lugar incorrecto en QGIS. En la opcion Docker esto se configura automaticamente.
> En la opcion manual hay que pasarlo explicitamente al script de instalacion.

---

### Requisitos comunes (ambas opciones)

- **QGIS 3.x** instalado
- Conexion a internet para descargar datos NYC

---

### Opcion A — Docker (recomendada)

No requiere instalar PostgreSQL, Java, PostGIS ni 3DCityDB manualmente.

**Requisitos adicionales:** Docker y Docker Compose instalados.

| Componente | Version | Como se levanta |
|---|---|---|
| PostgreSQL | 18 | incluido en imagen 3dcitydb-pg |
| PostGIS | 3.6 | incluido en imagen 3dcitydb-pg |
| 3DCityDB | 5.1.3 | incluido en imagen 3dcitydb-pg |
| citydb-tool | latest | imagen separada, se usa como comando |

#### Paso A.1 - Levantar la base de datos

Crear el archivo `docker-compose.yml` en la carpeta del proyecto:

```yaml
services:
  citydb:
    image: 3dcitydb/3dcitydb-pg:5.1.3-alpine
    environment:
      SRID: 32118
      SRS_NAME: "urn:ogc:def:crs:EPSG::32118"
      POSTGRES_DB: laboratorio
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - citydb_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d laboratorio"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  citydb_data:
```

Levantar el contenedor:

```bash
docker compose up -d
```

La imagen descarga automaticamente (~200MB) y crea el esquema `citydb` con SRID 32118 automaticamente.
Esperar ~30 segundos hasta que el healthcheck diga `(healthy)`.

```bash
docker compose ps
```

**Datos de conexion:**
```
Host:     localhost  |  Puerto: 5432
Base:     laboratorio
Usuario:  postgres   |  Password: postgres
```

Ir directo al **Paso 2** (descarga de datos).

---

### Opcion B — Instalacion manual

**Requisitos adicionales:**
- PostgreSQL 17 con extensiones **PostGIS** y **postgis_sfcgal**
- Java 17 o superior
- 3DCityDB 5.1.3 (carpeta extraida localmente)
- citydb-tool 1.3.1 (carpeta extraida localmente)

Descargas:
- 3DCityDB: `https://github.com/3dcitydb/3dcitydb/releases/tag/v5.1.3`
- citydb-tool: `https://github.com/3dcitydb/citydb-tool/releases/tag/v1.3.1`

#### Paso B.1 - Crear la base de datos

En pgAdmin o psql:
```sql
CREATE DATABASE laboratorio;
```

Conectarse a `laboratorio` y ejecutar:
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;
```

#### Paso B.2 - Configurar la conexion

Editar el archivo de conexion del 3DCityDB:
```
3dcitydb-5.1.3/postgresql/shell-scripts/unix/connection-details.sh   (Linux/Mac)
3dcitydb-5.1.3\postgresql\shell-scripts\windows\connection-details.bat  (Windows)
```

```
PGBIN   = /usr/bin  (Linux) o C:\Program Files\PostgreSQL\17\bin (Windows)
PGHOST  = localhost
PGPORT  = 5432
CITYDB  = laboratorio
PGUSER  = postgres
```

#### Paso B.3 - Instalar el esquema 3DCityDB

> **IMPORTANTE:** Usar SRID **32118**. Los datos NYC estan en este sistema de coordenadas.

**Linux / Mac:**
```bash
psql -U postgres -d laboratorio \
  -f "ruta/3dcitydb-5.1.3/postgresql/sql-scripts/create-db.sql" \
  -v srid="32118" \
  -v srs_name="urn:ogc:def:crs:EPSG::32118" \
  -v changelog="no"
```

**Windows (CMD):**
```cmd
psql -U postgres -d laboratorio ^
  -f "ruta\3dcitydb-5.1.3\postgresql\sql-scripts\create-db.sql" ^
  -v srid="32118" ^
  -v srs_name="urn:ogc:def:crs:EPSG::32118" ^
  -v changelog="no"
```

Debe mostrar al final: `3DCityDB instance successfully created.`

**Datos de conexion:**
```
Host:     localhost  |  Puerto: 5432
Base:     laboratorio
Usuario:  postgres
```

Continuar en el **Paso 2** (descarga de datos).

---

### Paso 2 - Descargar los archivos de datos NYC CityGML LoD2

Crear carpeta para los datos:
```bash
mkdir -p datos-nyc
```

#### Archivos de calles y espacios urbanos

Todos en: `http://www.3dcitydb.net/3dcitydb/fileadmin/public/datasets/NYC/NYC_street_space_CityGML_LoD2/`

| Archivo ZIP | Tamano comprimido | Comando wget |
|---|---|---|
| NYC_CityGML_LoD2_Roadbed.zip | ~132 MB | `wget [URL_base]/NYC_CityGML_LoD2_Roadbed.zip` |
| NYC_CityGML_LoD2_Intersection.zip | ~8 MB | `wget [URL_base]/NYC_CityGML_LoD2_Intersection.zip` |
| NYC_CityGML_LoD2_Entrance.zip | ~5.6 MB | `wget [URL_base]/NYC_CityGML_LoD2_Entrance.zip` |
| NYC_CityGML_LoD2_Median_Grass.zip | ~302 KB | `wget [URL_base]/NYC_CityGML_LoD2_Median_Grass.zip` |
| NYC_CityGML_LoD2_Median_Painted.zip | ~4 MB | `wget [URL_base]/NYC_CityGML_LoD2_Median_Painted.zip` |
| NYC_CityGML_LoD2_Median_Raised.zip | ~75 MB | `wget [URL_base]/NYC_CityGML_LoD2_Median_Raised.zip` |
| NYC_CityGML_LoD2_Parking_Lot.zip | ~33 MB | `wget [URL_base]/NYC_CityGML_LoD2_Parking_Lot.zip` |
| NYC_CityGML_LoD2_Plaza.zip | ~5.6 MB | `wget [URL_base]/NYC_CityGML_LoD2_Plaza.zip` |
| NYC_CityGML_LoD2_Track.zip | ~16 MB | `wget [URL_base]/NYC_CityGML_LoD2_Track.zip` |

Descarga de todos los archivos de calles de una vez:
```bash
BASE="http://www.3dcitydb.net/3dcitydb/fileadmin/public/datasets/NYC/NYC_street_space_CityGML_LoD2"
cd datos-nyc
wget "$BASE/NYC_CityGML_LoD2_Roadbed.zip" \
     "$BASE/NYC_CityGML_LoD2_Intersection.zip" \
     "$BASE/NYC_CityGML_LoD2_Entrance.zip" \
     "$BASE/NYC_CityGML_LoD2_Median_Grass.zip" \
     "$BASE/NYC_CityGML_LoD2_Median_Painted.zip" \
     "$BASE/NYC_CityGML_LoD2_Median_Raised.zip" \
     "$BASE/NYC_CityGML_LoD2_Parking_Lot.zip" \
     "$BASE/NYC_CityGML_LoD2_Plaza.zip" \
     "$BASE/NYC_CityGML_LoD2_Track.zip"
```

#### Archivo de edificios (el mas grande)

```bash
wget "http://www.3dcitydb.net/3dcitydb/fileadmin/public/datasets/NYC/NYC_buildings_CityGML_LoD2/NYC_Buildings_LoD2_CityGML.zip"
```

> Tamano: ~2.3 GB comprimido, ~30 GB descomprimido. Puede tardar 20-40 minutos segun la conexion.

**Zona de analisis (bounding box en EPSG:32118):**
```
x_min: 308000  y_min: 60500
x_max: 309500  y_max: 62000
```
Corresponde a ~2.25 km2 del area Queens/Brooklyn (Middle Village / Glendale), NYC.
Esta zona fue elegida por tener maxima diversidad de distritos de zonificacion:
R4, R4-1, R4B, R5B, M1-1, R6B, PARK.

---

### Paso 3 - Descomprimir los archivos

```bash
cd datos-nyc
for f in *.zip; do unzip -q "$f" -d "${f%.zip}"; done
```

---

### Paso 4 - Importar los datos con citydb-tool

> `--limit 50000` importa los primeros 50.000 features. Suficiente para cubrir
> la zona de analisis de Brooklyn (~2625 edificios). Sin limite la importacion
> completa puede tardar varias horas.

#### Opcion A — Docker

Reemplazar `$(pwd)/datos-nyc` por la ruta absoluta a tu carpeta si es necesario.

**Calles, plazas y espacios urbanos:**
```bash
docker run --rm --network host \
  -v "$(pwd)/datos-nyc:/data" \
  3dcitydb/citydb-tool:latest \
  import citygml --limit 50000 \
  -H localhost -d laboratorio -u postgres -p postgres \
  "/data/NYC_CityGML_LoD2_Roadbed/Roadbed/Road.gml" \
  "/data/NYC_CityGML_LoD2_Intersection/Intersection/Road/Road.gml" \
  "/data/NYC_CityGML_LoD2_Entrance/Entrance/Road.gml" \
  "/data/NYC_CityGML_LoD2_Median_Grass/Median_Grass/Road.gml" \
  "/data/NYC_CityGML_LoD2_Median_Painted/Median_Painted/Road.gml" \
  "/data/NYC_CityGML_LoD2_Median_Raised/Median_Raised/Road.gml" \
  "/data/NYC_CityGML_LoD2_Parking_Lot/Parking_Lot/Square.gml" \
  "/data/NYC_CityGML_LoD2_Plaza/Plaza/Square.gml" \
  "/data/NYC_CityGML_LoD2_Track/Track/Track.gml"
```

**Edificios:**
```bash
docker run --rm --network host \
  -v "$(pwd)/datos-nyc:/data" \
  3dcitydb/citydb-tool:latest \
  import citygml --limit 50000 \
  -H localhost -d laboratorio -u postgres -p postgres \
  "/data/NYC_Buildings_LoD2_CityGML/NYC_Buildings_LoD2_CityGML.gml"
```

**Curb y Sidewalk** (cada uno tiene 10 archivos):
```bash
docker run --rm --network host \
  -v "$(pwd)/datos-nyc:/data" \
  3dcitydb/citydb-tool:latest \
  import citygml --limit 50000 \
  -H localhost -d laboratorio -u postgres -p postgres \
  "/data/NYC_CityGML_LoD2_Curb/Curb/0/0.gml" \
  "/data/NYC_CityGML_LoD2_Curb/Curb/1/1.gml" \
  "/data/NYC_CityGML_LoD2_Curb/Curb/2/2.gml" \
  "/data/NYC_CityGML_LoD2_Curb/Curb/3/3.gml" \
  "/data/NYC_CityGML_LoD2_Curb/Curb/4/4.gml" \
  "/data/NYC_CityGML_LoD2_Curb/Curb/5/5.gml" \
  "/data/NYC_CityGML_LoD2_Curb/Curb/6/6.gml" \
  "/data/NYC_CityGML_LoD2_Curb/Curb/7/7.gml" \
  "/data/NYC_CityGML_LoD2_Curb/Curb/8/8.gml" \
  "/data/NYC_CityGML_LoD2_Curb/Curb/9/9.gml"
```
Repetir reemplazando `Curb` por `Sidewalk`.

#### Opcion B — Manual (citydb-tool instalado localmente)

Reemplazar `ruta` por donde extrajiste citydb-tool-1.3.1 y `TU_PASSWORD` por tu contrasena de postgres.

**Linux / Mac — calles y edificios:**
```bash
ruta/citydb-tool-1.3.1/citydb import citygml --limit 50000 \
  -H localhost -d laboratorio -u postgres -p TU_PASSWORD \
  "ruta/NYC_Buildings_LoD2_CityGML/NYC_Buildings_LoD2_CityGML.gml" \
  "ruta/NYC_CityGML_LoD2_Roadbed/Roadbed/Road.gml" \
  "ruta/NYC_CityGML_LoD2_Intersection/Intersection/Road/Road.gml" \
  "ruta/NYC_CityGML_LoD2_Entrance/Entrance/Road.gml" \
  "ruta/NYC_CityGML_LoD2_Median_Grass/Median_Grass/Road.gml" \
  "ruta/NYC_CityGML_LoD2_Median_Painted/Median_Painted/Road.gml" \
  "ruta/NYC_CityGML_LoD2_Median_Raised/Median_Raised/Road.gml" \
  "ruta/NYC_CityGML_LoD2_Parking_Lot/Parking_Lot/Square.gml" \
  "ruta/NYC_CityGML_LoD2_Plaza/Plaza/Square.gml" \
  "ruta/NYC_CityGML_LoD2_Track/Track/Track.gml"
```

**Windows (CMD):**
```cmd
ruta\citydb-tool-1.3.1\citydb.bat import citygml --limit 50000 ^
  -H localhost -d laboratorio -u postgres -p TU_PASSWORD ^
  "ruta\NYC_Buildings_LoD2_CityGML\NYC_Buildings_LoD2_CityGML.gml" ^
  "ruta\NYC_CityGML_LoD2_Roadbed\Roadbed\Road.gml" ^
  "ruta\NYC_CityGML_LoD2_Intersection\Intersection\Road\Road.gml" ^
  "ruta\NYC_CityGML_LoD2_Entrance\Entrance\Road.gml" ^
  "ruta\NYC_CityGML_LoD2_Median_Grass\Median_Grass\Road.gml" ^
  "ruta\NYC_CityGML_LoD2_Median_Painted\Median_Painted\Road.gml" ^
  "ruta\NYC_CityGML_LoD2_Median_Raised\Median_Raised\Road.gml" ^
  "ruta\NYC_CityGML_LoD2_Parking_Lot\Parking_Lot\Square.gml" ^
  "ruta\NYC_CityGML_LoD2_Plaza\Plaza\Square.gml" ^
  "ruta\NYC_CityGML_LoD2_Track\Track\Track.gml"
```

**Curb y Sidewalk (Linux):**
```bash
ruta/citydb-tool-1.3.1/citydb import citygml --limit 50000 \
  -H localhost -d laboratorio -u postgres -p TU_PASSWORD \
  ruta/NYC_CityGML_LoD2_Curb/Curb/{0..9}/{0..9}.gml
```
Repetir para Sidewalk.

---

### Paso 5 - Crear las vistas de trabajo

Conectarse a la base `laboratorio` desde pgAdmin, DBeaver o psql y ejecutar los siguientes scripts **en el orden indicado**. Cada vista depende de la anterior.

**Orden obligatorio:** v_buildings_3d -> zona_buildings -> zona_roads -> zona_analytics

**Opcion A — Docker:**
```bash
docker exec -i tsig-citydb-1 psql -U postgres -d laboratorio < vistas_sql.sql
```

**Opcion B — Manual (psql instalado):**
```bash
psql -U postgres -d laboratorio < vistas_sql.sql
```

**Opcion C — pgAdmin / DBeaver:** copiar y pegar cada bloque SQL en el Query Tool sobre la base `laboratorio`.

> El archivo `vistas_sql.sql` (en la carpeta del proyecto) contiene las 4 vistas en orden correcto.

#### Vista base de edificios completos (toda la ciudad)

```sql
CREATE MATERIALIZED VIEW public.v_buildings_3d AS
SELECT
    f.id AS qgis_id,
    ST_SetSRID(ST_Envelope(ST_Force2D(f.envelope)), 32118)::geometry(Polygon, 32118) AS geom,
    ROUND((ST_ZMax(Box3D(f.envelope)) - ST_ZMin(Box3D(f.envelope)))::numeric, 2) AS height,
    ROUND(ST_ZMin(Box3D(f.envelope))::numeric, 2) AS z_min,
    ROUND(ST_ZMax(Box3D(f.envelope))::numeric, 2) AS z_max
FROM citydb.feature f
JOIN citydb.objectclass oc ON f.objectclass_id = oc.id
WHERE oc.classname = 'Building'
  AND f.envelope IS NOT NULL;

CREATE INDEX v_buildings_3d_geom_idx ON public.v_buildings_3d USING GIST(geom);
```

#### Vista zona_buildings (zona de analisis, geometria real, Z=0)

```sql
CREATE MATERIALIZED VIEW public.zona_buildings AS
SELECT
    b.id AS qgis_id,
    ST_Force3DZ(ST_Force2D(ST_SetSRID(g.geometry, 32118)))::geometry(MultiPolygonZ, 32118) AS geom,
    ROUND((ST_ZMax(Box3D(b.envelope)) - ST_ZMin(Box3D(b.envelope)))::numeric, 2) AS height,
    0.0::numeric AS z_min,
    ROUND((ST_ZMax(Box3D(b.envelope)) - ST_ZMin(Box3D(b.envelope)))::numeric, 2) AS z_max,
    ROUND(ST_Area(ST_Force2D(ST_SetSRID(g.geometry, 32118)))::numeric, 2) AS area_planta,
    ROUND((ST_Area(ST_Force2D(ST_SetSRID(g.geometry, 32118))) *
        (ST_ZMax(Box3D(b.envelope)) - ST_ZMin(Box3D(b.envelope))))::numeric, 2) AS volumen,
    ROUND((CASE WHEN ST_Area(ST_Force2D(ST_SetSRID(g.geometry, 32118))) > 0
        THEN (ST_ZMax(Box3D(b.envelope)) - ST_ZMin(Box3D(b.envelope))) /
             ST_Area(ST_Force2D(ST_SetSRID(g.geometry, 32118)))
        ELSE 0 END)::numeric, 4) AS ratio_altura_area
FROM citydb.feature b
JOIN citydb.objectclass oc ON oc.id = b.objectclass_id AND oc.classname = 'Building'
JOIN citydb.property p ON p.feature_id = b.id AND p.name = 'boundary'
JOIN citydb.feature s ON s.id = p.val_feature_id
JOIN citydb.objectclass ocs ON ocs.id = s.objectclass_id AND ocs.classname = 'GroundSurface'
JOIN citydb.geometry_data g ON g.feature_id = s.id
WHERE b.envelope IS NOT NULL AND g.geometry IS NOT NULL
  AND ST_SetSRID(g.geometry, 32118) && ST_MakeEnvelope(308000, 60500, 309500, 62000, 32118);

CREATE INDEX zona_buildings_geom_idx ON public.zona_buildings USING GIST(geom);
```

#### Vista zona_roads (calles de la zona recortadas al bbox)

```sql
CREATE MATERIALIZED VIEW public.zona_roads AS
SELECT
    g.id AS qgis_id,
    oc.classname AS tipo,
    ST_Force3DZ(
        ST_CollectionExtract(
            ST_Intersection(
                ST_MakeValid(ST_SetSRID(g.geometry, 32118)),
                ST_MakeEnvelope(307800, 60200, 308800, 61200, 32118)
            ), 3)
    )::geometry(MultiPolygonZ, 32118) AS geom
FROM citydb.geometry_data g
JOIN citydb.feature f ON g.feature_id = f.id
JOIN citydb.objectclass oc ON f.objectclass_id = oc.id
WHERE oc.classname IN ('Road', 'Square', 'Track')
  AND g.geometry IS NOT NULL
  AND ST_SetSRID(g.geometry, 32118) && ST_MakeEnvelope(308000, 60500, 309500, 62000, 32118);

CREATE INDEX zona_roads_geom_idx ON public.zona_roads USING GIST(geom);
```

#### Vista zona_analytics (metricas analiticas urbanas)

```sql
CREATE MATERIALIZED VIEW public.zona_analytics AS
WITH edificios AS (
    SELECT qgis_id, geom, height, z_min, area_planta, volumen,
           ratio_altura_area, ST_Force2D(geom) AS geom2d
    FROM public.zona_buildings
    WHERE height > 0 AND area_planta > 0
),
orientacion AS (
    SELECT qgis_id,
        DEGREES(ST_Azimuth(
            ST_PointN(ST_ExteriorRing(ST_Envelope(geom2d)), 1),
            ST_PointN(ST_ExteriorRing(ST_Envelope(geom2d)), 2)
        )) AS azimuth_fachada
    FROM edificios
),
vecinos AS (
    SELECT a.qgis_id,
        COUNT(b.qgis_id) - 1 AS edificios_proximos_20m
    FROM edificios a
    JOIN edificios b ON ST_DWithin(a.geom2d, b.geom2d, 20)
    GROUP BY a.qgis_id
)
SELECT
    e.qgis_id, e.geom, e.height, e.z_min,
    ROUND(e.area_planta::numeric, 2) AS area_planta,
    ROUND(e.volumen::numeric, 2) AS volumen,
    ROUND(e.ratio_altura_area::numeric, 4) AS ratio_altura_area,
    CASE
        WHEN e.height < 5  THEN '1-2 pisos'
        WHEN e.height < 10 THEN '3-4 pisos'
        WHEN e.height < 20 THEN '5-7 pisos'
        ELSE 'Alto +8 pisos'
    END AS categoria_altura,
    CASE
        WHEN o.azimuth_fachada < 45  OR o.azimuth_fachada >= 315 THEN 'Norte'
        WHEN o.azimuth_fachada < 135 THEN 'Este'
        WHEN o.azimuth_fachada < 225 THEN 'Sur'
        ELSE 'Oeste'
    END AS orientacion_fachada,
    CASE
        WHEN o.azimuth_fachada >= 90 AND o.azimuth_fachada < 270 THEN 'Alta'
        WHEN o.azimuth_fachada >= 45 AND o.azimuth_fachada < 315 THEN 'Media'
        ELSE 'Baja'
    END AS exposicion_solar,
    v.edificios_proximos_20m,
    CASE
        WHEN v.edificios_proximos_20m >= 5 THEN 'Muy densa'
        WHEN v.edificios_proximos_20m >= 2 THEN 'Densa'
        ELSE 'Aislada'
    END AS densidad_entorno
FROM edificios e
JOIN orientacion o ON o.qgis_id = e.qgis_id
JOIN vecinos v ON v.qgis_id = e.qgis_id;

CREATE INDEX zona_analytics_geom_idx ON public.zona_analytics USING GIST(geom);
```

Refrescar vistas si se reimportan datos:
```bash
docker exec tsig-citydb-1 psql -U postgres -d laboratorio -c "
REFRESH MATERIALIZED VIEW public.v_buildings_3d;
REFRESH MATERIALIZED VIEW public.zona_buildings;
REFRESH MATERIALIZED VIEW public.zona_roads;
REFRESH MATERIALIZED VIEW public.zona_analytics;"
```

---

### Solucion de problemas frecuentes

**Las geometrias no se ven en QGIS / aparecen en el lugar incorrecto**

Esto ocurre si el esquema 3DCityDB fue instalado con un SRID incorrecto. Para corregirlo:

```sql
-- Paso 1: corregir restricciones de tipo (ejecutar uno por uno)
SELECT UpdateGeometrySRID('citydb', 'feature', 'envelope', 32118);
SELECT UpdateGeometrySRID('citydb', 'geometry_data', 'geometry', 32118);
SELECT UpdateGeometrySRID('citydb', 'address', 'multi_point', 32118);

-- Paso 2: corregir el SRID embebido en cada geometria
BEGIN;
UPDATE citydb.database_srs
    SET srid = 32118, srs_name = 'urn:ogc:def:crs:EPSG::32118';
UPDATE citydb.feature
    SET envelope = ST_SetSRID(envelope, 32118) WHERE envelope IS NOT NULL;
UPDATE citydb.geometry_data
    SET geometry = ST_SetSRID(geometry, 32118) WHERE geometry IS NOT NULL;
UPDATE citydb.address
    SET multi_point = ST_SetSRID(multi_point, 32118) WHERE multi_point IS NOT NULL;
COMMIT;
```

> Si aparece el error `cannot alter type of a column used by a view`, primero
> ejecutar `DROP MATERIALIZED VIEW IF EXISTS public.zona_analytics CASCADE`
> y luego `DROP MATERIALIZED VIEW IF EXISTS public.zona_buildings CASCADE`,
> ejecutar los UPDATE y recrear las vistas desde el Paso 5.

---

## PARTE 2 - Visualizacion en QGIS

---

## Como cargar las capas en QGIS

1. Capa -> Anadir capa -> Anadir capa PostGIS
2. Nueva conexion:
   - Host: `localhost` | Puerto: `5432`
   - Base de datos: `laboratorio`
   - Usuario: `postgres` | Contrasena: `postgres`
3. Esquema: **public** -> seleccionar la capa deseada -> Anadir

**Capas disponibles:**

| Capa | Filas | Descripcion |
|---|---|---|
| `zona_analytics` | 1597 | Capa principal — metricas + datos MapPLUTO de zonificacion |
| `zona_buildings` | 1597 | Geometria real de edificios (GroundSurface) |
| `zona_roads` | 871 | Calles, plazas y tracks recortados al bbox |
| `v_buildings_3d` | 100000 | Todos los edificios importados (sin filtro de zona) |
| `mappluto` | 856614 | Lotes NYC con datos de zonificacion FAR y uso de suelo |

### Vista 3D

En Propiedades de la capa `zona_analytics` -> **Vista 3D**:
- Dropdown superior: seleccionar **Simbolo unico**
- **Extrusion** -> boton epsilon (ε) -> escribir `"height"`
- Fijacion de la altura: `Absoluto`
- Aplicar

Para ver en 3D: menu **Ver -> Vistas de mapa -> Nueva vista 3D del mapa**

Controles en la ventana 3D:
- Rueda del mouse: zoom
- Ctrl + click izquierdo + arrastrar: rotar/inclinar
- Click derecho + arrastrar: pan

---

## Metricas disponibles en zona_analytics

---

### 1. Altura del edificio (`height`)

**Que mide:** La altura real del edificio en metros, calculada como la diferencia entre el punto mas alto y el punto mas bajo del edificio segun el modelo CityGML (z_max - z_min del envelope).

**Como se calculo:**
```sql
ST_ZMax(Box3D(envelope)) - ST_ZMin(Box3D(envelope))
```

**Valores en la zona:**
- Minimo: ~1.7 m (1 piso)
- Maximo: ~27 m (8+ pisos)
- Promedio: ~7.5 m (~3 pisos)

**Como visualizarlo en QGIS — Simbologia 2D:**
1. Clic derecho en `zona_analytics` -> Propiedades -> Simbologia
2. Tipo: **Graduado**
3. Campo: `height`
4. Rampa de color: **YlOrRd**
5. Modo: **Jenks**, 5 clases
6. Clic **Clasificar** -> Aceptar

Rangos resultantes y colores exactos (rampa YlOrRd):

| Clase | Rango (m) | Color | Hex |
|---|---|---|---|
| 1 | 1.66 - 5.46 | Amarillo | `#ffffb2` |
| 2 | 5.46 - 8.00 | Amarillo naranja | `#fecc5c` |
| 3 | 8.00 - 10.45 | Naranja | `#fd8d3c` |
| 4 | 10.45 - 16.36 | Rojo | `#f03b20` |
| 5 | 16.36 - 26.95 | Bordo | `#bd0026` |

**Como visualizarlo en QGIS — Vista 3D:**

La Vista 3D no hereda automaticamente la simbologia 2D. Hay que configurarla por separado:

1. Propiedades -> **Vista 3D** -> dropdown -> **Basado en reglas**
2. Agregar 5 reglas con el boton **+**, una por cada rango:

| Descripcion | Filtro | Extrusion | Color difuso |
|---|---|---|---|
| 1.7 - 5.5m | `"height" >= 1.66 AND "height" <= 5.46` | `"height"` | `#ffffb2` |
| 5.5 - 8m | `"height" > 5.46 AND "height" <= 8.0` | `"height"` | `#fecc5c` |
| 8 - 10.4m | `"height" > 8.0 AND "height" <= 10.45` | `"height"` | `#fd8d3c` |
| 10.4 - 16.4m | `"height" > 10.45 AND "height" <= 16.36` | `"height"` | `#f03b20` |
| 16.4 - 26.9m | `"height" > 16.36 AND "height" <= 26.95` | `"height"` | `#bd0026` |

En cada regla: campo **Extrusion** -> boton epsilon (ε) -> escribir `"height"` -> Aceptar.
Fijacion de la altura: `Absoluto`.

**En 3D:** Los edificios se extruyen y colorean por altura real en metros.

---

### 2. Area de planta (`area_planta`)

**Que mide:** El area de la huella del edificio en metros cuadrados.

**Como se calculo:**
```sql
ST_Area(ST_Force2D(ground_surface_geometry))
```

**Valores en la zona:**
- Edificios chicos: ~20-50 m2
- Edificios grandes: 500-2000 m2
- Promedio: ~100 m2

**Como visualizarlo en QGIS:**
1. Simbologia -> Tipo: **Graduado**
2. Campo: `area_planta`
3. Rampa de color: Greens
4. Modo: Quantil, 5 clases
5. Clasificar -> Aceptar

---

### 3. Volumen estimado (`volumen`)

**Que mide:** Volumen aproximado del edificio en metros cubicos (area_planta x height).

**Valores en la zona:**
- 1-2 pisos: promedio 228 m3
- 3-4 pisos: promedio 884 m3
- 5-7 pisos: promedio 3.224 m3
- Alto +8 pisos: promedio 36.269 m3

**Como visualizarlo en QGIS:**
1. Simbologia -> Tipo: **Graduado**
2. Campo: `volumen`
3. Rampa de color: PuRd o Reds
4. Modo: Jenks, 5 clases
5. Clasificar -> Aceptar

---

### 4. Relacion altura/area (`ratio_altura_area`)

**Que mide:** Cociente entre altura y area de planta. Alto = torre angosta. Bajo = deposito o comercio.

**Valores tipicos:**
- Torre angosta: > 0.2
- Edificio tipico: 0.05 - 0.15
- Deposito/comercio: < 0.03

**Como visualizarlo en QGIS:**
1. Simbologia -> Tipo: **Graduado**
2. Campo: `ratio_altura_area`
3. Rampa de color: RdYlGn invertida
4. Modo: Quantil, 5 clases
5. Clasificar -> Aceptar

---

### 5. Categoria de altura (`categoria_altura`)

**Distribucion en la zona:**
- 1-2 pisos: 716 edificios (27%)
- 3-4 pisos: 1746 edificios (67%)
- 5-7 pisos: 159 edificios (6%)
- Alto +8 pisos: 4 edificios (<1%)

**Como visualizarlo en QGIS:**
1. Simbologia -> Tipo: **Categorizado**
2. Campo: `categoria_altura`
3. Clic Clasificar
4. Colores sugeridos:
   - 1-2 pisos -> amarillo claro
   - 3-4 pisos -> naranja
   - 5-7 pisos -> rojo
   - Alto +8 pisos -> rojo oscuro
5. Aceptar

---

### 6. Orientacion de fachada (`orientacion_fachada`)

**Como visualizarlo en QGIS:**
1. Simbologia -> Tipo: **Categorizado**
2. Campo: `orientacion_fachada`
3. Clasificar
4. Colores sugeridos:
   - Norte -> azul
   - Sur -> rojo
   - Este -> amarillo
   - Oeste -> verde
5. Aceptar

---

### 7. Exposicion solar estimada (`exposicion_solar`)

**Como visualizarlo en QGIS:**
1. Simbologia -> Tipo: **Categorizado**
2. Campo: `exposicion_solar`
3. Clasificar
4. Colores sugeridos:
   - Alta -> amarillo / naranja brillante
   - Media -> amarillo palido
   - Baja -> azul claro
5. Aceptar

**Limitacion:** Estimacion basada solo en orientacion cardinal. No considera sombras de edificios vecinos ni angulo solar real.

---

### 8. Edificios proximos a menos de 20m (`edificios_proximos_20m`)

**Como visualizarlo en QGIS:**
1. Simbologia -> Tipo: **Graduado**
2. Campo: `edificios_proximos_20m`
3. Rampa de color: YlOrRd
4. Modo: Quantil, 5 clases
5. Clasificar -> Aceptar

---

### 9. Densidad del entorno (`densidad_entorno`)

**Como visualizarlo en QGIS:**
1. Simbologia -> Tipo: **Categorizado**
2. Campo: `densidad_entorno`
3. Clasificar
4. Colores sugeridos:
   - Muy densa -> rojo oscuro
   - Densa -> naranja
   - Aislada -> verde claro
5. Aceptar

---

## Combinaciones recomendadas para analisis

| Objetivo | Capa | Campo |
|---|---|---|
| Mapa de alturas 3D | zona_analytics (3D) | height (extrusion) |
| Densidad constructiva | zona_analytics | volumen (graduado) |
| Tipologia edilicia | zona_analytics | ratio_altura_area (graduado) |
| Orientacion solar | zona_analytics | exposicion_solar (categorizado) |
| Patrones de densidad urbana | zona_analytics | densidad_entorno (categorizado) |
| Comparacion de manzanas | zona_analytics + zona_roads | categoria_altura sobre roads |

---

## Nota sobre limitaciones

- El analisis de **sombras reales** requiere calculo solar con angulo, hora y fecha especifica.
- La **exposicion solar** calculada es una aproximacion por orientacion cardinal, no considera edificios vecinos que generen sombra.
- El **volumen** es una estimacion simplificada (huella x altura), no considera formas irregulares de techo.
- Los datos corresponden a una muestra de **1597 edificios** en una zona de ~2.25km2 del dataset NYC LoD2 (Queens/Brooklyn).

---

## PARTE 3 - MapPLUTO y Simulaciones de Zonificacion

---

### Que es MapPLUTO y por que lo usamos

MapPLUTO es el dataset oficial de la NYC Department of City Planning.
Contiene **856.614 lotes de impuesto** de los 5 boroughs de NYC con informacion catastral:

| Campo | Descripcion |
|---|---|
| `bbl` | Clave unica del lote (borough + block + lot) |
| `zonedist1` | Distrito de zonificacion principal (R4, R6B, M1-1, etc.) |
| `residfar` | FAR (Floor Area Ratio) maximo permitido para uso residencial |
| `builtfar` | FAR ya construido en el lote |
| `numfloors` | Numero de pisos segun catastro |
| `yearbuilt` | Anio de construccion del edificio |
| `landuse` | Codigo de uso de suelo (01=1fam, 02=2fam, 05=comercial, etc.) |
| `ownername` | Nombre del propietario registrado |
| `address` | Direccion postal |
| `ltdheight` | Distrito de altura limitada (si aplica) |

**FAR (Floor Area Ratio):** Relacion entre area total construida y area del lote.
Por ejemplo FAR=2 significa que se puede construir el doble del area del lote.
Si el lote mide 500m2 y FAR=2, el maximo de area construida es 1000m2.

### Descargar MapPLUTO

El archivo esta en el repositorio NYCPlanning en DigitalOcean:

```bash
cd datos-nyc
wget -O mappluto_26v1_shp.zip \
  "https://edm-publishing.nyc3.digitaloceanspaces.com/db-pluto/publish/26v1/mappluto/mappluto.shp.zip"
mkdir mappluto_26v1
unzip mappluto_26v1_shp.zip -d mappluto_26v1/
```

> Tamano: ~137 MB comprimido. La version 26v1 es de abril 2026.
> Para versiones anteriores reemplazar `26v1` por `25v4`, `24v3`, etc.

### Cargar MapPLUTO en PostgreSQL

La proyeccion del shapefile es **EPSG:2263** (NY State Plane en pies).
Se debe reprojectar a **EPSG:32118** (metros) para que coincida con 3DCityDB.

```bash
# Requiere ogr2ogr (viene con GDAL, disponible en la mayoria de distribuciones Linux)
# sudo apt install gdal-bin

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
```

Crear indices para performance:
```sql
CREATE INDEX IF NOT EXISTS mappluto_geom_idx ON public.mappluto USING GIST (geom);
CREATE INDEX IF NOT EXISTS mappluto_bbl_idx ON public.mappluto (bbl);
CREATE INDEX IF NOT EXISTS mappluto_zonedist1_idx ON public.mappluto (zonedist1);
ANALYZE public.mappluto;
```

Verificar:
```sql
SELECT COUNT(*) AS total_lotes, COUNT(DISTINCT borocode) AS boroughs
FROM public.mappluto;
-- Resultado esperado: 856614 lotes, 5 boroughs
```

### Zona de analisis con distritos de zonificacion

La zona bbox elegida (308000-309500, 60500-62000 EPSG:32118) incluye:

```sql
SELECT p.zonedist1 AS distrito, COUNT(*) AS lotes
FROM public.mappluto p
WHERE p.geom && ST_MakeEnvelope(308000, 60500, 309500, 62000, 32118)
GROUP BY p.zonedist1 ORDER BY lotes DESC;
```

| Distrito | Lotes | Descripcion | Altura max |
|---|---|---|---|
| R4-1 | ~2108 | Residencial bajo (casas 1-2 fam) | 9.14 m (30 ft) |
| R4 | ~966 | Residencial bajo | 9.14 m |
| R4B | ~593 | Rowhouse (casas adosadas) | 8.53 m (28 ft) |
| R5B | ~274 | Residencial medio | 10.06 m (33 ft) |
| M1-1 | ~54 | Industrial liviano / manufactura | sin limite residencial |
| R4A | ~45 | Residencial bajo (1 familia) | 9.14 m |
| R6B | ~39 | Residencial de mayor densidad | 15.24 m (50 ft) |
| PARK | ~4 | Espacio verde / parque | — |

### Queries de simulacion disponibles

El archivo `queries_simulacion.sql` contiene 9 queries analiticas. Ejecutarlas desde
DBeaver, pgAdmin o psql conectado a la base `laboratorio`.

---

**Q1 - Resumen por distrito:**
Cuantos edificios hay por zona, cual es la altura promedio y cuantos tienen FAR excedido.

```sql
SELECT zonedist1, COUNT(*) AS edificios,
       ROUND(AVG(height)::numeric, 2) AS altura_prom_m,
       SUM(CASE WHEN far_construido > far_permitido AND far_permitido > 0 THEN 1 ELSE 0 END) AS far_violaciones
FROM public.zona_analytics WHERE zonedist1 IS NOT NULL
GROUP BY zonedist1 ORDER BY edificios DESC;
```

---

**Q2 - Edificios con FAR excedido:**
Lista de edificios donde lo construido supera lo que el codigo de zonificacion permite.
Esto puede indicar construcciones ilegales, cambio de uso de suelo, o excepciones históricas.

---

**Q3 - Violaciones de altura maxima:**
Por ejemplo en R4-1 el maximo es 9.14m (30 pies). Edificios que superan ese limite
aparecen como potenciales infractores o excepciones legales.

---

**Q4 - Simulacion estricta de altura:**
¿Que pasaria si se aplicara el limite de altura exactamente?
Calcula cuantos metros en promedio se tendria que demoler por zona, y como cambiaria
la masa construida y la exposicion solar del entorno.

---

**Q5 - Potencial de densificacion:**
Lotes con FAR disponible (builtFAR << residFAR) = donde legalmente podria construirse mas.
Calcula los m2 adicionales posibles por edificio.

---

**Q6 a Q9** - Distribucion de usos de suelo, candidatos solares, edificios historicos,
impacto de nueva construccion sobre exposicion solar vecinos.

---

## PARTE 4 - Prototipo Web: GeoServer + CesiumJS

---

### Arquitectura del sistema

```
PostgreSQL/PostGIS (puerto 5432)
    |
    |-- zona_analytics (1597 edificios con metricas)
    |-- zona_roads (871 features de calles)
    |-- mappluto (856614 lotes NYC)
    
    ↓ (conexion JDBC)
    
GeoServer 2.25 (puerto 8080)
    |-- workspace: tsig
    |-- datastore: laboratorio (PostGIS)
    |-- capas publicadas: zona_analytics, zona_roads, zona_buildings, v_buildings_3d
    |-- protocolo: WFS (Web Feature Service) → GeoJSON
    
    ↓ (peticion HTTP fetch)
    
CesiumJS 1.122 (puerto 8081 via nginx)
    |-- carga GeoJSON desde GeoServer WFS
    |-- renderiza poligonos extruidos en 3D
    |-- mapa base: OpenStreetMap tiles
    |-- 4 modos de visualizacion:
         - Por zona de zonificacion (colores por R4, R6B, M1-1, etc.)
         - Violaciones FAR (rojo = excede limite)
         - Violaciones altura (rojo = supera maximo zonal)
         - Exposicion solar (amarillo/naranja/gris)
```

### Levantar el entorno completo

El archivo `docker-compose.yml` levanta los 3 servicios de una vez:

```bash
cd ~/Escritorio/TSIG
docker compose up -d
```

Esperar ~2 minutos hasta que GeoServer este listo (la primera vez descarga ~800MB de imagenes).
Verificar estado:
```bash
docker ps
# Deben aparecer: tsig-citydb-1, tsig-geoserver-1, tsig-cesium-viewer-1
```

### Configurar GeoServer (primera vez o si se borra el volumen)

```bash
bash geoserver-setup.sh
```

Este script hace automaticamente:
1. Crea el workspace `tsig` en GeoServer
2. Crea el datastore PostGIS apuntando al contenedor `citydb`
3. Publica las capas `zona_analytics`, `zona_roads`, `zona_buildings`, `v_buildings_3d`

> **Nota:** La configuracion de GeoServer se guarda en el volumen Docker `geoserver_data`.
> Si se reinicia el contenedor, la configuracion se mantiene. Solo re-ejecutar el script
> si se hace `docker volume rm tsig_geoserver_data`.

### Accesos

| Servicio | URL |
|---|---|
| Visor Cesium 3D | http://localhost:8081 |
| GeoServer admin | http://localhost:8080/geoserver/web (admin / geoserver) |
| WFS zona_analytics | http://localhost:8080/geoserver/tsig/ows?service=WFS&version=2.0.0&request=GetFeature&typeName=tsig:zona_analytics&outputFormat=application/json&srsName=EPSG:4326 |

### Como funciona el visor Cesium (web/index.html)

El visor sigue este flujo al cargar:

1. **Inicializa CesiumJS** con mapa base OSM (sin token Cesium Ion)
2. **Hace fetch** al endpoint WFS de GeoServer:
   `GET /geoserver/tsig/ows?...typeName=tsig:zona_analytics...srsName=EPSG:4326`
3. GeoServer **ejecuta un SELECT** sobre la vista materializada `zona_analytics` en PostgreSQL
   y devuelve GeoJSON con coordenadas en EPSG:4326 (WGS84 / longitud-latitud)
4. CesiumJS carga el GeoJSON con `GeoJsonDataSource.load()` que crea una entidad
   por cada edificio con su geometria de poligono
5. Por cada entidad se setea:
   - `extrudedHeight` = altura real del edificio en metros (columna `height` del SQL)
   - `material` = color segun el modo activo (zonedist1, FAR, altura, solar)
6. El resultado son **poligonos extruidos** (cajas 3D) en la posicion geografica real

El usuario puede cambiar el modo de visualizacion (botones del panel) y el visor
recorre todos los edificios recalculando el color sin volver a pedir datos al servidor.
Al hacer click en un edificio aparece el panel con todos sus atributos.

### Por que se ven cajas y no geometria LoD2 real

Esta es una pregunta importante para entender la diferencia entre los datos y su visualizacion.

**Los datos SI son LoD2:** El archivo `NYC_Buildings_LoD2_CityGML.gml` contiene cada
edificio con superficies separadas: paredes, techo, base (GroundSurface, WallSurface,
RoofSurface). Un edificio puede tener 20-50 poligonos 3D describiendo su forma exacta
(incluyendo techos inclinados, terrazas, escalones).

**Lo que mostramos son cajas (extrusion de footprint):** Para el prototipo web, la vista
materializada `zona_buildings` toma solo la **GroundSurface** (el poligono de la base del
edificio) y lo extruye verticalmente por la altura calculada del envelope. Esto produce
una caja rectangular simple.

**Por que no mostramos la geometria LoD2 completa en el web:**

| Aspecto | Extrusion footprint | LoD2 real en web |
|---|---|---|
| Complejidad de datos | 1 poligono por edificio | 20-50 poligonos por edificio |
| Total de poligonos (1597 edif.) | ~1600 poligonos | ~30.000-80.000 poligonos |
| Formato | GeoJSON (simple) | 3D Tiles o glTF (complejo) |
| Rendimiento en browser | Excelente | Requiere optimizacion |
| Implementacion | Vista SQL simple | citydb-tool export + pipeline 3D Tiles |
| Visual | Cajas coloreadas | Techos reales, formas exactas |

**Para tener LoD2 real en Cesium** habria que:
1. Exportar los datos con `citydb-tool export 3dtiles` a formato CityJSON/3D Tiles
2. Servir los tiles con nginx o un servidor de tiles 3D
3. Cargarlos en Cesium con `Cesium3DTileset`

Esto es factible pero esta fuera del alcance del prototipo actual.

**Conclusion:** Lo que el visor muestra es la **huella del edificio con altura real**.
Los datos de altura son correctos (vienen del LoD2), solo que la forma es simplificada.
Para el analisis de zonificacion y FAR esto es perfectamente valido.

### Por que existe el offset entre cajas y calles del mapa OSM

Los datos de edificios vienen del dataset **NYC LoD2 de TU Munich** (2015, datos catastrales).
El mapa de fondo es **OpenStreetMap** (datos voluntarios, actualizado continuamente).

Son dos fuentes independientes con levantamientos distintos. Un pequeno offset de 1-5 metros
es normal y esperado. No es un error del sistema de coordenadas ni del codigo.

---

## PARTE 5 - Comandos de mantenimiento

---

### Levantar todo de cero (en otra PC)

```bash
# 1. Instalar Docker y Docker Compose
# Ver: https://docs.docker.com/engine/install/

# 2. Clonar/copiar la carpeta del proyecto
cd ~/Escritorio/TSIG

# 3. Levantar base de datos
docker compose up -d

# 4. Esperar ~30s y verificar
docker ps  # citydb debe decir (healthy)

# 5. Descargar datos (ver PARTE 1 - Paso 2)
# Minimo para la zona de analisis: edificios + calles
# Los datos ya descargados estan en datos-nyc/

# 6. Importar datos (ver PARTE 1 - Paso 4)
# Si los datos ya estan en el volumen Docker, saltear este paso

# 7. Crear/refrescar vistas SQL
docker exec -i tsig-citydb-1 psql -U postgres -d laboratorio < vistas_sql.sql

# 8. Cargar MapPLUTO (si no esta cargado)
ogr2ogr -f "PostgreSQL" "PG:host=localhost port=5432 dbname=laboratorio user=postgres password=postgres" \
  datos-nyc/mappluto_26v1/mappluto.shp -nln public.mappluto -nlt MULTIPOLYGON \
  -t_srs EPSG:32118 -s_srs EPSG:2263 -lco GEOMETRY_NAME=geom -overwrite

# 9. Levantar GeoServer + Cesium viewer
docker compose up -d  # ya incluidos en docker-compose.yml

# 10. Configurar GeoServer (solo primera vez)
bash geoserver-setup.sh

# 11. Abrir el visor
# http://localhost:8081
```

### Refrescar vistas SQL (si se reimportan datos)

```bash
docker exec tsig-citydb-1 psql -U postgres -d laboratorio -c "
REFRESH MATERIALIZED VIEW public.v_buildings_3d;
REFRESH MATERIALIZED VIEW public.zona_buildings;
REFRESH MATERIALIZED VIEW public.zona_roads;
REFRESH MATERIALIZED VIEW public.zona_analytics;"
```

### Verificar estado de la base de datos

```sql
-- Contar features por tipo
SELECT oc.classname, COUNT(*) AS total
FROM citydb.feature f
JOIN citydb.objectclass oc ON f.objectclass_id = oc.id
GROUP BY oc.classname ORDER BY total DESC;

-- Verificar vistas materializadas
SELECT schemaname, matviewname,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||matviewname)) AS tamano
FROM pg_matviews WHERE schemaname = 'public';
```

### Cambiar la zona de analisis (bbox)

Si se quiere analizar una zona diferente, editar `vistas_sql.sql` y cambiar las 4 ocurrencias de:
```
ST_MakeEnvelope(308000, 60500, 309500, 62000, 32118)
```
Por las coordenadas deseadas en EPSG:32118, luego refrescar las vistas.

Para encontrar las coordenadas de una zona: en QGIS, usar el plugin `Coordinates Capture`

---

## PARTE N — Visor 3D LoD2 real (3D Tiles)

### Por qué los edificios se ven como cajas (LoD1 vs LoD2)

| Modo | Como funciona | Limitacion |
|---|---|---|
| **LoD1 (actual)** | Footprint 2D + `extrudedHeight` en Cesium | Todos los techos son planos aunque el dato real sea inclinado |
| **LoD2 (real)** | Geometria 3D completa: paredes, techos, bases | Requiere pipeline de conversion a 3D Tiles |

El dataset NYC TU Munich **SI tiene LoD2**: 723,716 registros `lod2MultiSurface` en la BD (WallSurface, RoofSurface, GroundSurface por edificio).

### Arquitectura del pipeline LoD2

```
3DCityDB (citydb.geometry_data)
    ↓ view: v_lod2_buildings_3dtiles
PostGIS MultiPolygonZ por edificio
    ↓ pg2b3dm (Docker: geodan/pg2b3dm)
3D Tiles 1.1 (implicit tiling, GLB)
    ↓ nginx /tiles/lod2/
CesiumJS Cesium3DTileset
```

### Vista SQL que usa el pipeline

```sql
-- Creada en public (persiste en volumen citydb_data)
CREATE OR REPLACE VIEW public.v_lod2_buildings_3dtiles AS
SELECT 
  f_bldg.id,
  f_bldg.objectid,
  ST_Multi(ST_Collect(poly.geom)) AS geom
FROM citydb.feature f_bldg
JOIN citydb.property p_b ON p_b.feature_id = f_bldg.id AND p_b.name = 'boundary'
JOIN citydb.feature f_surf ON f_surf.id = p_b.val_feature_id
JOIN citydb.property p_g ON p_g.feature_id = f_surf.id AND p_g.name = 'lod2MultiSurface'
JOIN citydb.geometry_data gd ON gd.id = p_g.val_geometry_id
CROSS JOIN LATERAL ST_Dump(gd.geometry) AS poly
WHERE f_bldg.objectclass_id = 901  -- Building
GROUP BY f_bldg.id, f_bldg.objectid;
-- Retorna: 50,000 edificios con MultiPolygonZ SRID 32118
```

> **Nota esquema 3DCityDB v5:** Building (objectclass 901) → `boundary` property → 
> WallSurface/RoofSurface/GroundSurface → `lod2MultiSurface` property → geometry_data.
> No hay columna `lod` directa en `feature`; las geometrias LoD viven en `property`.

### Generar o regenerar los tiles (desde cero o si cambian los datos)

```bash
# Desde la carpeta del proyecto (con docker compose levantado):
docker compose run --rm pg2b3dm-converter

# O manualmente:
mkdir -p web/tiles/lod2 && chmod 777 web/tiles/lod2
docker run --rm \
  --network tsig_default \
  -v $(pwd)/web/tiles/lod2:/output \
  geodan/pg2b3dm \
  --connection "Host=citydb;Port=5432;Database=laboratorio;Username=postgres;Password=postgres;CommandTimeout=300" \
  -t public.v_lod2_buildings_3dtiles \
  -c geom \
  -o /output \
  --max_features_per_tile 500 \
  -g 200
```

Tiempo estimado: ~5-10 min para 50,000 edificios.
Resultado: `web/tiles/lod2/tileset.json` + `content/*.glb` + `subtrees/`

### Setup herramientas de conversion (primera vez en maquina nueva)

```bash
# Venv Python con cjio + py3dtiles (para exportar/inspeccionar CityJSON)
python3 -m venv converter/.venv
converter/.venv/bin/pip install py3dtiles cjio triangle

# pg2b3dm ya esta como servicio Docker en docker-compose.yml (profile: tools)
# No requiere instalacion local
```

### Como usar el visor

- **LoD1 Analytics** (default): footprint extruido, coloreado por zona/FAR/altura/solar, click para datos del edificio
- **LoD2 Real 3D**: boton "LoD2 Real 3D" — carga `Cesium3DTileset` desde `/tiles/lod2/`, muestra geometria 3D real con techos y paredes
- Los tiles se pre-cargan en background al abrir el visor

### Limitaciones del LoD2 actual

- Los tiles NO tienen atributos de zona/FAR embedded — coloreo por zona no disponible en modo LoD2
  (para agregar: usar `-a "atributo1,atributo2"` en pg2b3dm + `Cesium3DTileStyle` en JS)
- `web/tiles/lod2/` no esta en control de versiones (archivos binarios grandes)
- Si se regeneran los datos, volver a correr `pg2b3dm-converter`
o leer las coordenadas del cursor en la barra inferior (asegurarse que el proyecto este en EPSG:32118).
