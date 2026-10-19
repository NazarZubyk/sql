-- start and finish node ids — edit these two lines
SET @start  = 1;
SET @finish = 12;

-- 1) is the finish on the other side of the river?
SELECT
    s.id AS start_node,
    s.name AS start_name,
    s.river_bank AS start_bank,
    f.id AS finish_node,
    f.name AS finish_name,
    f.river_bank AS finish_bank,
    CASE WHEN s.river_bank <> f.river_bank THEN 'yes' ELSE 'no' END AS finish_on_other_bank,
    ROUND(ST_Distance_Sphere(POINT(s.longitude, s.latitude),
                             POINT(f.longitude, f.latitude))) AS straight_line_m
FROM road_node_mem s
JOIN road_node_mem f
WHERE s.id = @start
  AND f.id = @finish;

-- 2) routes with distances, per bridge
--    h1..h5 = road_edge ids before the bridge, h6..h10 = after the bridge
SELECT
    l1.start        AS start,
    l2.finish       AS finish,
    l1.distance + b.bridge_distance + l2.distance AS distance,
    l1.distance     AS distance_to_bridge,
    b.bridge_distance AS distance_over_bridge,
    l2.distance     AS distance_after_bridge,
    b.near_node     AS bridge_node_this_side,
    b.far_node      AS bridge_node_other_side,
    b.bridge_edge_id AS bridge_edge,
    l1.h1 AS h1, l1.h2 AS h2, l1.h3 AS h3, l1.h4 AS h4, l1.h5 AS h5,
    l2.h1 AS h6, l2.h2 AS h7, l2.h3 AS h8, l2.h4 AS h9, l2.h5 AS h10
FROM (
    -- leg 1: start -> every bridge entrance on the start's bank
    --        (the same 5-hop query as in find_routes_same_bank.sql,
    --         with finish = bridge nodes instead of one node)
    SELECT DISTINCT
        c1.id AS start,
        c.id  AS finish,
        COALESCE(h1.distance_m, 0) + COALESCE(h2.distance_m, 0) + COALESCE(h3.distance_m, 0)
            + COALESCE(h4.distance_m, 0) + COALESCE(h5.distance_m, 0) AS distance,
        h1.id AS h1, h2.id AS h2, h3.id AS h3, h4.id AS h4, h5.id AS h5
    FROM road_node_mem c1
    JOIN road_node_mem c
        ON c.id IN (SELECT id FROM road_node_mem
                    WHERE is_bridge = 1
                      AND river_bank = (SELECT river_bank FROM road_node_mem WHERE id = @start))
    JOIN road_edge_mem h1
        ON c1.id IN (h1.from_node_id, h1.to_node_id)
    LEFT JOIN road_edge_mem h2
        ON (h1.from_node_id IN (h2.from_node_id, h2.to_node_id)
            OR h1.to_node_id IN (h2.from_node_id, h2.to_node_id))
        AND h1.id <> h2.id
        AND NOT (c.id IN (h1.from_node_id, h1.to_node_id))
    LEFT JOIN road_edge_mem h3
        ON (h2.from_node_id IN (h3.from_node_id, h3.to_node_id)
            OR h2.to_node_id IN (h3.from_node_id, h3.to_node_id))
        AND NOT h3.id IN (h1.id, h2.id)
        AND NOT (c.id IN (h2.from_node_id, h2.to_node_id))
        AND h1.distance_m + h2.distance_m + h3.distance_m
            < 3 * ST_Distance_Sphere(POINT(c1.longitude, c1.latitude),
                                      POINT(c.longitude,  c.latitude))
    LEFT JOIN road_edge_mem h4
        ON (h3.from_node_id IN (h4.from_node_id, h4.to_node_id)
            OR h3.to_node_id IN (h4.from_node_id, h4.to_node_id))
        AND NOT h4.id IN (h1.id, h2.id, h3.id)
        AND NOT (c.id IN (h3.from_node_id, h3.to_node_id))
        AND h1.distance_m + h2.distance_m + h3.distance_m + h4.distance_m
            < 3 * ST_Distance_Sphere(POINT(c1.longitude, c1.latitude),
                                      POINT(c.longitude,  c.latitude))
    LEFT JOIN road_edge_mem h5
        ON (h4.from_node_id IN (h5.from_node_id, h5.to_node_id)
            OR h4.to_node_id IN (h5.from_node_id, h5.to_node_id))
        AND NOT h5.id IN (h1.id, h2.id, h3.id, h4.id)
        AND NOT (c.id IN (h4.from_node_id, h4.to_node_id))
        AND h1.distance_m + h2.distance_m + h3.distance_m + h4.distance_m + h5.distance_m
            < 3 * ST_Distance_Sphere(POINT(c1.longitude, c1.latitude),
                                      POINT(c.longitude,  c.latitude))
    WHERE c1.id = @start
      AND c.id <> c1.id
      AND (
             (c.id IN (h1.from_node_id, h1.to_node_id) AND h2.id IS NULL)
          OR (c.id IN (h2.from_node_id, h2.to_node_id) AND h3.id IS NULL)
          OR (c.id IN (h3.from_node_id, h3.to_node_id) AND h4.id IS NULL)
          OR (c.id IN (h4.from_node_id, h4.to_node_id) AND h5.id IS NULL)
          OR (c.id IN (h5.from_node_id, h5.to_node_id))
          )
    UNION ALL
    -- start is itself a bridge node: leg 1 is empty (0 m)
    SELECT @start, @start, 0, NULL, NULL, NULL, NULL, NULL
) l1
JOIN (
    -- bridges: near = endpoint on the start's bank, far = the other one
    SELECT e.id         AS bridge_edge_id,
           e.distance_m AS bridge_distance,
           IF(nf.river_bank = (SELECT river_bank FROM road_node_mem WHERE id = @start),
              e.from_node_id, e.to_node_id) AS near_node,
           IF(nf.river_bank = (SELECT river_bank FROM road_node_mem WHERE id = @start),
              e.to_node_id,  e.from_node_id) AS far_node
    FROM road_edge_mem e
    JOIN road_node_mem nf ON nf.id = e.from_node_id
    WHERE e.is_bridge = 1
) b ON l1.finish = b.near_node
JOIN (
    -- leg 2: every bridge exit on the finish's bank -> finish
    --        (the same 5-hop query, with start = bridge nodes)
    SELECT DISTINCT
        c1.id AS start,
        c.id  AS finish,
        COALESCE(h1.distance_m, 0) + COALESCE(h2.distance_m, 0) + COALESCE(h3.distance_m, 0)
            + COALESCE(h4.distance_m, 0) + COALESCE(h5.distance_m, 0) AS distance,
        h1.id AS h1, h2.id AS h2, h3.id AS h3, h4.id AS h4, h5.id AS h5
    FROM road_node_mem c1
    JOIN road_node_mem c
        ON c.id = @finish
    JOIN road_edge_mem h1
        ON c1.id IN (h1.from_node_id, h1.to_node_id)
    LEFT JOIN road_edge_mem h2
        ON (h1.from_node_id IN (h2.from_node_id, h2.to_node_id)
            OR h1.to_node_id IN (h2.from_node_id, h2.to_node_id))
        AND h1.id <> h2.id
        AND NOT (c.id IN (h1.from_node_id, h1.to_node_id))
    LEFT JOIN road_edge_mem h3
        ON (h2.from_node_id IN (h3.from_node_id, h3.to_node_id)
            OR h2.to_node_id IN (h3.from_node_id, h3.to_node_id))
        AND NOT h3.id IN (h1.id, h2.id)
        AND NOT (c.id IN (h2.from_node_id, h2.to_node_id))
        AND h1.distance_m + h2.distance_m + h3.distance_m
            < 3 * ST_Distance_Sphere(POINT(c1.longitude, c1.latitude),
                                      POINT(c.longitude,  c.latitude))
    LEFT JOIN road_edge_mem h4
        ON (h3.from_node_id IN (h4.from_node_id, h4.to_node_id)
            OR h3.to_node_id IN (h4.from_node_id, h4.to_node_id))
        AND NOT h4.id IN (h1.id, h2.id, h3.id)
        AND NOT (c.id IN (h3.from_node_id, h3.to_node_id))
        AND h1.distance_m + h2.distance_m + h3.distance_m + h4.distance_m
            < 3 * ST_Distance_Sphere(POINT(c1.longitude, c1.latitude),
                                      POINT(c.longitude,  c.latitude))
    LEFT JOIN road_edge_mem h5
        ON (h4.from_node_id IN (h5.from_node_id, h5.to_node_id)
            OR h4.to_node_id IN (h5.from_node_id, h5.to_node_id))
        AND NOT h5.id IN (h1.id, h2.id, h3.id, h4.id)
        AND NOT (c.id IN (h4.from_node_id, h4.to_node_id))
        AND h1.distance_m + h2.distance_m + h3.distance_m + h4.distance_m + h5.distance_m
            < 3 * ST_Distance_Sphere(POINT(c1.longitude, c1.latitude),
                                      POINT(c.longitude,  c.latitude))
    WHERE c1.id IN (SELECT id FROM road_node_mem
                    WHERE is_bridge = 1
                      AND river_bank = (SELECT river_bank FROM road_node_mem WHERE id = @finish))
      AND c.id <> c1.id
      AND (
             (c.id IN (h1.from_node_id, h1.to_node_id) AND h2.id IS NULL)
          OR (c.id IN (h2.from_node_id, h2.to_node_id) AND h3.id IS NULL)
          OR (c.id IN (h3.from_node_id, h3.to_node_id) AND h4.id IS NULL)
          OR (c.id IN (h4.from_node_id, h4.to_node_id) AND h5.id IS NULL)
          OR (c.id IN (h5.from_node_id, h5.to_node_id))
          )
    UNION ALL
    -- finish is itself a bridge node: leg 2 is empty (0 m)
    SELECT @finish, @finish, 0, NULL, NULL, NULL, NULL, NULL
) l2 ON l2.start = b.far_node AND l2.finish = @finish
ORDER BY distance
LIMIT 5;
