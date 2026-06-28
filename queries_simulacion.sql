-- =============================================================
-- QUERIES DE SIMULACION DE ZONIFICACION NYC
-- Requiere: zona_analytics (con MapPLUTO) + public.mappluto
-- SRID: 32118 (NAD83 / New York Long Island)
-- =============================================================

\pset pager off

-- Parametros modificables desde psql con -v nombre=valor.
-- Ejemplo:
-- docker compose exec -T citydb psql -U postgres -d laboratorio \
--   -v query_limit=10 -v vecinos_radio_m=50 < queries_simulacion.sql
\if :{?query_limit}
\else
\set query_limit 20
\endif

\if :{?vecinos_radio_m}
\else
\set vecinos_radio_m 30
\endif

\if :{?desarrollo_radio_m}
\else
\set desarrollo_radio_m 25
\endif

\if :{?far_disponible_min}
\else
\set far_disponible_min 0.5
\endif

\if :{?area_min_m2}
\else
\set area_min_m2 200
\endif

\if :{?solar_area_min_m2}
\else
\set solar_area_min_m2 100
\endif

\if :{?historico_anio_max}
\else
\set historico_anio_max 1940
\endif

-- -------------------------------------------------------
-- Q1: Resumen de distritos de zonificacion en la zona
-- -------------------------------------------------------
\echo ''
\echo 'Q1 - Resumen de distritos de zonificacion en la zona'
SELECT 
    zonedist1 AS distrito,
    COUNT(*) AS edificios,
    ROUND(AVG(height)::numeric, 2) AS altura_promedio_m,
    ROUND(AVG(far_construido)::numeric, 2) AS far_promedio,
    ROUND(AVG(far_permitido)::numeric, 2) AS far_max_permitido,
    SUM(CASE WHEN far_construido > far_permitido AND far_permitido > 0 THEN 1 ELSE 0 END) AS edificios_far_violacion
FROM public.zona_analytics
WHERE zonedist1 IS NOT NULL
GROUP BY zonedist1
ORDER BY edificios DESC;

-- -------------------------------------------------------
-- Q2: Edificios con violacion de FAR (construido > permitido)
-- -------------------------------------------------------
\echo ''
\echo 'Q2 - Edificios con violacion de FAR'
SELECT 
    qgis_id, direccion_lote, zonedist1,
    height AS altura_m,
    far_permitido, far_construido,
    ROUND((far_construido - far_permitido)::numeric, 2) AS exceso_far,
    propietario
FROM public.zona_analytics
WHERE far_construido > far_permitido 
  AND far_permitido > 0
  AND zonedist1 IS NOT NULL
ORDER BY exceso_far DESC
LIMIT :query_limit;

-- -------------------------------------------------------
-- Q3: Violaciones de altura maxima por distrito
-- Alturas maximas NYC (metros): R4=9.14, R4-1=9.14, R4B=8.53,
--   R4A=9.14, R5=10.67, R5B=10.06, R6B=15.24, M1-1=no limite residencial
-- -------------------------------------------------------
\echo ''
\echo 'Q3 - Violaciones de altura maxima por distrito'
SELECT 
    qgis_id, direccion_lote, zonedist1, height AS altura_real_m,
    CASE zonedist1
        WHEN 'R4'   THEN 9.14
        WHEN 'R4-1' THEN 9.14
        WHEN 'R4A'  THEN 9.14
        WHEN 'R4B'  THEN 8.53
        WHEN 'R5'   THEN 10.67
        WHEN 'R5B'  THEN 10.06
        WHEN 'R6B'  THEN 15.24
        ELSE NULL
    END AS altura_max_permitida_m,
    ROUND((height - CASE zonedist1
        WHEN 'R4'   THEN 9.14
        WHEN 'R4-1' THEN 9.14
        WHEN 'R4A'  THEN 9.14
        WHEN 'R4B'  THEN 8.53
        WHEN 'R5'   THEN 10.67
        WHEN 'R5B'  THEN 10.06
        WHEN 'R6B'  THEN 15.24
        ELSE height END)::numeric, 2) AS metros_en_exceso,
    propietario
FROM public.zona_analytics
WHERE zonedist1 IN ('R4','R4-1','R4A','R4B','R5','R5B','R6B')
  AND height > CASE zonedist1
        WHEN 'R4'   THEN 9.14
        WHEN 'R4-1' THEN 9.14
        WHEN 'R4A'  THEN 9.14
        WHEN 'R4B'  THEN 8.53
        WHEN 'R5'   THEN 10.67
        WHEN 'R5B'  THEN 10.06
        WHEN 'R6B'  THEN 15.24
        ELSE 9999 END
ORDER BY metros_en_exceso DESC
LIMIT :query_limit;

-- -------------------------------------------------------
-- Q4: Simulacion — ¿que pasa si se aplica altura maxima estricta?
-- Muestra como cambiaria exposicion_solar si se recortan alturas
-- -------------------------------------------------------
\echo ''
\echo 'Q4 - Simulacion de altura maxima estricta'
WITH alturas_simuladas AS (
    SELECT 
        qgis_id, geom, zonedist1, height AS altura_original,
        LEAST(height, CASE zonedist1
            WHEN 'R4'   THEN 9.14
            WHEN 'R4-1' THEN 9.14
            WHEN 'R4A'  THEN 9.14
            WHEN 'R4B'  THEN 8.53
            WHEN 'R5'   THEN 10.67
            WHEN 'R5B'  THEN 10.06
            WHEN 'R6B'  THEN 15.24
            ELSE height END) AS altura_simulada
    FROM public.zona_analytics
    WHERE zonedist1 IS NOT NULL
),
impacto AS (
    SELECT a.*,
        COUNT(b.qgis_id) - 1 AS vecinos_con_altura_original,
        SUM(b.altura_original) AS suma_alturas_vecinas_original,
        SUM(b.altura_simulada) AS suma_alturas_vecinas_simulada
    FROM alturas_simuladas a
    JOIN alturas_simuladas b ON ST_DWithin(ST_Force2D(a.geom), ST_Force2D(b.geom), :vecinos_radio_m)
    GROUP BY a.qgis_id, a.geom, a.zonedist1, a.altura_original, a.altura_simulada
)
SELECT 
    zonedist1,
    COUNT(*) AS edificios,
    ROUND(AVG(altura_original)::numeric, 2) AS altura_prom_actual,
    ROUND(AVG(altura_simulada)::numeric, 2) AS altura_prom_simulada,
    ROUND(AVG(suma_alturas_vecinas_original - suma_alturas_vecinas_simulada)::numeric, 2) AS reduccion_alturas_entorno_prom
FROM impacto
WHERE altura_original != altura_simulada
GROUP BY zonedist1
ORDER BY reduccion_alturas_entorno_prom DESC;

-- -------------------------------------------------------
-- Q5: Potencial de densificacion — lotes con FAR subutilizado
-- Cuanto volumen ADICIONAL podria construirse legalmente
-- -------------------------------------------------------
\echo ''
\echo 'Q5 - Potencial de densificacion por FAR subutilizado'
SELECT 
    qgis_id, direccion_lote, zonedist1,
    area_planta AS area_lote_aprox_m2,
    far_permitido, far_construido,
    ROUND((far_permitido - far_construido)::numeric, 2) AS far_disponible,
    ROUND((far_permitido - far_construido) * area_planta::numeric, 2) AS m2_adicionales_posibles,
    ROUND(height::numeric, 2) AS altura_actual_m
FROM public.zona_analytics
WHERE far_permitido > far_construido
  AND far_permitido > 0
  AND far_construido > 0
  AND zonedist1 IS NOT NULL
ORDER BY m2_adicionales_posibles DESC
LIMIT :query_limit;

-- -------------------------------------------------------
-- Q6: Distribucion de uso de suelo por zona  
-- landuse codes: 01=1-fam, 02=2-fam, 03=walkup apt, 
--   04=elevator apt, 05=commercial, 06=industrial, 
--   07=transportation, 08=public, 09=open space, 10=parking
-- -------------------------------------------------------
\echo ''
\echo 'Q6 - Distribucion de uso de suelo por zona'
SELECT 
    zonedist1,
    codigo_uso_suelo AS landuse,
    COUNT(*) AS edificios,
    ROUND(AVG(height)::numeric, 2) AS altura_prom_m,
    ROUND(AVG(far_construido)::numeric, 2) AS far_prom
FROM public.zona_analytics
WHERE zonedist1 IS NOT NULL AND codigo_uso_suelo IS NOT NULL
GROUP BY zonedist1, codigo_uso_suelo
ORDER BY zonedist1, edificios DESC;

-- -------------------------------------------------------
-- Q7: Edificios con potencial solar (orientacion Sur + baja densidad)
-- Simulacion: candidatos para paneles solares o jardines en roof
-- -------------------------------------------------------
\echo ''
\echo 'Q7 - Edificios con potencial solar'
SELECT 
    qgis_id, direccion_lote, zonedist1,
    height AS altura_m,
    area_planta AS area_techo_aprox_m2,
    orientacion_fachada,
    exposicion_solar,
    densidad_entorno,
    edificios_proximos_20m
FROM public.zona_analytics
WHERE exposicion_solar = 'Alta'
  AND densidad_entorno IN ('Aislada', 'Densa')
  AND area_planta > :solar_area_min_m2
ORDER BY area_planta DESC
LIMIT :query_limit;

-- -------------------------------------------------------
-- Q8: Edificios historicos (construidos antes de 1940) que violan normas actuales
-- Muestra tension entre patrimonio y zonificacion moderna
-- -------------------------------------------------------
\echo ''
\echo 'Q8 - Edificios historicos y normas actuales'
SELECT 
    qgis_id, direccion_lote, zonedist1,
    pluto_yearbuilt AS anio_construccion,
    height AS altura_actual_m,
    far_construido, far_permitido,
    CASE WHEN far_construido > far_permitido THEN 'FAR excedido'
         WHEN height > CASE zonedist1
            WHEN 'R4'   THEN 9.14 WHEN 'R4-1' THEN 9.14
            WHEN 'R4B'  THEN 8.53 WHEN 'R5B'  THEN 10.06
            WHEN 'R6B'  THEN 15.24 ELSE 9999 END THEN 'Altura excedida'
         ELSE 'Conforme'
    END AS estado_normativo,
    propietario
FROM public.zona_analytics
WHERE pluto_yearbuilt > 0 AND pluto_yearbuilt < :historico_anio_max
  AND zonedist1 IS NOT NULL
ORDER BY pluto_yearbuilt ASC
LIMIT :query_limit;

-- -------------------------------------------------------
-- Q9: Impacto de nueva construccion en exposicion solar vecinos
-- Simula: si se construye edificio nuevo en lote vacio (FAR disponible)
-- ¿cuantos edificios cercanos perderian luz solar?
-- -------------------------------------------------------
\echo ''
\echo 'Q9 - Impacto de nueva construccion en exposicion solar de vecinos'
WITH lotes_potencial AS (
    SELECT qgis_id, direccion_lote, geom, zonedist1, area_planta,
           far_permitido, far_construido,
           (far_permitido - far_construido) AS far_disponible,
           (far_permitido - far_construido) * area_planta AS m2_adicionales
    FROM public.zona_analytics
    WHERE (far_permitido - far_construido) > :far_disponible_min
      AND far_permitido > 0
      AND area_planta > :area_min_m2
),
impacto_solar AS (
    SELECT 
        l.qgis_id AS lote_desarrollo,
        l.direccion_lote,
        l.zonedist1,
        l.m2_adicionales,
        COUNT(v.qgis_id) AS vecinos_afectados,
        SUM(CASE WHEN v.exposicion_solar = 'Alta' THEN 1 ELSE 0 END) AS vecinos_solar_alto_afectados
    FROM lotes_potencial l
    JOIN public.zona_analytics v ON ST_DWithin(ST_Force2D(l.geom), ST_Force2D(v.geom), :desarrollo_radio_m)
    WHERE l.qgis_id != v.qgis_id
    GROUP BY l.qgis_id, l.direccion_lote, l.zonedist1, l.m2_adicionales
)
SELECT * FROM impacto_solar
ORDER BY vecinos_solar_alto_afectados DESC
LIMIT :query_limit;
