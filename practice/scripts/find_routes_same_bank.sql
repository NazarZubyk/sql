
-- start and finish node ids — edit these two lines
SET @start  = 1;
SET @finish = 3;

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

-- 2) routes with distances (h1..h5 = road_edge ids of each hop)
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
WHERE c1.id = @start
  AND c.id <> c1.id
  AND (
         (c.id IN (h1.from_node_id, h1.to_node_id) AND h2.id IS NULL)
      OR (c.id IN (h2.from_node_id, h2.to_node_id) AND h3.id IS NULL)
      OR (c.id IN (h3.from_node_id, h3.to_node_id) AND h4.id IS NULL)
      OR (c.id IN (h4.from_node_id, h4.to_node_id) AND h5.id IS NULL)
      OR (c.id IN (h5.from_node_id, h5.to_node_id))
      )
ORDER BY distance
LIMIT 5;
