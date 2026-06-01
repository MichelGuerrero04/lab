# Lab - Ciudades 3D con CityGML, 3D CityDB, GeoServer y Cesium

Este repositorio contiene un prototipo web para el laboratorio de Bases de Datos para Ciudades 3D.

La idea del caso de estudio es tomar edificios reales LoD2 de NYC, cargarlos en 3D CityDB, cruzarlos con datos de zonificacion de MapPLUTO y mostrar metricas urbanas en un visor web 3D.

## Que se ve en el visor

El visor Cesium muestra edificios extruidos sobre OpenStreetMap y permite cambiar la simbologia por:

- zona normativa (`zonedist1`);
- posibles violaciones de FAR;
- posibles violaciones de altura;
- exposicion solar aproximada;
- datos del lote al hacer clic sobre un edificio.

URL local del visor:

```text
http://localhost:8081
```

## Stack

- `citydb`: PostgreSQL/PostGIS con 3D CityDB 5, SRID `EPSG:32118`.
- `geoserver`: publica vistas PostGIS como WFS.
- `cesium-viewer`: nginx sirviendo `web/index.html`.
- `scripts/filter_citygml_bbox.py`: recorta el CityGML grande antes de importarlo.

Puertos locales:

- Postgres/3D CityDB: `localhost:5432`
- GeoServer: `http://localhost:8082/geoserver`
- Cesium: `http://localhost:8081`

GeoServer usa `8082` porque `8080` suele estar ocupado por otros servicios.

## Datos

Los datos grandes no estan versionados en Git. Se descargan en `datos-nyc/`, carpeta ignorada por `.gitignore`.

Fuentes usadas:

- NYC Buildings LoD2 CityGML, publicado como dataset de ejemplo de 3D CityDB/TUM.
- MapPLUTO 26v1, publicado por NYC Planning, para atributos de zoning y FAR.

El CityGML completo viene comprimido en un ZIP de alrededor de 2.46 GB, pero el GML interno pesa mas de 31 GB. Por eso no lo descomprimimos completo: se lee por streaming con `7z` y se genera un recorte espacial chico.

Zona de analisis:

```text
EPSG:32118 bbox = 308000, 60500, 309500, 62000
```

Esa bbox cae en el area Queens/Brooklyn, cerca de Middle Village / Glendale.

## Requisitos

Antes de empezar, instalar:

- Docker Desktop
- `curl`
- `python3`
- `7z` / p7zip
- GDAL, para tener `ogr2ogr`

En macOS con Homebrew:

```bash
brew install p7zip gdal
```

Tambien conviene tener al menos 5 GB libres. No hacen falta 31 GB porque el flujo evita descomprimir el GML completo.

## Instalacion desde cero

Clonar el repo:

```bash
git clone git@github.com:MichelGuerrero04/lab.git
cd lab
```

Levantar servicios:

```bash
docker compose up -d
```

Esto crea Postgres/3D CityDB, GeoServer y el nginx del visor. Al principio todavia no hay datos reales cargados.

Descargar datasets:

```bash
./download_real_data.sh
```

Esto descarga:

- `datos-nyc/NYC_Buildings_LoD2_CityGML.zip`
- `datos-nyc/mappluto_26v1_shp.zip`

Importar y publicar todo:

```bash
./import_real_data.sh
```

Este script hace varios pasos porque cada uno tiene una razon:

- genera `datos-nyc/NYC_Buildings_LoD2_bbox.gml`, un CityGML recortado a la bbox del laboratorio;
- importa ese GML en 3D CityDB con `citydb-tool`;
- carga MapPLUTO recortado y reproyectado a `EPSG:32118`;
- ejecuta `vistas_sql.sql` para crear las vistas analiticas;
- ejecuta `geoserver-setup.sh` para publicar las vistas como capas WFS;
- deja listo el visor web.

Abrir:

```text
http://localhost:8081
```

## Verificaciones

Ver que los contenedores esten vivos:

```bash
docker compose ps
```

Ver cantidad de edificios analiticos:

```bash
docker compose exec -T citydb psql -U postgres -d laboratorio \
  -c "select count(*) from public.zona_analytics;"
```

En la corrida usada para este prototipo, el resultado fue `5395`.

Probar GeoServer/WFS:

```bash
curl "http://localhost:8082/geoserver/tsig/ows?service=WFS&version=2.0.0&request=GetFeature&typeName=tsig:zona_analytics&outputFormat=application%2Fjson&srsName=EPSG:4326&count=1"
```

Si devuelve un `FeatureCollection`, GeoServer esta publicando bien.

## Capas y tablas principales

- `citydb.feature`: features CityGML importadas en el esquema 3D CityDB.
- `public.mappluto`: lotes MapPLUTO recortados.
- `public.v_buildings_3d`: edificios importados con altura calculada desde el envelope 3D.
- `public.zona_buildings`: geometria de base de edificios desde `GroundSurface`.
- `public.zona_analytics`: capa principal del visor, con metricas + zoning/FAR.
- `public.zona_roads`: queda vacia en esta version porque solo se importan edificios, no calles CityGML.

La capa que consume el frontend es:

```text
tsig:zona_analytics
```

## Por que hay un archivo demo

`seed_demo_data.sql` crea una capa sintetica chica de 96 edificios. Sirve solo para probar que Docker, GeoServer y Cesium se comunican.

Para el laboratorio real no usar esa capa como resultado final. El flujo real es:

```bash
./download_real_data.sh
./import_real_data.sh
```

## Repetir desde una base limpia

Si queres borrar la base y empezar de cero:

```bash
docker compose down -v
docker compose up -d
./import_real_data.sh
```

No hace falta volver a ejecutar `download_real_data.sh` si `datos-nyc/` sigue existiendo.

## Problemas comunes

Si `7z` no existe:

```bash
brew install p7zip
```

Si `ogr2ogr` no existe:

```bash
brew install gdal
```

Si `localhost:8082` no responde, esperar unos segundos y revisar:

```bash
docker compose ps
docker compose logs geoserver
```

Si el visor carga pero no muestra edificios, probar primero el WFS con el `curl` de verificacion. Si WFS funciona, refrescar el navegador con cache limpia.

## Notas sobre conteos

La guia original del laboratorio menciona `1597` edificios para una corrida previa. En este repo, el filtro espacial sobre el CityGML real completo produce alrededor de `5395` registros en `zona_analytics`.

La diferencia no significa que sean datos sinteticos: el visor actual usa edificios reales de NYC y lotes reales de MapPLUTO. Simplemente el recorte efectivo incluye mas edificios que la corrida documentada originalmente.
