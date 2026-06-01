# Dataset y Base de Datos — NYC 3DCityDB
## Proyecto TSIG 2026 — Bases de Datos para Ciudades 3D

---

## Fuente de datos

**NYC 3D City Model** — Technical University of Munich (TU Munich)
- URL: https://www.asg.ed.tum.de/gis/projekte/new-york-city-3d/
- Formato fuente: CityGML 2.0
- Almacenado en: 3DCityDB 5.1.3 (esquema CityGML 3 internamente)
- SRID: **32118** (NAD83 / New York Long Island)

---

## Archivos disponibles para descargar

### LoD2 — Edificios

| Archivo | Tamaño | Estado | URL base |
|---|---|---|---|
| NYC_Buildings_LoD2_CityGML.zip | 2.4 GB | ✅ descargado | `.../NYC_buildings_CityGML_LoD2/` |

### LoD2 — Espacio vial

Base URL: `http://www.3dcitydb.net/3dcitydb/fileadmin/public/datasets/NYC/NYC_street_space_CityGML_LoD2/`

| Archivo | Tamaño | Estado | Descripcion |
|---|---|---|---|
| NYC_CityGML_LoD2_Roadbed.zip | 132 MB | ✅ descargado | Calzada principal |
| NYC_CityGML_LoD2_Intersection.zip | 8 MB | ✅ descargado | Intersecciones |
| NYC_CityGML_LoD2_Entrance.zip | 5.6 MB | ✅ descargado | Entradas/accesos |
| NYC_CityGML_LoD2_Median_Grass.zip | 0.3 MB | ✅ descargado | Medianas verdes |
| NYC_CityGML_LoD2_Median_Painted.zip | 4 MB | ✅ descargado | Marcas viales |
| NYC_CityGML_LoD2_Median_Raised.zip | 75 MB | ✅ descargado | Medianas elevadas |
| NYC_CityGML_LoD2_Parking_Lot.zip | 33 MB | ✅ descargado | Estacionamientos |
| NYC_CityGML_LoD2_Plaza.zip | 5.6 MB | ✅ descargado | Plazas |
| NYC_CityGML_LoD2_Track.zip | 16 MB | ✅ descargado | Pistas/vías |
| NYC_CityGML_LoD2_Sidewalk.zip | 1.3 GB | ❌ no descargado | Veredas (10 archivos) |
| NYC_CityGML_LoD2_Curb.zip | 2 GB | ❌ no descargado | Cordones (10 archivos) |

### LoD1 — Dataset 2015 (atributos tematicos ricos)

Base URL: `http://www.3dcitydb.net/3dcitydb/fileadmin/mydata/Cesium_NYC_Demo/CityGML/`

| Archivo | Tamaño | Estado | Descripcion |
|---|---|---|---|
| NYC_Buildings_CityGML_20150907.zip | ~300 MB | ✅ descargado | 1,082,015 edificios, hasta 55 atributos por objeto |
| NYC_Streets_CityGML_20150907.zip | 50 MB | ✅ descargado | 149,292 calles, hasta 24 atributos por objeto |
| NYC_Lots_CityGML_20150907.zip | 400 MB | ✅ descargado | 866,853 parcelas, hasta 92 atributos por objeto |

> Los LoD1 tienen geometria de caja simple (sin detalle de techo/pared) pero atributos tematicos muy ricos.
> Clase CityGML: Buildings = bldg:Building, Streets = tran:Road/tran:Track, Lots = luse:LandUse

#### Atributos LoD1 Lots (luse:LandUse) — uso de suelo y zoning

Clave para simulacion de reglas de construccion NYC.

| Atributo | Tipo | Descripcion |
|---|---|---|
| zoning_district_1/2/3/4 | string | Distrito de zoning (R6, M1-1, C4-4, etc.) |
| all_zoning_1/2 | string | Zoning completo incluyendo overlays |
| commercial_overlay1/2 | string | Overlay comercial |
| land_use_category | string | Categoria de uso (1=residencial, 4=mixto, etc.) |
| building_class | string | Clase del edificio segun NYC DOF |
| number_of_buildings | int | Edificios en la parcela |
| number_of_floors | int | Pisos |
| year_built | int | Año de construccion |
| year_altered_1/2 | int | Años de modificacion |
| lot_area | double | Area de parcela (m²) |
| building_area | double | Area construida (m²) |
| built_floor_area_ratio | double | FAR real construido |
| residential_area | double | Area residencial (m²) |
| commercial_area | double | Area comercial (m²) |
| office_area | double | Area de oficinas (m²) |
| lot_frontage / lot_depth | double | Frente y fondo de parcela |
| building_frontage / building_depth | double | Frente y fondo del edificio |
| owner_name / owner_type | string | Propietario |
| borough_name | string | Borough (Manhattan, Brooklyn, etc.) |
| block_number / lot_number | int | Identificacion catastral |
| zipcode | int | Codigo postal |
| community_district | int | Distrito comunitario |
| limited_height_district | string | Distrito de altura limitada |
| historic_district_name | string | Distrito historico |
| landmark_name | string | Nombre si es landmark |
| sperical_purpose_district_1/2 | string | Distritos de proposito especial |
| assessed_value_land / total | double | Valor catastral |
| waterfront | string | Indicador frente al agua |
| park_area / park_number | double/string | Datos de parque si aplica |

#### Atributos LoD1 Buildings (bldg:Building) — edificios con datos PLUTO

| Atributo | Tipo | Descripcion |
|---|---|---|
| building_identification_nuber | string | BIN — ID unico de edificio NYC |
| doitt_id | int | ID del Dept. of Information Technology |
| OBJECTID | int | ID del dataset |
| borough_block_lot_number | string | BBL — identificacion catastral |
| ground_elevation | double | Elevacion del suelo en pies |
| building_base_area | double | Area de la base del edificio |
| building_volume | double | Volumen del edificio |
| geom_source | string | Fuente de la geometria |
| status | string | Estado del edificio |
| building_under_construction | string | En construccion (S/N) |
| last_modify_date | string | Fecha ultima modificacion |
| citygml_function | string | Funcion CityGML (residencial, comercial, etc.) |
| citygml_usage | string | Uso CityGML |
| PLUTO_building_class | string | Clase del edificio (A1, B2, D4, etc.) |
| PLUTO_land_use_category | string | Categoria de uso de suelo |
| PLUTO_number_of_floors | int | Numero de pisos |
| PLUTO_year_built | int | Año de construccion |
| PLUTO_year_altered_1/2 | int | Años de modificacion |
| PLUTO_built_floor_area_ratio | double | FAR construido real |
| PLUTO_residential_area | double | Area residencial (m²) |
| PLUTO_commercial_area | double | Area comercial (m²) |
| PLUTO_office_area | double | Area de oficinas (m²) |
| PLUTO_retail_area | double | Area retail (m²) |
| PLUTO_building_frontage / depth | double | Frente y fondo del edificio |
| PLUTO_lot_address | string | Direccion de la parcela |
| PLUTO_units_residential | int | Unidades residenciales |
| PLUTO_condominium_number | int | Numero de condominio |

#### Atributos LoD1 Streets (tran:Road / tran:Track)

| Atributo | Tipo | Descripcion |
|---|---|---|
| segment_id / physical_id | int | Identificadores del segmento vial |
| street_code | int | Codigo de calle NYC |
| segment_type | string | Tipo de segmento |
| traffic_direction | string | Direccion de trafico |
| non_pedestrian | string | Indicador no peatonal |
| bike_lane | int | Tipo de carril bici |
| snow_priority | string | Prioridad de limpieza de nieve |
| construction_status | int | Estado de construccion |
| street_width_meter | double | Ancho de calle en metros |
| street_length_2D_meter | double | Longitud en metros |
| street_area_2D_sq_m | double | Area en m² |
| level_start/end_segment | string | Nivel inicio/fin (calle, elevada, subterranea) |
| node_id_from / node_id_to | string | Nodos de red vial |
| curve_flag | string | Indicador de curva |
| radius_arc | double | Radio del arco si es curva |

### LoD0 — Red vial

| Archivo | Tamaño | Estado | Descripcion |
|---|---|---|---|
| NYC_lod0Network_CityGML.zip | 646 MB | ❌ no descargado | Red vial como features lineales 3D |

### Muestra — Flatiron District

| Archivo | Tamaño | Estado | Descripcion |
|---|---|---|---|
| NYC_Flatiron_Streetpace_CityGML_LoD2.zip | 48 MB | ✅ descargado | Muestra LoD2 Manhattan central |
| NYC_Flatiron_Streetspace_KML.zip | 141 MB | ❌ no descargado | Version KML para Google Earth Pro |

---

## Tablas en la base de datos

### Schema `citydb` — Esquema 3DCityDB (CityGML 3)

#### `citydb.feature` — Tabla principal de objetos urbanos

Almacena todos los objetos CityGML: edificios, calles, plazas, superficies, etc.

| Columna | Tipo | Descripcion |
|---|---|---|
| id | bigint | PK — identificador unico interno |
| objectclass_id | integer | FK a objectclass — tipo de objeto (Building, Road, etc.) |
| objectid | text | ID original del archivo GML fuente |
| identifier | text | Identificador semantico del objeto |
| envelope | geometry | Bounding box 3D del objeto (usado para calcular height) |
| creation_date | timestamp | Fecha de creacion del registro |
| termination_date | timestamp | Fecha de fin de vigencia (soporte versioning CityGML 3) |
| valid_from / valid_to | timestamp | Periodo de validez temporal |
| lineage | text | Origen/procedencia del dato |

#### `citydb.geometry_data` — Geometrias 3D

Almacena la geometria real de cada objeto (polygonos, solidos, superficies).

| Columna | Tipo | Descripcion |
|---|---|---|
| id | bigint | PK |
| geometry | geometry | Geometria 3D del objeto (MultiPolygon, Solid, etc.) |
| implicit_geometry | geometry | Geometria implicita (instanciada) |
| geometry_properties | jsonb | Metadatos de la geometria |
| feature_id | bigint | FK a feature |

#### `citydb.objectclass` — Tipos de objetos CityGML

Catalogo de clases del modelo CityGML 3.

| Columna | Descripcion |
|---|---|
| id | PK |
| classname | Nombre de la clase (Building, Road, Square, WallSurface, etc.) |
| supertype_of | Jerarquia de herencia |

Clases presentes en la DB:

| classname | count | Dataset origen | Descripcion |
|---|---|---|---|
| WallSurface | 462,184 | LoD2 Buildings | Superficies de pared |
| Road | 274,786 | LoD2 + LoD1 Streets | Calles, medianas, intersecciones |
| Building | 100,000 | LoD2 (50K) + LoD1 (50K) | Edificios |
| LandUse | 100,000 | LoD1 Lots | Parcelas con atributos de zoning |
| RoofSurface | 70,186 | LoD2 Buildings | Superficies de techo |
| GroundSurface | 50,148 | LoD2 Buildings | Superficies de suelo |
| Track | 12,984 | LoD2 + LoD1 Streets | Pistas/vias especiales |
| Square | 2,720 | LoD2 Streets | Plazas y estacionamientos |

#### `citydb.property` — Atributos de los objetos

Almacena todas las propiedades de cada feature (relaciones, valores, referencias).

| Columna | Tipo | Descripcion |
|---|---|---|
| id | bigint | PK |
| feature_id | bigint | FK a feature |
| name | text | Nombre del atributo (ej: "boundary", "lod2Solid") |
| val_int / val_double / val_string | varios | Valor segun tipo |
| val_feature_id | bigint | Referencia a otro feature (relaciones padre-hijo) |
| val_geometry_id | bigint | Referencia a geometry_data |
| val_lod | text | Nivel de detalle asociado |

#### `citydb.appearance` / `citydb.surface_data` — Apariencia visual

Texturas y materiales de los objetos 3D.

#### `citydb.database_srs` — Configuracion del sistema de coordenadas

| srid | srs_name |
|---|---|
| 32118 | urn:ogc:def:crs:EPSG::32118 |

---

### Schema `public` — Vistas analiticas del proyecto

#### `public.zona_analytics` — Capa principal de analisis (1,597 filas)

Zona de ~2.25 km² en Queens/Brooklyn (Middle Village/Glendale).
Bounding box: x 308000-309500, y 60500-62000 (EPSG:32118).
Cada fila = un edificio con metricas calculadas + datos de zonificacion MapPLUTO.

**Columnas de geometria y metricas 3DCityDB:**

| Columna | Tipo | Descripcion |
|---|---|---|
| qgis_id | bigint | ID del feature en citydb |
| geom | MultiPolygonZ,32118 | Geometria 3D del edificio (huella GroundSurface) |
| height | numeric | Altura en metros (z_max - z_min del envelope) |
| z_min | numeric | Altura minima (base del edificio) |
| area_planta | numeric | Area de huella en m² |
| volumen | numeric | Volumen estimado en m³ (area x height) |
| ratio_altura_area | numeric | height / area_planta — mide esbeltez |
| categoria_altura | text | '1-2 pisos' / '3-4 pisos' / '5-7 pisos' / 'Alto +8 pisos' |
| orientacion_fachada | text | 'Norte' / 'Sur' / 'Este' / 'Oeste' |
| exposicion_solar | text | 'Alta' / 'Media' / 'Baja' |
| edificios_proximos_20m | bigint | Cantidad de edificios a menos de 20m |
| densidad_entorno | text | 'Muy densa' / 'Densa' / 'Aislada' |

**Columnas de zonificacion (JOIN con MapPLUTO por interseccion espacial):**

| Columna | Tipo | Descripcion |
|---|---|---|
| zonedist1 | text | Distrito de zonificacion (R4, R4-1, R6B, M1-1, etc.) |
| far_permitido | numeric | FAR maximo segun codigo de zonificacion |
| far_construido | numeric | FAR ya construido en el lote |
| uso_far_pct | numeric | far_construido / far_permitido — % de FAR usado |
| pluto_numfloors | numeric | Pisos segun catastro MapPLUTO |
| pluto_yearbuilt | numeric | Anio de construccion |
| codigo_uso_suelo | text | Codigo landuse (01=1fam, 02=2fam, 05=comercial...) |
| propietario | text | Nombre del propietario registrado |
| direccion_lote | text | Direccion postal del lote |

#### `public.zona_buildings` — Geometria real de edificios (1,597 filas)

Fuente de zona_analytics. Contiene la geometria original desde GroundSurface.

| Columna | Tipo | Descripcion |
|---|---|---|
| qgis_id | bigint | ID del feature |
| geom | MultiPolygonZ,32118 | Geometria real desde GroundSurface |
| height / z_min / z_max | numeric | Alturas |
| area_planta | numeric | Area de huella |
| volumen | numeric | Volumen estimado |
| ratio_altura_area | numeric | Esbeltez |

#### `public.zona_roads` — Calles en la zona (871 filas)

Calles, pistas y plazas recortadas al bounding box del area de analisis.

| Columna | Tipo | Descripcion |
|---|---|---|
| qgis_id | bigint | ID del feature |
| tipo | text | 'Road' / 'Track' / 'Square' |
| geom | MultiPolygonZ,32118 | Geometria 3D de la via |

#### `public.v_buildings_3d` — Todos los edificios importados (100,000 filas)

Sin filtro de zona — cubre todos los edificios importados. Usa envelope 2D.

| Columna | Tipo | Descripcion |
|---|---|---|
| qgis_id | bigint | ID del feature |
| geom | Polygon,32118 | Envelope 2D del edificio |
| height / z_min / z_max | numeric | Alturas desde envelope 3D |

#### `public.mappluto` — Lotes NYC con datos de zonificacion (856,614 filas)

Dataset oficial NYC Department of City Planning (version 26v1, abril 2026).
Contiene todos los lotes de impuesto de los 5 boroughs con datos catastrales.

| Columna | Tipo | Descripcion |
|---|---|---|
| geom | MultiPolygon,32118 | Geometria del lote (reproyectada desde EPSG:2263) |
| bbl | numeric | Borough+Block+Lot — clave unica del lote |
| borocode | numeric | Codigo del borough (1=Manhattan, 2=Bronx, 3=Brooklyn, 4=Queens, 5=SI) |
| block / lot | numeric | Numero de manzana y lote |
| address | text | Direccion postal |
| zonedist1/2/3/4 | text | Distritos de zonificacion (hasta 4 por lote) |
| overlay1/2 | text | Overlays comerciales |
| spdist1 | text | Distrito de proposito especial |
| ltdheight | text | Distrito de altura limitada |
| residfar | numeric | FAR maximo residencial permitido |
| commfar | numeric | FAR maximo comercial |
| facilfar | numeric | FAR maximo para facilidades |
| builtfar | numeric | FAR total construido actualmente |
| lotarea | numeric | Area del lote en pies cuadrados |
| bldgarea | numeric | Area total construida en pies cuadrados |
| numfloors | numeric | Numero de pisos |
| yearbuilt | numeric | Anio de construccion |
| numbldgs | numeric | Numero de edificios en el lote |
| landuse | text | Codigo uso de suelo (01-10) |
| ownername | text | Nombre del propietario |
| assessland / assesstot | numeric | Valor catastral del suelo / total |

---

## Notas sobre los datos

- **Road vs tipo real:** todos los objetos de espacio vial (calzada, mediana, interseccion) se importan como clase `Road` en 3DCityDB — se pierde la distincion del archivo fuente.
- **LoD2 vs visualizacion:** las vistas SQL usan extrusion de huella (= LoD1 visual). La geometria LoD2 real (techos, paredes) esta en `citydb.geometry_data` pero requiere consultas mas complejas o Cesium para visualizarla.
- **Limit 50,000:** los datos se importaron con `--limit 50000`. El dataset completo de edificios tiene ~1M de objetos.
- **Zonas verdes:** no disponibles en el dataset NYC LoD2. Los datos LoD1 de 2015 tienen parcelas con atributos de uso de suelo que podrian incluirlas.

---

## Arquitectura del sistema completo

```
DATOS FUENTE (archivos GML en datos-nyc/)
    |
    | citydb-tool import citygml
    ↓
POSTGRESQL + POSTGIS + 3DCITYDB (Docker, puerto 5432)
    |   DB: laboratorio
    |   Schema citydb: feature, geometry_data, property, objectclass
    |   Schema public: zona_analytics, zona_buildings, zona_roads, v_buildings_3d, mappluto
    |
    |── QGIS (conexion directa PostGIS)
    |       Visualizacion 2D y 3D en escritorio
    |
    | conexion JDBC (dentro de Docker network)
    ↓
GEOSERVER 2.25 (Docker, puerto 8080)
    |   workspace: tsig
    |   datastore: laboratorio → PostGIS
    |   capas WFS: zona_analytics, zona_roads, zona_buildings, v_buildings_3d
    |   protocolo: WFS → responde GeoJSON
    |
    | HTTP fetch (browser hace GET al GeoServer)
    ↓
NGINX (Docker, puerto 8081)
    |   sirve web/index.html (archivo estatico)
    |
    | el browser carga index.html, ejecuta JavaScript
    ↓
CESIUMJS (corre en el browser del usuario)
    |   carga GeoJSON desde GeoServer
    |   renderiza poligonos extruidos por altura
    |   mapa base: OpenStreetMap tiles
    |   4 modos: zona / FAR / altura / solar
    ↓
PANTALLA DEL USUARIO (localhost:8081)
```

**Punto clave:** CesiumJS NO corre en Docker. Es una libreria JavaScript que se descarga
de `cesium.com` y ejecuta en el browser. Docker/nginx solo sirve el HTML. El procesamiento
3D ocurre en la GPU del cliente.

**Diferencia vista 2D vs 3D:** La SQL query es identica en ambos casos.
Solo cambia el angulo de camara en CesiumJS:
- Vista Top: pitch = -90 grados (mirando recto abajo) → edificios parecen rectangulos planos
- Vista 3D: pitch = -30 grados (oblicua) → se ven paredes de los edificios

---

## Referencia rapida de comandos

### Levantar el entorno

```bash
cd ~/Escritorio/TSIG
docker compose up -d
# Esperar ~30s para citydb, ~2min para geoserver primera vez
docker ps  # verificar que los 3 contenedores esten Up
```

### Configurar GeoServer (solo primera vez o si se borra el volumen)

```bash
bash geoserver-setup.sh
```

### Abrir el visor web

```
http://localhost:8081          # Visor Cesium 3D
http://localhost:8080/geoserver/web   # GeoServer admin (admin/geoserver)
```

### Conectar desde DBeaver / pgAdmin

```
Host: localhost    Puerto: 5432
Base: laboratorio  Usuario: postgres   Password: postgres
```

### Conectar desde QGIS

1. Capa → Anadir capa → Anadir capa PostGIS
2. Nueva conexion: host=localhost, puerto=5432, db=laboratorio, user=postgres, pass=postgres
3. Esquema public → seleccionar capa → Anadir

### Verificar datos en la BD

```sql
-- Contar por tipo de objeto
SELECT oc.classname, COUNT(*) FROM citydb.feature f
JOIN citydb.objectclass oc ON f.objectclass_id = oc.id
GROUP BY oc.classname ORDER BY COUNT(*) DESC;

-- Estado de las vistas
SELECT matviewname, pg_size_pretty(pg_total_relation_size('public.'||matviewname))
FROM pg_matviews WHERE schemaname = 'public';

-- Edificios en la zona de analisis
SELECT COUNT(*), ROUND(AVG(height)::numeric,2) AS altura_prom
FROM public.zona_analytics;
```

### Refrescar vistas (si se reimportan datos)

```bash
docker exec tsig-citydb-1 psql -U postgres -d laboratorio -c "
REFRESH MATERIALIZED VIEW public.v_buildings_3d;
REFRESH MATERIALIZED VIEW public.zona_buildings;
REFRESH MATERIALIZED VIEW public.zona_roads;
REFRESH MATERIALIZED VIEW public.zona_analytics;"
```

### Apagar todo

```bash
docker compose down
# Los datos persisten en el volumen citydb_data
# Para borrar datos tambien: docker compose down -v  (CUIDADO: borra todo)
```

### Levantar en una PC nueva (desde cero)

```bash
# 1. Instalar Docker: https://docs.docker.com/engine/install/ubuntu/
# 2. Copiar la carpeta TSIG/ completa (incluyendo datos-nyc/)
cd ~/Escritorio/TSIG
docker compose up -d          # levanta 3 servicios
# esperar que citydb este healthy (~30s)
docker exec -i tsig-citydb-1 psql -U postgres -d laboratorio < vistas_sql.sql  # crear vistas

# Si los datos NO estan en el volumen (PC nueva sin datos previos):
# Importar edificios (tarda 10-20 min con --limit 100000)
docker run --rm --network host -v "$(pwd)/datos-nyc:/data" 3dcitydb/citydb-tool:latest \
  import citygml --limit 100000 -H localhost -d laboratorio -u postgres -p postgres \
  "/data/NYC_Buildings_LoD2_CityGML/NYC_Buildings_LoD2_CityGML.gml"
# Importar calles
docker run --rm --network host -v "$(pwd)/datos-nyc:/data" 3dcitydb/citydb-tool:latest \
  import citygml --limit 50000 -H localhost -d laboratorio -u postgres -p postgres \
  "/data/NYC_CityGML_LoD2_Roadbed/Roadbed/Road.gml"
# Cargar MapPLUTO
ogr2ogr -f "PostgreSQL" "PG:host=localhost port=5432 dbname=laboratorio user=postgres password=postgres" \
  datos-nyc/mappluto_26v1/mappluto.shp -nln public.mappluto -nlt MULTIPOLYGON \
  -t_srs EPSG:32118 -s_srs EPSG:2263 -lco GEOMETRY_NAME=geom -overwrite

bash geoserver-setup.sh       # configurar GeoServer
# Abrir http://localhost:8081
```

---

## Por que los edificios en Cesium se ven como cajas

Los datos CityGML LoD2 contienen geometria detallada: cada edificio tiene entre 20 y 50
poligonos 3D separados (WallSurface, RoofSurface, GroundSurface, etc.) que describen
techos inclinados, terrazas, escalones.

**Lo que mostramos en el visor web** es diferente: tomamos solo la GroundSurface
(el poligono de la base) y lo extruimos verticalmente hasta la altura del edificio.
Esto produce una caja rectangular simple pero conserva la altura real.

**Por que no usamos la geometria LoD2 completa en el web:**
- 1597 edificios x ~30 poligonos = ~48.000 poligonos a renderizar
- Requeriria exportar a formato 3D Tiles (proceso con citydb-tool export)
- El visor actual usa GeoJSON (simple, facil de servir con GeoServer)
- Para el analisis de zonificacion la altura es lo mas importante, no la forma del techo

**Los datos de altura SI son de LoD2** — vienen del bounding box Z del modelo real,
no de una estimacion. La forma es simplificada, los numeros son correctos.

Para visualizacion LoD2 real en Cesium se necesitaria:
1. `citydb-tool export 3dtiles` → genera archivo .3dtiles
2. Servir con nginx
3. `viewer.scene.primitives.add(new Cesium.Cesium3DTileset({url: '...'}))`
