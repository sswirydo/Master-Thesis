/*
  Queries on imported GTFS data notably, used for the thesis doc.
*/


SELECT mobilitydb_full_version();



/* Bus 71 Reference */

-- route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id
-- 60,250654060,116621908250654060,"DELTA",0,9207704,071b0240



/* Number of trips per route in a day */

SELECT route_id, service_id, direction_id, count(*) as c
FROM trips_mdb_day
WHERE route_id = '60' and direction_id = '0'
GROUP BY route_id, service_id, direction_id
ORDER BY c DESC LIMIT 10;



/* Average number of trips per route in a day */

SELECT 
  AVG(total),
  COUNT(service_id)
FROM 
(
  SELECT service_id, count(*) as total
  FROM trips_mdb_day
  WHERE route_id = '60' and direction_id = '0'
  GROUP BY route_id, service_id, direction_id
);



/* Checking the number of similar trips */

WITH aligned_trips AS (
  SELECT 
    startTimestamp(trip::tgeompoint) as starttime,
    (periodic_align(trip))::tgeompoint AS altrip, 
    trip_id, 
    route_id,
    direction_id,
    service_id
  FROM trips_mdb_day
), common_trips AS (
  SELECT 
    span(MIN(starttime), MAX(starttime)) as timerange,
    route_id, service_id, direction_id, 
    duration(altrip), count(*) AS total
  FROM aligned_trips
  WHERE route_id = '60' AND direction_id = '0'
  GROUP BY route_id, service_id, direction_id, altrip
  HAVING count(*) > 1
)
SELECT count(*) as total FROM common_trips WHERE service_id = '250656500' GROUP BY route_id ORDER BY total DESC LIMIT 100;
-- SELECT timerange, total FROM common_trips WHERE service_id = '250654060' ORDER BY total DESC LIMIT 100;
-- SELECT timerange, total FROM common_trips ORDER BY timerange, total DESC LIMIT 10000;
-- SELECT timerange, total FROM common_trips WHERE service_id = '250656500' ORDER BY timerange, total DESC LIMIT 10;
-- SELECT total, service_id FROM common_trips ORDER BY total DESC LIMIT 10;
-- 250654060 (WEEKDAYS)
-- 250656500 (SATURDAY)



/* Number of periodic vs. non-periodic rows */

VACUUM ANALYSE;

SELECT 'trips_mdb_classic';
SELECT count(*)
FROM trips_mdb_classic;
SELECT pg_size_pretty(pg_relation_size('trips_mdb_classic'));
SELECT pg_size_pretty(pg_table_size('trips_mdb_classic'));
SELECT pg_size_pretty (pg_total_relation_size ('trips_mdb_classic'));


SELECT 'trips_mdb_week';
SELECT count(*)
FROM trips_mdb_week;
SELECT pg_size_pretty(pg_relation_size('trips_mdb_week'));
SELECT pg_size_pretty(pg_table_size('trips_mdb_week'));
SELECT pg_size_pretty (pg_total_relation_size ('trips_mdb_week'));

SELECT 'trips_mdb_day';
SELECT count(*)
FROM trips_mdb_day;
SELECT pg_size_pretty(pg_relation_size('trips_mdb_day'));
SELECT pg_size_pretty (pg_total_relation_size ('trips_mdb_day'));

SELECT 'trips_mdb_grouped';
DROP TABLE IF EXISTS trips_mdb_grouped;
CREATE TABLE trips_mdb_grouped AS (
  WITH aligned_trips AS (
    SELECT trip_id, route_id, service_id, direction_id, (periodic_align(trip))::tgeompoint as altrip
    FROM trips_mdb_day
  )
  SELECT MIN(trip_id), route_id, service_id, direction_id, altrip
  FROM aligned_trips
  GROUP BY route_id, service_id, direction_id, altrip
);

SELECT count(*)
FROM trips_mdb_grouped;
SELECT pg_size_pretty(pg_relation_size('trips_mdb_grouped'));
SELECT pg_size_pretty (pg_total_relation_size ('trips_mdb_grouped'));

SELECT 'trip_start_times';
DROP TABLE IF EXISTS trip_start_times;
CREATE TABLE trip_start_times AS (
  SELECT trip_id, startTimestamp(trip::tgeompoint)
  FROM trips_mdb_day
);
SELECT count(*)
FROM trip_start_times;
SELECT pg_size_pretty (pg_total_relation_size ('trip_start_times'));



-- \timing on

-- SELECT trip
-- FROM trips_mdb_day
-- WHERE trip_id = '105630435191020500';

/* -------------------------------------- */
/* TRANSPORT FROM A TO B (DAY) (PERIODIC) */
/* -------------------------------------- */



-- SET enable_seqscan = off;

VACUUM ANALYSE;
EXPLAIN ANALYSE
WITH 
args AS (
  SELECT 
    ST_SetSRID(ST_MakePoint(4.372180396003406, 50.84722561466854), 4326) AS artsloi,
    ST_SetSRID(ST_MakePoint(4.398234226769904, 50.83924650473654), 4326) AS merode,
    ST_SetSRID(ST_MakePoint(4.403745097828254, 50.81836960981391), 4326) AS delta,
    ST_SetSRID(ST_MakePoint(4.382258393089591, 50.81209088981962), 4326) as solbosch,
    ST_SetSRID(ST_MakePoint(4.39626675936008, 50.81812165343881), 4326) as plaine
)

,near_routes AS (
  SELECT shape_id
  FROM shape_geoms
  WHERE ST_DWithin(shape_geom::geography, (select solbosch from args)::geography, 500)
  AND ST_DWithin(shape_geom::geography, (select plaine from args)::geography, 500)
)

-- /* Filters to trips that are near start A end end B points */
,temp_near_trips AS (
  SELECT DISTINCT
    t.trip_id,
    nearestApproachInstant(trip::tgeompoint, (select solbosch from args))::tgeogpoint AS start_point,
    nearestApproachInstant(trip::tgeompoint, (select plaine from args))::tgeogpoint AS end_point
  FROM 
    trips_mdb_day t
    INNER JOIN trips tr ON t.trip_id = tr.trip_id
  WHERE 
    tr.shape_id IN (SELECT * FROM near_routes)
)

-- /* Fitlers to trips in a 30min range from current time */
,near_trips AS (
  SELECT *
  FROM temp_near_trips
  WHERE 
    getTimestamp(start_point) < getTimestamp(end_point)
    AND start_point &&
      span('2000-01-01 12:30:00 UTC'::timestamptz, '2000-01-01 13:00:00 UTC'::timestamptz)
)

-- /* Anchors and repeats the trips to actual dates  */
, anchored_trips AS (
  SELECT
    t.trip_id, t.route_id, t.service_id,
    anchor_array(
      trip,
      span(
        c.start_date, 
        c.end_date + '1 day'::interval),
      '1 day'::interval,
      true,
      ARRAY[monday, tuesday, wednesday, thursday, friday, saturday, sunday],
      (EXTRACT(DOW FROM c.start_date::timestamptz)::int + 6) % 7
    ) as anchor_seq,
    n.start_point,
    n.end_point
  FROM 
    trips_mdb_day t
    INNER JOIN near_trips n ON t.trip_id = n.trip_id
    INNER JOIN calendar c ON t.service_id = c.service_id
)


-- /* Selects */
SELECT 
  trip_id, route_short_name, service_id,
  getTimestamp(start_point), getTimestamp(end_point)
FROM 
  anchored_trips a
  INNER JOIN routes r ON a.route_id = r.route_id
WHERE atTime(anchor_seq, span('2023-04-03 12:30:00'::timestamptz, '2023-04-03 14:00:00'::timestamptz)) IS NOT NULL 
ORDER BY getTimestamp(end_point) ASC;



/* -------------------------------------- */
/* TRANSPORT FROM A TO B (DAY) (TEMPORAL) */
/* -------------------------------------- */

VACUUM ANALYSE;
EXPLAIN ANALYSE
WITH 
args AS (
  SELECT 
    ST_SetSRID(ST_MakePoint(4.372180396003406, 50.84722561466854), 4326) AS artsloi,
    ST_SetSRID(ST_MakePoint(4.398234226769904, 50.83924650473654), 4326) AS merode,
    ST_SetSRID(ST_MakePoint(4.403745097828254, 50.81836960981391), 4326) AS delta,
    ST_SetSRID(ST_MakePoint(4.382258393089591, 50.81209088981962), 4326) as solbosch,
    ST_SetSRID(ST_MakePoint(4.39626675936008, 50.81812165343881), 4326) as plaine
)

,near_routes AS (
  SELECT shape_id
  FROM shape_geoms
  WHERE ST_DWithin(shape_geom::geography, (select solbosch from args)::geography, 500)
  AND ST_DWithin(shape_geom::geography, (select plaine from args)::geography, 500)
)

,temp_near_trips AS (
  SELECT DISTINCT
    t.trip_id,
    nearestApproachInstant(trip, (select solbosch from args))::tgeogpoint AS start_point,
    nearestApproachInstant(trip, (select plaine from args))::tgeogpoint AS end_point
  FROM 
    trips_mdb_classic t
    INNER JOIN trips tr ON t.trip_id = tr.trip_id
  WHERE 
    tr.shape_id IN (SELECT * FROM near_routes)
)

,near_trips AS (
  SELECT *
  FROM temp_near_trips
  WHERE 
    getTimestamp(start_point) < getTimestamp(end_point)
    AND start_point &&
      span('2023-04-03 13:30:00'::timestamptz, '2023-04-03 14:00:00'::timestamptz) 
    -- note that we query 1 hour later as actually the classic GTFS approach also has issues related to DST changes :D  
)

SELECT DISTINCT
  t.trip_id, r.route_short_name, t.service_id,
  getTimestamp(n.start_point), getTimestamp(n.end_point)
FROM 
  trips_mdb_classic t
  INNER JOIN near_trips n ON t.trip_id = n.trip_id
  INNER JOIN routes r ON t.route_id = r.route_id
ORDER BY getTimestamp(end_point) ASC;


-- VACUUM ANALYSE;
-- EXPLAIN ANALYSE
-- SELECT periodicValueAtTimestamp(
--   trip,
--   span(c.start_date::timestamptz, c.end_date::timestamptz),
--   '1 week'::interval,
--   '2023-04-03 14:00:00'::timestamptz
-- )
-- FROM trips_mdb_week t JOIN calendar c ON t.service_id = c.service_id;