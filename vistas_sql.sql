-- Orden: ejecutar en secuencia v_buildings_3d -> zona_buildings -> zona_roads -> zona_analytics

-- Vista 1: edificios completos (toda la ciudad, 2D envelope)
DROP MATERIALIZED VIEW IF EXISTS public.v_buildings_3d CASCADE;
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

-- Vista 2: edificios zona Brooklyn ~2.25km2 (geometria real desde GroundSurface)
-- Bbox: 308000-309500 x, 60500-62000 y (EPSG:32118) — zona con R4/R4-1/R4B/R5B/M1-1/R6B
DROP MATERIALIZED VIEW IF EXISTS public.zona_buildings CASCADE;
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

-- Vista 3: calles de la zona recortadas al bbox
DROP MATERIALIZED VIEW IF EXISTS public.zona_roads CASCADE;
CREATE MATERIALIZED VIEW public.zona_roads AS
SELECT
    g.id AS qgis_id,
    oc.classname AS tipo,
    ST_Force3DZ(
        ST_CollectionExtract(
            ST_Intersection(
                ST_MakeValid(ST_SetSRID(g.geometry, 32118)),
                ST_MakeEnvelope(308000, 60500, 309500, 62000, 32118)
            ), 3)
    )::geometry(MultiPolygonZ, 32118) AS geom
FROM citydb.geometry_data g
JOIN citydb.feature f ON g.feature_id = f.id
JOIN citydb.objectclass oc ON f.objectclass_id = oc.id
WHERE oc.classname IN ('Road', 'Square', 'Track')
  AND g.geometry IS NOT NULL
  AND ST_SetSRID(g.geometry, 32118) && ST_MakeEnvelope(308000, 60500, 309500, 62000, 32118);

CREATE INDEX zona_roads_geom_idx ON public.zona_roads USING GIST(geom);

-- Vista 4: metricas analiticas urbanas con datos de zonificacion MapPLUTO
DROP MATERIALIZED VIEW IF EXISTS public.zona_analytics CASCADE;
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
),
pluto AS (
    SELECT DISTINCT ON (e.qgis_id)
        e.qgis_id,
        p.zonedist1,
        p.residfar,
        p.builtfar,
        p.numfloors AS pluto_numfloors,
        p.yearbuilt AS pluto_yearbuilt,
        p.landuse,
        p.ownername,
        p.address
    FROM edificios e
    LEFT JOIN public.mappluto p ON ST_Intersects(
        ST_Centroid(e.geom2d), p.geom
    )
    ORDER BY e.qgis_id
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
    END AS densidad_entorno,
    -- Datos MapPLUTO (zonificacion y uso)
    pl.zonedist1,
    pl.residfar AS far_permitido,
    pl.builtfar AS far_construido,
    ROUND((CASE WHEN pl.residfar > 0 THEN pl.builtfar / pl.residfar ELSE NULL END)::numeric, 2) AS uso_far_pct,
    pl.pluto_numfloors,
    pl.pluto_yearbuilt,
    pl.landuse AS codigo_uso_suelo,
    pl.ownername AS propietario,
    pl.address AS direccion_lote
FROM edificios e
JOIN orientacion o ON o.qgis_id = e.qgis_id
JOIN vecinos v ON v.qgis_id = e.qgis_id
LEFT JOIN pluto pl ON pl.qgis_id = e.qgis_id;

CREATE INDEX zona_analytics_geom_idx ON public.zona_analytics USING GIST(geom);
