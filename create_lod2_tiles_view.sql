DROP VIEW IF EXISTS public.v_lod2_buildings_3dtiles;

CREATE OR REPLACE VIEW public.v_lod2_buildings_3dtiles AS
WITH building_surfaces AS (
    SELECT
        b.id AS id,
        ST_ZMin(Box3D(b.envelope)) AS z_base,
        gd.geometry AS geom
    FROM citydb.feature b
    JOIN citydb.objectclass boc
        ON boc.id = b.objectclass_id
       AND boc.classname = 'Building'
    JOIN citydb.property boundary
        ON boundary.feature_id = b.id
       AND boundary.name = 'boundary'
    JOIN citydb.feature surface
        ON surface.id = boundary.val_feature_id
    JOIN citydb.objectclass soc
        ON soc.id = surface.objectclass_id
       AND soc.classname IN ('WallSurface', 'RoofSurface', 'GroundSurface')
    JOIN citydb.property lod2
        ON lod2.feature_id = surface.id
       AND lod2.name = 'lod2MultiSurface'
    JOIN citydb.geometry_data gd
        ON gd.id = lod2.val_geometry_id
    WHERE b.envelope IS NOT NULL
      AND gd.geometry IS NOT NULL
      AND ST_SetSRID(gd.geometry, 32118)
          && ST_MakeEnvelope(308000, 60500, 309500, 62000, 32118)
),
dumped AS (
    SELECT
        id,
        (ST_Dump(ST_Translate(ST_SetSRID(geom, 32118), 0, 0, -z_base))).geom AS geom
    FROM building_surfaces
)
SELECT
    id,
    ST_Multi(ST_Collect(geom))::geometry(MultiPolygonZ, 32118) AS geom
FROM dumped
GROUP BY id;
