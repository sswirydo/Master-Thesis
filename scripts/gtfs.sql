
CREATE EXTENSION MobilityDB CASCADE;


CREATE TABLE agency (
  agency_id text DEFAULT '',
  agency_name text DEFAULT NULL,
  agency_url text DEFAULT NULL,
  agency_timezone text DEFAULT NULL,
  agency_lang text DEFAULT NULL,
  agency_phone text DEFAULT NULL,
  CONSTRAINT agency_pkey PRIMARY KEY (agency_id)
);

CREATE TABLE calendar (
  service_id text,
  monday int NOT NULL,
  tuesday int NOT NULL,
  wednesday int NOT NULL,
  thursday int NOT NULL,
  friday int NOT NULL,
  saturday int NOT NULL,
  sunday int NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  CONSTRAINT calendar_pkey PRIMARY KEY (service_id)
);

CREATE INDEX calendar_service_id ON calendar (service_id);

CREATE TABLE exception_types (
  exception_type int PRIMARY KEY,
  description text
);

CREATE TABLE calendar_dates (
  service_id text,
  date date NOT NULL,
  exception_type int REFERENCES exception_types(exception_type)
);

CREATE INDEX calendar_dates_dateidx ON calendar_dates (date);

-- (optional)
-- CREATE TABLE route_types (
-- 	route_type int PRIMARY KEY,
-- 	description text
-- );

CREATE TABLE routes (
  route_id text,
  route_short_name text DEFAULT '',
  route_long_name text DEFAULT '',
  route_desc text DEFAULT '',
	route_type int, -- REFERENCES route_types(route_type),
  route_url text,
  route_color text DEFAULT '',
  route_text_color text,
  CONSTRAINT routes_pkey PRIMARY KEY (route_id)
);

CREATE TABLE shapes (
  shape_id text NOT NULL,
  shape_pt_lat double precision NOT NULL,
  shape_pt_lon double precision NOT NULL,
  shape_pt_sequence int NOT NULL,
  shape_dist_traveled text DEFAULT '' -- optional
);

CREATE INDEX shapes_shape_key ON shapes (shape_id);

-- Create a table to store the shape geometries
CREATE TABLE shape_geoms (
  shape_id text NOT NULL,
  shape_geom geometry('LINESTRING', 4326),
  CONSTRAINT shape_geom_pkey PRIMARY KEY (shape_id)
);

CREATE INDEX shape_geoms_key ON shapes (shape_id);


CREATE TABLE location_types (
  location_type int PRIMARY KEY,
  description text
);

CREATE TABLE stops (
  stop_id text,
  stop_code text,
  stop_name text DEFAULT NULL,
  stop_desc text DEFAULT NULL,
  stop_lat double precision,
  stop_lon double precision,
  zone_id text,
  stop_url text,
  location_type integer  REFERENCES location_types(location_type),
  parent_station integer,
  stop_geom geometry('POINT', 4326),
  platform_code text DEFAULT NULL,
  CONSTRAINT stops_pkey PRIMARY KEY (stop_id)
);

CREATE TABLE pickup_dropoff_types (
  type_id int PRIMARY KEY,
  description text
);

CREATE TABLE stop_times (
  trip_id text NOT NULL,
  -- Check that casting to time interval works.
  arrival_time interval CHECK (arrival_time::interval = arrival_time::interval),
  departure_time interval CHECK (departure_time::interval = departure_time::interval),
  stop_id text,
  stop_sequence int NOT NULL,
  pickup_type int REFERENCES pickup_dropoff_types(type_id),
  drop_off_type int REFERENCES pickup_dropoff_types(type_id),
  CONSTRAINT stop_times_pkey PRIMARY KEY (trip_id, stop_sequence)
);
CREATE INDEX stop_times_key ON stop_times (trip_id, stop_id);
CREATE INDEX arr_time_index ON stop_times (arrival_time);
CREATE INDEX dep_time_index ON stop_times (departure_time);

CREATE TABLE trips (
  route_id text NOT NULL,
  service_id text NOT NULL,
  trip_id text NOT NULL,
  trip_headsign text,
  direction_id int,
  block_id text,
  shape_id text,
  CONSTRAINT trips_pkey PRIMARY KEY (trip_id)
);
CREATE INDEX trips_trip_id ON trips (trip_id);


INSERT INTO exception_types (exception_type, description) VALUES
(1, 'service has been added'),
(2, 'service has been removed');

INSERT INTO location_types(location_type, description) VALUES
(0,'stop'),
(1,'station'),
(2,'station entrance');

INSERT INTO pickup_dropoff_types (type_id, description) VALUES
(0,'Regularly Scheduled'),
(1,'Not available'),
(2,'Phone arrangement only'),
(3,'Driver arrangement only');


-- MARCH 2023 GTFS
-------> TODO update paths with your owns
COPY calendar(service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date) 
  FROM '/home/szymon/Master-Thesis/data/gtfs/calendar.txt' DELIMITER ',' CSV HEADER;
COPY calendar_dates(service_id,date,exception_type)
  FROM '/home/szymon/Master-Thesis/data/gtfs/calendar_dates.txt' DELIMITER ',' CSV HEADER;
COPY stop_times(trip_id,arrival_time,departure_time,stop_id,stop_sequence,pickup_type,drop_off_type) 
  FROM '/home/szymon/Master-Thesis/data/gtfs/stop_times.txt' DELIMITER ',' CSV HEADER;
COPY trips(route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id)
  FROM '/home/szymon/Master-Thesis/data/gtfs/trips.txt' DELIMITER ',' CSV HEADER;
COPY agency(agency_id,agency_name,agency_url,agency_timezone,agency_lang,agency_phone)
  FROM '/home/szymon/Master-Thesis/data/gtfs/agency.txt' DELIMITER ',' CSV HEADER;
COPY routes(route_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color)
  FROM '/home/szymon/Master-Thesis/data/gtfs/routes.txt' DELIMITER ',' CSV HEADER;
COPY shapes(shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence)
  FROM '/home/szymon/Master-Thesis/data/gtfs/shapes.txt' DELIMITER ',' CSV HEADER;
COPY stops(stop_id,stop_code,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station)
  FROM '/home/szymon/Master-Thesis/data/gtfs/stops.txt' DELIMITER ',' CSV HEADER;

-- JULY 2024 GTFS
-- COPY calendar(service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date) 
--   FROM '/home/szymon/Master-Thesis/data/other/gtfs75/calendar.txt' DELIMITER ',' CSV HEADER;
-- COPY calendar_dates(service_id,date,exception_type)
--   FROM '/home/szymon/Master-Thesis/data/other/gtfs75/calendar_dates.txt' DELIMITER ',' CSV HEADER;
-- COPY stop_times(trip_id,arrival_time,departure_time,stop_id,stop_sequence,pickup_type,drop_off_type) 
--   FROM '/home/szymon/Master-Thesis/data/other/gtfs75/stop_times.txt' DELIMITER ',' CSV HEADER;
-- COPY trips(route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id)
--   FROM '/home/szymon/Master-Thesis/data/other/gtfs75/trips.txt' DELIMITER ',' CSV HEADER;
-- COPY agency(agency_id,agency_name,agency_url,agency_timezone,agency_lang,agency_phone)
--   FROM '/home/szymon/Master-Thesis/data/other/gtfs75/agency.txt' DELIMITER ',' CSV HEADER;
-- COPY routes(route_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color)
--   FROM '/home/szymon/Master-Thesis/data/other/gtfs75/routes.txt' DELIMITER ',' CSV HEADER;
-- COPY shapes(shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence, shape_dist_traveled)
--   FROM '/home/szymon/Master-Thesis/data/other/gtfs75/shapes.txt' DELIMITER ',' CSV HEADER;
-- COPY stops(stop_id,stop_code,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station)
--   FROM '/home/szymon/Master-Thesis/data/other/gtfs75/stops.txt' DELIMITER ',' CSV HEADER;


-- WORKSHOP METRO 1 WEEK REDUCED GTFS
-- COPY calendar(service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date) 
--   FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/calendar.txt' DELIMITER ',' CSV HEADER;
-- COPY calendar_dates(service_id,date,exception_type)
--   FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/calendar_dates.txt' DELIMITER ',' CSV HEADER;
-- COPY stop_times(trip_id,arrival_time,departure_time,stop_id,stop_sequence,pickup_type,drop_off_type) 
--   FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/stop_times.txt' DELIMITER ',' CSV HEADER;
-- COPY trips(route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id)
--   FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/trips.txt' DELIMITER ',' CSV HEADER;
-- COPY agency(agency_id,agency_name,agency_url,agency_timezone,agency_lang,agency_phone)
--   FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/agency.txt' DELIMITER ',' CSV HEADER;
-- COPY routes(route_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color)
--   FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/routes.txt' DELIMITER ',' CSV HEADER;
-- COPY shapes(shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence)
--   FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/shapes.txt' DELIMITER ',' CSV HEADER;
-- COPY stops(stop_id,stop_code,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station)
--   FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/stops.txt' DELIMITER ',' CSV HEADER;

-- /* Artificially increase workshop service end_date for debugging. (less time consuming than other gtfs) */
-- UPDATE calendar
--   SET end_date = end_date + INTERVAL '3 week';


/* Counting service date range */ 
SELECT
  CASE
    WHEN
      (end_date + INTERVAL '1 day') - start_date <= INTERVAL '1 week' 
      THEN '<=1W'
    WHEN
      (end_date + INTERVAL '1 day') - start_date <= INTERVAL '2 week' AND
      (end_date + INTERVAL '1 day') - start_date > INTERVAL '1 week'
      THEN '<=2W'
    WHEN
      (end_date + INTERVAL '1 day') - start_date <= INTERVAL '3 week' AND
      (end_date + INTERVAL '1 day') - start_date > INTERVAL '2 week'
      THEN '<=3W'
    WHEN
      (end_date + INTERVAL '1 day') - start_date <= INTERVAL '4 week' AND
      (end_date + INTERVAL '1 day') - start_date > INTERVAL '3 week'
      THEN '<=4W'
    ELSE '>4W'
  END AS range_bucket,
  COUNT(*) as count
FROM calendar c JOIN trips t ON c.service_id = t.service_id
GROUP BY range_bucket;

SELECT count(*)
FROM calendar c JOIN trips t ON c.service_id = t.service_id;



/* Transforming lon/lat point data into postGIS geometries */
INSERT INTO shape_geoms
SELECT 
  shape_id, 
  ST_MakeLine(
    array_agg(
      ST_SetSRID(ST_MakePoint(shape_pt_lon, shape_pt_lat), 4326)
      ORDER BY shape_pt_sequence)
    )
FROM shapes
GROUP BY shape_id;

UPDATE stops
SET stop_geom = ST_SetSRID(ST_MakePoint(stop_lon, stop_lat), 4326);



CREATE TABLE periodic_dates AS (
  SELECT service_id, date_trunc('day', d)::date AS date
    FROM calendar c, generate_series('2000-01-01'::date, '2000-01-07'::date, '1 day'::interval) AS d
    WHERE (
      (monday = 1 AND d = '2000-01-01') OR
      (tuesday = 1 AND d = '2000-01-02') OR
      (wednesday = 1 AND d = '2000-01-03') OR
      (thursday = 1 AND d = '2000-01-04') OR
      (friday = 1 AND d = '2000-01-05') OR
      (saturday = 1 AND d = '2000-01-06') OR
      (sunday = 1 AND d = '2000-01-07')
    )
);

CREATE TABLE service_dates AS (
  SELECT service_id, date_trunc('day', d)::date AS date
    FROM calendar c, generate_series(start_date, end_date, '1 day'::interval) AS d
    WHERE (
      (monday = 1 AND extract(isodow FROM d) = 1) OR
      (tuesday = 1 AND extract(isodow FROM d) = 2) OR
      (wednesday = 1 AND extract(isodow FROM d) = 3) OR
      (thursday = 1 AND extract(isodow FROM d) = 4) OR
      (friday = 1 AND extract(isodow FROM d) = 5) OR
      (saturday = 1 AND extract(isodow FROM d) = 6) OR
      (sunday = 1 AND extract(isodow FROM d) = 7)
    )
  EXCEPT
    SELECT service_id, date
      FROM calendar_dates WHERE exception_type = 2
    UNION
    SELECT c.service_id, date
      FROM calendar c JOIN calendar_dates d ON c.service_id = d.service_id
      WHERE exception_type = 1 AND start_date <= date AND date <= end_date
);



CREATE TABLE trip_stops (
  trip_id text,
  direction_id text,
  stop_sequence integer,
  no_stops integer,
  route_id text,
  service_id text,
  shape_id text,
  stop_id text,
  arrival_time interval,
  perc float
);
INSERT INTO trip_stops (trip_id, stop_sequence, no_stops, route_id, service_id, shape_id, stop_id, arrival_time)
  SELECT t.trip_id, stop_sequence, MAX(stop_sequence) OVER (PARTITION BY t.trip_id), route_id, service_id, shape_id, stop_id, arrival_time
  FROM trips t JOIN stop_times s ON t.trip_id = s.trip_id;
UPDATE trip_stops t
  SET perc = 
    CASE
      WHEN stop_sequence = 1 then 0.0
      WHEN stop_sequence = no_stops then 1.0
      ELSE ST_LineLocatePoint(g.shape_geom, s.stop_geom)
    END
  FROM shape_geoms g, stops s
  WHERE t.shape_id = g.shape_id AND t.stop_id = s.stop_id;


-- 1: current stop
-- 2: next stop (lead)
CREATE TABLE trip_segs (
  trip_id text,
  route_id text,
  service_id text,
  stop1_sequence integer,
  stop2_sequence integer,
  no_stops integer,
  shape_id text,
  stop1_arrival_time interval,
  stop2_arrival_time interval,
  perc1 float,
  perc2 float,
  seg_geom geometry,
  seg_length float,
  no_points integer,
  PRIMARY KEY (trip_id, stop1_sequence)
);


/* Basically, creates LINES between current and next stop */
INSERT INTO trip_segs (trip_id, route_id, service_id, stop1_sequence, stop2_sequence, no_stops, shape_id, stop1_arrival_time, stop2_arrival_time, perc1, perc2)
  WITH temp AS (
    SELECT trip_id, route_id, service_id, stop_sequence as stop_sequence1,
    LEAD(stop_sequence) OVER w AS stop_sequence2,
    MAX(stop_sequence) OVER (PARTITION BY trip_id) as no_stops,
    shape_id, arrival_time as stop1_arrival_time, 
    LEAD(arrival_time) OVER w as stop2_arrival_time, 
    perc as perc1, 
    LEAD(perc) OVER w as perc2
    FROM trip_stops WINDOW w AS (PARTITION BY trip_id ORDER BY stop_sequence)
  )
  SELECT * 
    FROM temp 
    WHERE stop_sequence2 IS NOT null;

  UPDATE trip_segs t
    SET seg_geom = ST_LineSubstring(g.shape_geom, perc1, perc2)
    FROM shape_geoms g
    WHERE t.shape_id = g.shape_id;

  UPDATE trip_segs
    SET seg_length = ST_Length(seg_geom), no_points = ST_NumPoints(seg_geom);


/* Extracts points from segments (simplifies segments into points) */
CREATE TABLE trip_points (
	trip_id text,
	route_id text,
	service_id text,
	stop1_sequence integer,
	point_sequence integer,
	point_geom geometry,
	point_arrival_time interval,
	PRIMARY KEY (trip_id, stop1_sequence, point_sequence)
);


-- temp1: does ST_DumpPoints and adds point_sequence (dump.path) and point_geom (dump.geom)
-- temp2: filters temp1 from excessive duplicate points, unless its the last segment
-- temp3: computes perc position of point on segment
-- select: computes arrival_time per point based on perc
INSERT INTO trip_points (trip_id, route_id, service_id, stop1_sequence, point_sequence, point_geom, point_arrival_time)
  WITH temp1 AS (
    SELECT trip_id, route_id, service_id, stop1_sequence, stop2_sequence, no_stops, stop1_arrival_time, stop2_arrival_time, seg_length,
    (dp).path[1] AS point_sequence, no_points, (dp).geom as point_geom
    FROM trip_segs, ST_DumpPoints(seg_geom) AS dp
  ),
  temp2 AS (
    SELECT trip_id, route_id, service_id, stop1_sequence, stop1_arrival_time, stop2_arrival_time, seg_length, point_sequence, no_points, point_geom
    FROM temp1
    WHERE point_sequence <> no_points OR stop2_sequence = no_stops
  ),
  temp3 AS (
    SELECT trip_id, route_id, service_id, stop1_sequence, stop1_arrival_time, stop2_arrival_time, point_sequence, no_points, point_geom,
    ST_Length(ST_MakeLine(array_agg(point_geom) OVER w)) / seg_length AS perc
    FROM temp2 WINDOW w AS (PARTITION BY trip_id, service_id, stop1_sequence
    ORDER BY point_sequence)
  )
  SELECT trip_id, route_id, service_id, stop1_sequence, point_sequence, point_geom,
    CASE
    WHEN point_sequence = 1 then stop1_arrival_time
    WHEN point_sequence = no_points then stop2_arrival_time
    ELSE stop1_arrival_time + ((stop2_arrival_time - stop1_arrival_time) * perc)
    END AS point_arrival_time
    FROM temp3;


-- note: only contains the first date of the trip 
CREATE TABLE trips_input (
	trip_id text,
	route_id text,
	service_id text,
	date date,
	point_geom geometry,
	t timestamptz -- <--- problem: as it is ts with time zone there are shifts in arrival_times: specify UTC
);
INSERT INTO trips_input
  SELECT trip_id, route_id, t.service_id, date, point_geom, (date + point_arrival_time) AT TIME ZONE 'UTC' AS t
  FROM trip_points t JOIN
  ( SELECT service_id, MIN(date) AS date FROM periodic_dates GROUP BY service_id) s
  ON t.service_id = s.service_id;

CREATE TABLE trips_input_classic (
	trip_id text,
	route_id text,
	service_id text,
	date date,
	point_geom geometry,
	t timestamptz
);
INSERT INTO trips_input_classic
  SELECT trip_id, route_id, t.service_id, date, point_geom, date + point_arrival_time AS t
  FROM trip_points t JOIN
  ( SELECT service_id, MIN(date) AS date FROM service_dates GROUP BY service_id) s
  ON t.service_id = s.service_id;

/* 
 * Removing duplicate timestamps 
 * cause God decided to add 
 * floating point precision problems
 * into this world.
 */
DELETE FROM trips_input WHERE
 (trip_id, t) IN (
  SELECT trip_id, t
  FROM trips_input
  GROUP BY trip_id, t
  HAVING count(*) > 1
 )
 AND ctid NOT IN (
  SELECT min(ctid)
  FROM trips_input
  GROUP BY trip_id, t
  HAVING count(*) > 1
);

DELETE FROM trips_input_classic WHERE
 (trip_id, t) IN (
  SELECT trip_id, t
  FROM trips_input_classic
  GROUP BY trip_id, t
  HAVING count(*) > 1
 )
 AND ctid NOT IN (
  SELECT min(ctid)
  FROM trips_input_classic
  GROUP BY trip_id, t
  HAVING count(*) > 1
);


/* DEBUG: lists trajectories with duplicate timestamps */
-- SELECT trip_id, t, count(*) FROM trips_input GROUP BY trip_id, t HAVING count(*) > 1;



CREATE TABLE trips_mdb (
	trip_id text NOT NULL,
  direction_id text NOT NULL,
	service_id text NOT NULL,
	route_id text NOT NULL,
	date date NOT NULL,
	trip tgeompoint,
	PRIMARY KEY (trip_id, date)
);
INSERT INTO trips_mdb(trip_id, direction_id, service_id, route_id, date, trip)
  SELECT ti.trip_id, tr.direction_id, ti.service_id, ti.route_id, date, tgeompointSeq(array_agg(tgeompoint(ti.point_geom, ti.t) ORDER BY T))
  FROM trips_input ti JOIN trips tr ON ti.trip_id = tr.trip_id
  GROUP BY ti.trip_id, tr.direction_id, ti.service_id, ti.route_id, ti.date;


CREATE TABLE trips_mdb_classic (
  trip_id text NOT NULL,
  direction_id text NOT NULL,
  route_id text NOT NULL,
  service_id text NOT NULL,
  date date NOT NULL,
  trip tgeompoint,
  PRIMARY KEY (trip_id, date)
);
INSERT INTO trips_mdb_classic(trip_id, direction_id, service_id, route_id, date, trip)
  SELECT ti.trip_id, tr.direction_id, ti.service_id, ti.route_id, date, tgeompointSeq(array_agg(tgeompoint(ti.point_geom, ti.t) ORDER BY T))
  FROM trips_input_classic ti JOIN trips tr ON ti.trip_id = tr.trip_id
  GROUP BY ti.trip_id, tr.direction_id, ti.service_id, ti.route_id, ti.date;

INSERT INTO trips_mdb_classic(trip_id, direction_id, service_id, route_id, date, trip)
  SELECT trip_id, direction_id, t.service_id, route_id, d.date, shiftTime(trip, make_interval(days => d.date - t.date))
  FROM trips_mdb_classic t JOIN service_dates d ON t.service_id = d.service_id AND t.date <> d.date;



/* Day-style format 
 * Requires a more complex anchor / repeat behavior 
 * (e.g., repeat every day except on weekends)
 */
CREATE TABLE trips_mdb_day AS
SELECT trip_id, direction_id, service_id, route_id, date, setPeriodicType(trip::pgeompoint, 'day') as trip FROM trips_mdb;

/* Shifting all trajectories of _day table to 2000-01-01 date */
UPDATE trips_mdb_day
  SET trip = shiftTime(trip::tgeompoint, (age('2000-01-01'::date, date)))::pgeompoint
  WHERE date >= '2000-01-02'::date;
ALTER TABLE trips_mdb_day DROP COLUMN "date";


/* Week-style format
 * Periodic but note that trips might be duplicated at most 7 times
 * for each different day_of_week of service.
 */
CREATE TABLE trips_mdb_week AS
SELECT trip_id, direction_id, service_id, route_id, date, setPeriodicType(trip::pgeompoint, 'week') as trip FROM trips_mdb;


/* DEBUG: Checks how many similar trips are there */
-- WITH aligned_trips AS (
--   SELECT 
--     (periodic_align(trip))::tgeompoint as altrip, 
--     trip_id, 
--     route_id,
--     direction_id,
--     service_id
--   FROM trips_mdb_week
-- ), specific_trips AS (
--   SELECT route_id, service_id, direction_id, duration(altrip), count(*) as cnt
--   FROM aligned_trips
--   GROUP BY route_id, service_id, direction_id, altrip
--   HAVING count(*) = 1
-- ), common_trips AS (
--   SELECT route_id, service_id, direction_id, duration(altrip), count(*) as cnt
--   FROM aligned_trips
--   GROUP BY route_id, service_id, direction_id, altrip
--   HAVING count(*) > 1
-- )
-- SELECT count(*) FROM specific_trips;
-- SELECT * FROM common_trips ORDER BY cnt DESC LIMIT 10;



/* Repeats trips fro each service day of week */ 
INSERT INTO trips_mdb_week("trip_id", "direction_id", "service_id", "route_id", "date", "trip")
  SELECT 
    trip_id as trip_id,
    direction_id as direction_id,
    t.service_id as service_id,
    route_id as route_id,
    d.date as date,
    shiftTime(trip::tgeompoint, make_interval(days => d.date - t.date))::pgeompoint as trip
  FROM 
    trips_mdb_week t 
    JOIN periodic_dates d
      ON t.service_id = d.service_id 
      AND t.date <> d.date;


/*
 * Because c.start_date is NOT necessarily a Monday,
 * first, before anchoring,
 * we cyclically shift the sequences such that relative Mon corresponds
 * to start_date day of week.
 */
CREATE TABLE trips_mdb_week_shifted AS
SELECT trip_id, direction_id, service_id, route_id, date, trip FROM trips_mdb_week;
UPDATE trips_mdb_week_shifted t
  SET trip =
    CASE
      WHEN 
        ((EXTRACT(DOW FROM t.date::timestamp)::int + 1) % 7) < ((EXTRACT(DOW FROM c.start_date::timestamp)::int + 6) % 7)
      THEN
        shiftTime(
          trip::tgeompoint,
          make_interval(days => 7 - ((EXTRACT(DOW FROM c.start_date::timestamp)::int + 6) % 7))
        )::pgeompoint
      ELSE
        shiftTime(
          trip::tgeompoint,
          make_interval(days => 0 - ((EXTRACT(DOW FROM c.start_date::timestamp)::int + 6) % 7))
        )::pgeompoint
      END
  FROM calendar c
  WHERE t.service_id = c.service_id;
UPDATE trips_mdb_week_shifted t
  SET date =
    CASE
      WHEN 
        ((EXTRACT(DOW FROM t.date::timestamp)::int + 1) % 7) < ((EXTRACT(DOW FROM c.start_date::timestamp)::int + 6) % 7)
      THEN
        t.date + make_interval(days => 7 - ((EXTRACT(DOW FROM c.start_date::timestamp)::int + 6) % 7))
      ELSE
        t.date + make_interval(days => 0 - ((EXTRACT(DOW FROM c.start_date::timestamp)::int + 6) % 7))
      END
  FROM calendar c
  WHERE t.service_id = c.service_id;

