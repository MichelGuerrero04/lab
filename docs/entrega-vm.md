# Entrega en VM

Esta guia es para dejar una maquina virtual lista para evaluacion del laboratorio.
La idea es que quien corrija no tenga que instalar nada ni reconstruir el entorno:
solo debe abrir la VM, ejecutar un comando y abrir el visor.

## Uso esperado por la docente

Al iniciar la VM, abrir una terminal y ejecutar:

```bash
cd ~/lab
./scripts/start_eval.sh
```

Ese comando:

- levanta los contenedores Docker;
- verifica Postgres/3D CityDB, GeoServer, Cesium, WFS, 3D Tiles y queries;
- deja el visor disponible en `http://localhost:8081`;
- intenta abrir el navegador automaticamente si la VM tiene entorno grafico.

Si todo esta bien, debe terminar con:

```text
OK - VM lista para evaluacion.
```

Despues abrir:

```text
http://localhost:8081
```

La docente no deberia tener que instalar paquetes, descargar datasets, cargar la
base ni regenerar tiles.

## Configuracion recomendada

- Ubuntu 24.04 LTS o Ubuntu 22.04 LTS.
- 4 CPU.
- 8 GB RAM.
- 25 GB de disco si se entregan los datos ya descargados.
- Acceso a internet si se quiere reconstruir todo desde cero.

## Lo que la VM debe traer preparado

Antes de entregar la VM, nosotros debemos dejar ya instalado y probado:

- Git, curl, Python 3, p7zip y GDAL/ogr2ogr.
- Docker Engine con Docker Compose v2.
- Usuario de la VM con permisos para correr `docker` sin `sudo`.
- Repo clonado en `~/lab`.
- Datasets descargados en `~/lab/datos-nyc/`.
- Volumen Docker `lab_citydb_data` poblado.
- Volumen Docker `lab_geoserver_data` poblado.
- 3D Tiles LoD2 generados en `~/lab/web/tiles/lod2/`.

Con ese estado, el comando `./scripts/start_eval.sh` alcanza para evaluar.

## Preparacion de la VM por el equipo

Esta seccion es para quien arma la VM, no para la docente.

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

Clonar el proyecto en el home del usuario:

```bash
git clone https://github.com/MichelGuerrero04/lab.git
cd lab
```

Preparar todo una vez:

```bash
docker compose up -d
./download_real_data.sh
./import_real_data.sh
./scripts/run_queries.sh
./scripts/vm_smoke_test.sh
```

## Reconstruccion desde cero, si hiciera falta

Si durante la preparacion se quiere reconstruir todo:

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

Antes de exportar o entregar la VM, correr:

```bash
./scripts/start_eval.sh
```

Debe terminar con:

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
