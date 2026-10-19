-- ============================================================================
-- road_memory_setup.sql — load the road network into MEMORY-engine tables.
--
-- Run this BEFORE searching, and again after every change of
-- road_node / road_edge (safe to run repeatedly, it drops and recreates).
--
-- Creates road_node_mem and road_edge_mem — in-memory copies of the road
-- network that the find_routes_* scripts search in.
--
-- Note: MEMORY engine cannot store POINT columns, so lon/lat are kept as
-- DOUBLE and the searches build POINT(...) on the fly for ST_Distance_Sphere.
-- ============================================================================

DROP TABLE IF EXISTS road_node_mem;
CREATE TABLE road_node_mem (
    id         INT UNSIGNED NOT NULL,
    name       VARCHAR(100) DEFAULT NULL,
    river_bank ENUM('west','east') NOT NULL,
    is_bridge  TINYINT(1) NOT NULL DEFAULT 0,
    longitude  DOUBLE DEFAULT NULL,
    latitude   DOUBLE DEFAULT NULL,
    PRIMARY KEY (id),
    KEY road_node_mem_bank_IDX (river_bank, is_bridge)
) ENGINE=MEMORY;
INSERT INTO road_node_mem (id, name, river_bank, is_bridge, longitude, latitude)
SELECT id, name, river_bank, is_bridge, longitude, latitude FROM road_node;

DROP TABLE IF EXISTS road_edge_mem;
CREATE TABLE road_edge_mem (
    id            INT UNSIGNED NOT NULL,
    from_node_id  INT UNSIGNED NOT NULL,
    to_node_id    INT UNSIGNED NOT NULL,
    distance_m    INT UNSIGNED NOT NULL,
    travel_time_s INT UNSIGNED NOT NULL,
    is_bridge     TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY road_edge_mem_from_IDX (from_node_id),
    KEY road_edge_mem_to_IDX (to_node_id)
) ENGINE=MEMORY;
INSERT INTO road_edge_mem (id, from_node_id, to_node_id, distance_m, travel_time_s, is_bridge)
SELECT id, from_node_id, to_node_id, distance_m, travel_time_s, is_bridge FROM road_edge;

SELECT (SELECT COUNT(*) FROM road_node_mem) AS nodes_loaded,
       (SELECT COUNT(*) FROM road_edge_mem) AS edges_loaded;
