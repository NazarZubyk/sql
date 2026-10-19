-- Seed data for road_node / road_edge and their dependencies:
--   geographicAreaType -> geographicArea -> street
-- Road network: 16 nodes (8 west bank, 8 east bank), 3 bridges over the river.
-- Bridges are edges with is_bridge = 1; both of their endpoint nodes are
-- marked is_bridge = 1 as well. Undirected streets are stored once per pair,
-- always with from_node_id < to_node_id (enforced by road_edge_node_order_chk).

-- ---------------------------------------------------------------------------
-- 1. Geographic areas (referenced by street)
-- ---------------------------------------------------------------------------

INSERT INTO geographicAreaType (`type`)
SELECT 'City'
WHERE NOT EXISTS (SELECT 1 FROM geographicAreaType WHERE `type` = 'City');

INSERT INTO geographicAreaType (`type`)
SELECT 'District'
WHERE NOT EXISTS (SELECT 1 FROM geographicAreaType WHERE `type` = 'District');

INSERT INTO geographicArea (`name`, `geographicAreaTypeID`)
SELECT 'City Center', t.id
FROM geographicAreaType t
WHERE t.`type` = 'City'
  AND NOT EXISTS (SELECT 1 FROM geographicArea WHERE `name` = 'City Center');

INSERT INTO geographicArea (`name`, `geographicAreaTypeID`)
SELECT 'West Bank District', t.id
FROM geographicAreaType t
WHERE t.`type` = 'District'
  AND NOT EXISTS (SELECT 1 FROM geographicArea WHERE `name` = 'West Bank District');

INSERT INTO geographicArea (`name`, `geographicAreaTypeID`)
SELECT 'East Bank District', t.id
FROM geographicAreaType t
WHERE t.`type` = 'District'
  AND NOT EXISTS (SELECT 1 FROM geographicArea WHERE `name` = 'East Bank District');

-- ---------------------------------------------------------------------------
-- 2. Streets
-- ---------------------------------------------------------------------------

INSERT INTO street (`name`, `geographicAreaID`, `drivable`)
SELECT s.`name`, a.id, 1
FROM (
    SELECT 'Svobody Avenue' AS `name`, 'City Center' AS area
    UNION ALL SELECT 'Railway Street', 'West Bank District'
    UNION ALL SELECT 'Market Street', 'West Bank District'
    UNION ALL SELECT 'Park Road', 'West Bank District'
    UNION ALL SELECT 'University Boulevard', 'West Bank District'
    UNION ALL SELECT 'East Park Road', 'East Bank District'
    UNION ALL SELECT 'Terminal Street', 'East Bank District'
    UNION ALL SELECT 'Industrial Highway', 'East Bank District'
    UNION ALL SELECT 'Hilltop Road', 'East Bank District'
    UNION ALL SELECT 'Riverside Drive', 'East Bank District'
) s
JOIN geographicArea a ON a.`name` = s.area
WHERE NOT EXISTS (SELECT 1 FROM street st WHERE st.`name` = s.`name`);

-- Bridge streets belong to no geographic area
INSERT INTO street (`name`, `geographicAreaID`, `drivable`)
SELECT 'North Bridge', NULL, 1
WHERE NOT EXISTS (SELECT 1 FROM street WHERE `name` = 'North Bridge');

INSERT INTO street (`name`, `geographicAreaID`, `drivable`)
SELECT 'Central Bridge', NULL, 1
WHERE NOT EXISTS (SELECT 1 FROM street WHERE `name` = 'Central Bridge');

INSERT INTO street (`name`, `geographicAreaID`, `drivable`)
SELECT 'South Bridge', NULL, 1
WHERE NOT EXISTS (SELECT 1 FROM street WHERE `name` = 'South Bridge');

-- ---------------------------------------------------------------------------
-- 3. Road nodes (reseeded: this script owns the road network tables)
--    river_bank = 'west' for ids 1..8, 'east' for ids 13..16;
--    nodes 5,6,7 (west ends) and 13,14,15 (east ends) are bridge towers.
-- ---------------------------------------------------------------------------

DELETE FROM road_edge;
DELETE FROM road_node;

INSERT INTO road_node (id, `name`, river_bank, is_bridge, longitude, latitude) VALUES
(1,  'Central Square',      'west', 0, 25.587100, 49.553500),
(2,  'Railway Station',     'west', 0, 25.581200, 49.558900),
(3,  'Market Square',       'west', 0, 25.592400, 49.556200),
(4,  'Park Junction',       'west', 0, 25.588900, 49.548700),
(5,  'North Bridge (West)', 'west', 1, 25.579300, 49.564100),
(6,  'Central Bridge (West)','west', 1, 25.596800, 49.551100),
(7,  'South Bridge (West)', 'west', 1, 25.593100, 49.542600),
(8,  'University Junction', 'west', 0, 25.600200, 49.549300),
(9,  'East Park',           'east', 0, 25.612400, 49.555800),
(10, 'Bus Terminal',        'east', 0, 25.618900, 49.563400),
(11, 'Industrial Zone',     'east', 0, 25.628300, 49.546100),
(12, 'Hilltop',             'east', 0, 25.621500, 49.559700),
(13, 'North Bridge (East)', 'east', 1, 25.610800, 49.566200),
(14, 'Central Bridge (East)','east', 1, 25.608200, 49.551700),
(15, 'South Bridge (East)', 'east', 1, 25.614900, 49.542100),
(16, 'Riverside East',      'east', 0, 25.617200, 49.549200);

-- ---------------------------------------------------------------------------
-- 4. Road edges (undirected, stored from_node_id < to_node_id)
-- ---------------------------------------------------------------------------

INSERT INTO road_edge
    (from_node_id, to_node_id, street_id, distance_m, travel_time_s, is_bridge)
VALUES
-- west bank streets
(1,  2,  (SELECT id FROM street WHERE `name` = 'Railway Street'      LIMIT 1), 1200, 180, 0),
(1,  3,  (SELECT id FROM street WHERE `name` = 'Market Street'       LIMIT 1),  800, 120, 0),
(2,  3,  (SELECT id FROM street WHERE `name` = 'Railway Street'      LIMIT 1),  900, 150, 0),
(1,  4,  (SELECT id FROM street WHERE `name` = 'Park Road'           LIMIT 1), 1000, 140, 0),
(3,  8,  (SELECT id FROM street WHERE `name` = 'University Boulevard' LIMIT 1), 1100, 160, 0),
(2,  8,  (SELECT id FROM street WHERE `name` = 'University Boulevard' LIMIT 1), 1500, 240, 0),
(4,  8,  (SELECT id FROM street WHERE `name` = 'Park Road'           LIMIT 1),  950, 130, 0),
(4,  5,  (SELECT id FROM street WHERE `name` = 'Park Road'           LIMIT 1),  600,  90, 0),
(2,  5,  (SELECT id FROM street WHERE `name` = 'Railway Street'      LIMIT 1), 1400, 220, 0),
(1,  6,  (SELECT id FROM street WHERE `name` = 'Svobody Avenue'      LIMIT 1),  500,  80, 0),
(3,  6,  (SELECT id FROM street WHERE `name` = 'Svobody Avenue'      LIMIT 1),  650, 100, 0),
(7,  8,  (SELECT id FROM street WHERE `name` = 'Park Road'           LIMIT 1),  700, 110, 0),
-- bridges (west -> east)
(5,  13, (SELECT id FROM street WHERE `name` = 'North Bridge'        LIMIT 1),  850, 120, 1),
(6,  14, (SELECT id FROM street WHERE `name` = 'Central Bridge'      LIMIT 1),  700, 100, 1),
(7,  15, (SELECT id FROM street WHERE `name` = 'South Bridge'        LIMIT 1),  900, 130, 1),
-- east bank streets
(9,  13, (SELECT id FROM street WHERE `name` = 'East Park Road'      LIMIT 1),  800, 120, 0),
(10, 13, (SELECT id FROM street WHERE `name` = 'Terminal Street'     LIMIT 1), 1000, 150, 0),
(13, 14, (SELECT id FROM street WHERE `name` = 'Riverside Drive'     LIMIT 1),  400,  60, 0),
(9,  14, (SELECT id FROM street WHERE `name` = 'East Park Road'      LIMIT 1),  600,  90, 0),
(14, 16, (SELECT id FROM street WHERE `name` = 'Riverside Drive'     LIMIT 1),  550,  85, 0),
(15, 16, (SELECT id FROM street WHERE `name` = 'Riverside Drive'     LIMIT 1),  700, 105, 0),
(11, 15, (SELECT id FROM street WHERE `name` = 'Industrial Highway'  LIMIT 1), 1300, 200, 0),
(11, 16, (SELECT id FROM street WHERE `name` = 'Industrial Highway'  LIMIT 1),  900, 140, 0),
(10, 11, (SELECT id FROM street WHERE `name` = 'Terminal Street'     LIMIT 1), 1600, 260, 0),
(10, 12, (SELECT id FROM street WHERE `name` = 'Hilltop Road'        LIMIT 1), 1200, 190, 0),
(9,  12, (SELECT id FROM street WHERE `name` = 'Hilltop Road'        LIMIT 1), 1400, 210, 0),
(11, 12, (SELECT id FROM street WHERE `name` = 'Hilltop Road'        LIMIT 1), 1000, 160, 0);

-- ---------------------------------------------------------------------------
-- 5. Sanity checks
-- ---------------------------------------------------------------------------

-- Expect 3
SELECT COUNT(*) AS bridge_edge_count FROM road_edge WHERE is_bridge = 1;
-- Expect 6
SELECT COUNT(*) AS bridge_node_count FROM road_node WHERE is_bridge = 1;
-- Expect 0: every node must be reachable (the graph is connected)
SELECT COUNT(*) AS isolated_nodes
FROM road_node n
WHERE NOT EXISTS (
    SELECT 1 FROM road_edge e
    WHERE e.from_node_id = n.id OR e.to_node_id = n.id
);
