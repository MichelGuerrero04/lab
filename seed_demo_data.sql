-- Datos DEMO para levantar el visor sin los datasets NYC completos.
-- No usar como resultado analitico real: es una muestra sintetica con la
-- misma estructura que espera web/index.html y GeoServer.

DROP TABLE IF EXISTS public.zona_analytics CASCADE;

CREATE TABLE public.zona_analytics AS
WITH base AS (
  SELECT
    row_number() OVER () AS qgis_id,
    x,
    y,
    (ARRAY['R4','R4-1','R4B','R5B','R6B','M1-1'])[
      1 + ((x + y) % 6)
    ] AS zonedist1,
    7 + ((x * 3 + y * 5) % 18)::numeric AS height,
    0.7 + (((x + y) % 12)::numeric / 10.0) AS far_construido,
    1.0 + (((x * 2 + y) % 10)::numeric / 10.0) AS far_permitido,
    1920 + ((x * 11 + y * 7) % 100) AS pluto_yearbuilt,
    1 + ((x + y) % 6) AS codigo_uso_suelo,
    70 + ((x * 13 + y * 17) % 180)::numeric AS area_planta
  FROM generate_series(0, 11) AS x
  CROSS JOIN generate_series(0, 7) AS y
)
SELECT
  qgis_id,
  ST_SetSRID(
    ST_MakeEnvelope(
      308050 + x * 115,
      60550 + y * 150,
      308110 + x * 115 + ((x + y) % 4) * 8,
      60620 + y * 150 + ((x * 2 + y) % 4) * 8,
      32118
    ),
    32118
  )::geometry(Polygon, 32118) AS geom,
  height,
  0::numeric AS z_min,
  area_planta,
  ROUND((area_planta * height)::numeric, 2) AS volumen,
  ROUND((height / NULLIF(area_planta, 0))::numeric, 4) AS ratio_altura_area,
  CASE
    WHEN height < 10 THEN '3-4 pisos'
    WHEN height < 20 THEN '5-7 pisos'
    ELSE 'Alto +8 pisos'
  END AS categoria_altura,
  (ARRAY['Norte','Este','Sur','Oeste'])[1 + ((x + y) % 4)] AS orientacion_fachada,
  (ARRAY['Alta','Media','Baja'])[1 + ((x * 2 + y) % 3)] AS exposicion_solar,
  ((x + y) % 8) AS edificios_proximos_20m,
  CASE
    WHEN ((x + y) % 8) >= 5 THEN 'Muy densa'
    WHEN ((x + y) % 8) >= 2 THEN 'Densa'
    ELSE 'Aislada'
  END AS densidad_entorno,
  zonedist1,
  far_permitido,
  far_construido,
  ROUND((far_construido / NULLIF(far_permitido, 0))::numeric, 2) AS uso_far_pct,
  GREATEST(1, ROUND(height / 3.1))::integer AS pluto_numfloors,
  pluto_yearbuilt,
  codigo_uso_suelo,
  'DEMO OWNER ' || qgis_id AS propietario,
  qgis_id || ' DEMO ST' AS direccion_lote
FROM base;

CREATE INDEX zona_analytics_geom_idx
  ON public.zona_analytics
  USING gist (geom);

DROP TABLE IF EXISTS public.zona_buildings CASCADE;
CREATE TABLE public.zona_buildings AS
SELECT
  qgis_id,
  ST_Force3DZ(geom)::geometry(PolygonZ, 32118) AS geom,
  height,
  z_min,
  height AS z_max,
  area_planta,
  volumen,
  ratio_altura_area
FROM public.zona_analytics;

CREATE INDEX zona_buildings_geom_idx
  ON public.zona_buildings
  USING gist (geom);

DROP TABLE IF EXISTS public.v_buildings_3d CASCADE;
CREATE TABLE public.v_buildings_3d AS
SELECT qgis_id, geom, height, z_min, height AS z_max
FROM public.zona_analytics;

CREATE INDEX v_buildings_3d_geom_idx
  ON public.v_buildings_3d
  USING gist (geom);

DROP TABLE IF EXISTS public.zona_roads CASCADE;
CREATE TABLE public.zona_roads AS
SELECT
  row_number() OVER () AS qgis_id,
  'Road'::text AS tipo,
  ST_Buffer(
    ST_SetSRID(
      ST_MakeLine(
        ST_MakePoint(308000, 60520 + n * 150),
        ST_MakePoint(309500, 60520 + n * 150)
      ),
      32118
    ),
    8
  )::geometry(Polygon, 32118) AS geom
FROM generate_series(0, 10) AS n;

CREATE INDEX zona_roads_geom_idx
  ON public.zona_roads
  USING gist (geom);

SELECT 'zona_analytics' AS table_name, COUNT(*) AS features
FROM public.zona_analytics;
