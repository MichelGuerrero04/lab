# Entrega en VM

Esta guia es para dejar una maquina virtual lista para evaluacion del laboratorio.
La idea es que quien corrija pueda abrir el visor, ejecutar consultas y revisar el
pipeline sin instalar herramientas adicionales dentro de la VM.

## Configuracion recomendada

- Ubuntu 24.04 LTS o Ubuntu 22.04 LTS.
- 4 CPU.
- 8 GB RAM.
- 25 GB de disco si se entregan los datos ya descargados.
- Acceso a internet si se quiere reconstruir todo desde cero.

## Software que debe quedar instalado

```bash
sudo apt update
sudo apt install -y git curl python3 p7zip-full gdal-bin
```

Docker debe quedar instalado con Docker Compose v2. En Ubuntu, la forma mas simple
es seguir la guia oficial de Docker Engine y despues validar:

```bash
docker --version
docker compose version
```

Para evitar usar `sudo` en cada comando:

```bash
sudo usermod -aG docker "$USER"
```

Cerrar sesion y volver a entrar antes de seguir.

## Estructura esperada

Clonar el proyecto en el home del usuario de la VM:

```bash
git clone https://github.com/MichelGuerrero04/lab.git
cd lab
```

Si la VM se entrega ya preparada, conviene dejar tambien:

- `datos-nyc/NYC_Buildings_LoD2_CityGML.zip`
- `datos-nyc/mappluto_26v1_shp.zip`
- volumen Docker `lab_citydb_data` poblado
- volumen Docker `lab_geoserver_data` poblado
- `web/tiles/lod2/` generado

Con eso la docente solo necesita levantar:

```bash
docker compose up -d
./scripts/vm_smoke_test.sh
```

Y abrir:

```text
http://localhost:8081
```

## Reconstruccion desde cero

Si se quiere validar que el pipeline entero es reproducible:

```bash
docker compose down -v
docker compose up -d
./download_real_data.sh
./import_real_data.sh
./scripts/run_queries.sh
./scripts/vm_smoke_test.sh
```

Esto descarga datasets externos, importa CityGML en 3D CityDB, carga MapPLUTO,
crea vistas SQL, regenera 3D Tiles LoD2, publica GeoServer y ejecuta las consultas.

## Credenciales y URLs

- Visor Cesium: `http://localhost:8081`
- GeoServer: `http://localhost:8080/geoserver`
- GeoServer usuario: `admin`
- GeoServer password: `geoserver`
- PostgreSQL host: `localhost`
- PostgreSQL puerto: `5432`
- Base: `laboratorio`
- Usuario: `postgres`
- Password: `postgres`

## Como saber que quedo bien

El smoke test debe terminar con:

```text
OK - VM lista para evaluacion.
```

Ademas, en el visor deben verse:

- modo `LoD1 Analytics`, con edificios coloreables por zona, FAR, altura y solar;
- modo `LoD2 Real 3D`, con techos y paredes reales;
- panel `Sombra solar 3D`;
- consultas de simulacion en el panel derecho.

El archivo `web/tiles/lod2/tileset.json` debe tener `boundingVolume.region` con
altura minima `0.0`. Esa es la senial de que los edificios LoD2 fueron normalizados
y no deberian aparecer flotando.

