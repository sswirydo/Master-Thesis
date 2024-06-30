
/** APPROACHES

- isolate gtfs per trip, construct geometires, transform into mobilitydb etc.
but do not join with calendar dates as those are repetitive

- construct a repetition tree for mobilitydb trips that will simplify the storage / the size of the trips
..but what about analysis them later?

*/


/** QUESTIONS

- any reason to use intervals over timestamps for arrival times ?

- can geometries, segments.. be different for each trip or are they always the same per service?
if they are the same perhaps we can compute the geometry once per service rather than per trip
* answer: geometires are per trips as some trips inside a service might be shorter or longer (e.g. return to warehouse)

- do we really need to create segment point for mobilitydb? aren't stops and times sufficient? cannot mobilitydb interpolate those points itself?


*/



/** PROBLEMS (dates)

- we have to get rid of EXCEPT calendar_dates (?) at least for now,
  as our goal is to create a 1-week sequence that will repeat itself, not the full sequence
  BUT still keep / build an exception list somewhere in order to filter results later 

- instead of generating a series from start date to end date
  generate a series from periodic monday to periodic sunday 
  i.e. from 2000-01-01 to 2000-01-07 (included) (a priori it shouldnt matter that 01-01 is actually a saturday)

- but what if start date is not a monday ?
  what if it starts (start_date) at thursday and continues on monday etc. ?
  -> don't generate series from start_date
  start_date and end_dates will be important for anchoring and operations
  here we only care about the monday to sunday pattern

*/




/** TODOS

- trips_mdb contains (trip tgeompoint), transform into (trip pgeompoint)
- requires tgeompointSeq -> quickly add a pgeompointSeq equivalent
- trips_mdb stores : trip_id, service_id, route_id -> check if we can aggregate per service rather par each individual trip
  answer: we can have multiple trips running concurrently so the answer is we do it per trip
  -> should we do some sort of ([tripA1, ..., tripAi], timestamp) for each trip running simultanously?
  -> e.g. if we want to check which trip is running the nearest to a certain point at a certain timestamp later in time? 
  -> probably just group together per service + discard all not running at the given timestamp + check which is nearest amongst remaining

*/






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
CREATE TABLE route_types (
	route_type int PRIMARY KEY,
	description text
);

CREATE TABLE routes (
  route_id text,
  route_short_name text DEFAULT '',
  route_long_name text DEFAULT '',
  route_desc text DEFAULT '',
	route_type int REFERENCES route_types(route_type),
  route_url text,
  route_color text,
  route_text_color text,
  CONSTRAINT routes_pkey PRIMARY KEY (route_id)
);

CREATE TABLE shapes (
  shape_id text NOT NULL,
  shape_pt_lat double precision NOT NULL,
  shape_pt_lon double precision NOT NULL,
  shape_pt_sequence int NOT NULL
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



-- COPY calendar(service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date) 
--   FROM '/home/szymon/Master-Thesis/data/gtfs/calendar.txt' DELIMITER ',' CSV HEADER;
-- COPY calendar_dates(service_id,date,exception_type)
--   FROM '/home/szymon/Master-Thesis/data/gtfs/calendar_dates.txt' DELIMITER ',' CSV HEADER;
-- COPY stop_times(trip_id,arrival_time,departure_time,stop_id,stop_sequence,pickup_type,drop_off_type) 
--   FROM '/home/szymon/Master-Thesis/data/gtfs/stop_times.txt' DELIMITER ',' CSV HEADER;
-- COPY trips(route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id)
--   FROM '/home/szymon/Master-Thesis/data/gtfs/trips.txt' DELIMITER ',' CSV HEADER;
-- COPY agency(agency_id,agency_name,agency_url,agency_timezone,agency_lang,agency_phone)
--   FROM '/home/szymon/Master-Thesis/data/gtfs/agency.txt' DELIMITER ',' CSV HEADER;
-- COPY route_types(route_type,description)
--   FROM '/home/szymon/Master-Thesis/data/gtfs/route_types.txt' DELIMITER ',' CSV HEADER;
-- COPY routes(route_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color)
--   FROM '/home/szymon/Master-Thesis/data/gtfs/routes.txt' DELIMITER ',' CSV HEADER;
-- COPY shapes(shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence)
--   FROM '/home/szymon/Master-Thesis/data/gtfs/shapes.txt' DELIMITER ',' CSV HEADER;
-- COPY stops(stop_id,stop_code,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station)
--   FROM '/home/szymon/Master-Thesis/data/gtfs/stops.txt' DELIMITER ',' CSV HEADER;

COPY calendar(service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date) 
  FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/calendar.txt' DELIMITER ',' CSV HEADER;
COPY calendar_dates(service_id,date,exception_type)
  FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/calendar_dates.txt' DELIMITER ',' CSV HEADER;
COPY stop_times(trip_id,arrival_time,departure_time,stop_id,stop_sequence,pickup_type,drop_off_type) 
  FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/stop_times.txt' DELIMITER ',' CSV HEADER;
COPY trips(route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id)
  FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/trips.txt' DELIMITER ',' CSV HEADER;
COPY agency(agency_id,agency_name,agency_url,agency_timezone,agency_lang,agency_phone)
  FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/agency.txt' DELIMITER ',' CSV HEADER;
COPY route_types(route_type,description) --  not needed?
  FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/route_types.txt' DELIMITER ',' CSV HEADER;
COPY routes(route_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color)
  FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/routes.txt' DELIMITER ',' CSV HEADER;
COPY shapes(shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence)
  FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/shapes.txt' DELIMITER ',' CSV HEADER;
COPY stops(stop_id,stop_code,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station)
  FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/stops.txt' DELIMITER ',' CSV HEADER;


-- transforming lon/lat data into postGIS geometries
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

-- CREATE TABLE service_dates AS (
--   SELECT service_id, date_trunc('day', d)::date AS date
--     FROM calendar c, generate_series(start_date, end_date, '1 day'::interval) AS d
--     WHERE (
--       (monday = 1 AND extract(isodow FROM d) = 1) OR
--       (tuesday = 1 AND extract(isodow FROM d) = 2) OR
--       (wednesday = 1 AND extract(isodow FROM d) = 3) OR
--       (thursday = 1 AND extract(isodow FROM d) = 4) OR
--       (friday = 1 AND extract(isodow FROM d) = 5) OR
--       (saturday = 1 AND extract(isodow FROM d) = 6) OR
--       (sunday = 1 AND extract(isodow FROM d) = 7)
--     )
--   EXCEPT
--     SELECT service_id, date
--       FROM calendar_dates WHERE exception_type = 2
--     UNION
--     SELECT c.service_id, date
--       FROM calendar c JOIN calendar_dates d ON c.service_id = d.service_id
--       WHERE exception_type = 1 AND start_date <= date AND date <= end_date
-- );



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

-- basically creates LINES between current and next stop
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


-- extracts points from segments (simplifies segments into points)
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

-- SELECT trip_id,
-- 	route_id,
-- 	service_id,
-- 	stop1_sequence,
-- 	point_sequence,
-- 	ST_AsText(point_geom),
-- 	point_arrival_time
-- FROM trip_points
-- ORDER BY service_id, trip_id
-- LIMIT 50;



-- note: only contains the first date of the trip 
CREATE TABLE trips_input (
	trip_id text,
	route_id text,
	service_id text,
	date date,
	point_geom geometry,
	t timestamptz
);
INSERT INTO trips_input
  SELECT trip_id, route_id, t.service_id, date, point_geom, date + point_arrival_time AS t
  FROM trip_points t JOIN
  ( SELECT service_id, MIN(date) AS date FROM periodic_dates GROUP BY service_id) s
  ON t.service_id = s.service_id;


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

-- UPDATE trips_mdb SET trip = shiftTime(trip, '2 weeks');

-- day format would require a more complex repeat behavior (repeat every day except on weekends)
CREATE TABLE trips_mdb_day AS
SELECT trip_id, direction_id, service_id, route_id, date, setPeriodicType(trip::pgeompoint, 'day') as trip FROM trips_mdb;

-- some trips may be repeated (at most 7 times)
CREATE TABLE trips_mdb_week AS
SELECT trip_id, direction_id, service_id, route_id, date, setPeriodicType(trip::pgeompoint, 'week') as trip FROM trips_mdb;



-- REPEATS DATES OVER THERE
-- INSERT INTO trips_mdb(trip_id, service_id, route_id, date, trip)
--   SELECT trip_id, route_id, t.service_id, d.date,
--     shiftTime(trip, make_interval(days => d.date - t.date))
--   FROM trips_mdb t JOIN service_dates d ON t.service_id = d.service_id AND t.date <> d.date;

-- REPEATS A TRIP FOR EACH DAY OF WEEK THE SERVICE RUNS
-- e.g. from only (Mon) to (Mon, Tue, Wed, Thu, Fri)

SELECT route_id, service_id, date, direction_id, count(*) FROM trips_mdb_week
GROUP BY route_id, service_id, date, direction_id
ORDER BY route_id, service_id, direction_id, date;
-- route_id|1
-- service_id|200039050
-- date|2000-01-01
-- direction_id|0
-- count|175

SELECT 2+2;

SELECT route_id, direction_id, count(*) FROM trips_mdb_week
GROUP BY route_id, direction_id
ORDER BY route_id;


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



SELECT trip_id, direction_id, service_id, route_id, date, asText(trip::tgeompoint)
FROM trips_mdb_week
WHERE trip_id = '106624048200039050'
ORDER BY date;



-- SELECT 10+1;
-- SELECT * FROM periodic_dates d WHERE service_id = '200039050'; 
-- SELECT 10+2;

-- SELECT anchor(trip, pmode('1 week', 1000, true, '[2024-06-01, 2024-06-30]')) as result
-- FROM trips_mdb_week
-- WHERE trip_id = '106624048200039050';
 
-- SELECT anchor(trip, pmode('1 week'::interval, NULL, true, span(c.start_date, c.end_date, true, true)::tstzspan))
-- FROM trips_mdb_week t
-- JOIN calendar c ON t.service_id = c.service_id
-- WHERE trip_id = '106624048200039050';


-- SELECT anchor(trip, pmode('1 week', 0, true, '[2019-11-01, 2019-12-01]'))
-- CREATE VIEW final_sequences AS
--   WITH anchored_trips1 AS (
--     SELECT 
--       trip_id, direction_id, service_id, route_id, -- date,
--       anchor(trip, pmode('1 week', 0, true, tstzspan(cal.start_date, cal.end_date))) as trip
--     FROM trips_mdb_week mdb JOIN calendar cal ON mdb.service_id = cal.service_id
--   WHERE service_id = '200039050' AND trip_id = '106624048200039050'
--   ),
--   WITH anchored_trips2 AS (
--     SELECT
--       trip_id, direction_id, service_id, route_id,
--       startTimestamp(trip),
--       trip
--     FROM anchored_trips1
--   ),
--   WITH 
  







/*****************************************************************************
 *  ARCHIVES
*****************************************************************************/



-- SELECT distinct date
-- FROM trips_mdb
-- ORDER BY date ASC;
--     date
-- ------------
--  2000-01-01
--  2000-01-06
--  2000-01-07

-- SELECT trip
-- FROM trips_mdb
-- LIMIT 1;
-- SELECT getTime(trip) as ts
-- FROM trips_mdb
-- LIMIT 1;
-- ...
-- ts|{[2000-01-07 23:22:28+01, 2000-01-07 23:56:58+01]}
-- ts|{[2000-01-07 23:23:14+01, 2000-01-07 23:41:53+01]}
-- ts|{[2000-01-07 23:24:00+01, 2000-01-08 00:03:00+01]}
-- ts|{[2000-01-07 23:25:10+01, 2000-01-07 23:46:47+01]}
-- ts|{[2000-01-07 23:28:24+01, 2000-01-08 00:03:16+01]}
-- ts|{[2000-01-07 23:29:56+01, 2000-01-07 23:55:23+01]}
-- ...
--
-- FIXME: timestamps going over to 2000-01-08; > 1 week repetition
-- we could loop it and mark it as 2000-01-01, but then we would have 2000-01-07 < 2000-01-01 which can not happen
-- SOLUTION?
-- shift start time to 00:00:00; but then we would need to store additional shift else where, but it would be troublesome to compare periodics one to another
-- ACTUALLY
-- does it really matter that we have 2000-01-08?
-- if the start_time and end_time interval > 1 week we should be able to loop the sequence which is OK
-- IMPORTANT
-- 2000-01-01 00:00:00 is the reference point for anchoring, NOT for repeting the sequence; its reference is the first timestamp of the sequence
--
-- NOTE+FIXME:
-- shouldn't (/can) timestamps be in [2000-01-01, 2000-01-02] rather than [2000-01-01, 2000-01-08]?


-- SELECT distinct date
-- FROM trips_mdb
-- ORDER BY date ASC;
--     date
-- ------------
--  2000-01-01
--  2000-01-06
--  2000-01-07
--  2019-10-28
--  2019-10-29
--  2019-10-30
--  2019-10-31
--  2019-11-01
--  2019-11-02
--  2019-11-03

-- with temp_1 as (
--     select trip from trips_mdb limit 3
-- ), temp_2 as (
--     select (st_dump(geometry(shiftTime(trip,
--             localtime - (current_time at time zone 'utc')::time), true))).geom as geom
--     from temp_1
-- )
-- select
--     row_number() over () as id,
--     geom,
--     to_timestamp(st_m(st_startpoint(geom))) at time zone 'gmt' as start_t,
--     to_timestamp(st_m(st_endpoint(geom))) at time zone 'gmt' as end_t
-- from temp_2;


-- SELECT ST_Intersects('POINT(0 0)'::geometry, 'LINESTRING ( 0 0, 0 2 )'::geometry);


-- SELECT SRID(trip) FROM trips_mdb LIMIT 10; 


-- select *
-- from calendar_transformed
-- order by service_id
-- limit 1000;

-- SELECT *
-- FROM shape_geoms
-- ORDER BY shape_id
-- LIMIT 20;

-- SELECT * 
-- FROM stop_times 
-- ORDER BY trip_id, arrival_time
-- LIMIT 10;


-- Checks if there exist a seg_geom that is different for the same service_id but different trip_id
-- Answer: yes. For instance if the metro line 5 stop at delta (warehouse) to end its work day
-- SELECT *
-- FROM trip_segs t1 CROSS JOIN trip_segs t2
-- WHERE t1.service_id = t2.service_id
--   AND t1.trip_id != t2.trip_id
--   AND t1.stop1_sequence = t2.stop1_sequence
--   AND NOT ST_Equals(t1.seg_geom, t2.seg_geom)
-- ORDER BY t1.service_id, t1.trip_id
-- LIMIT 10;

/*
QUESTION, DO WE REALLY NEED TO CREATE THOSE SEGMENTED LINES FOR TEMPORALS? 
ARENT (stop_id, arrival_time) SUFFICIENT FOR ANALYSIS ? (tint)
I GUESS BOTH COULD WORK ?
BUT WHAT IS THE ADVANTAGE OF USING LINE STRINGS DIRECTLY ?
PERHAPS BY CREATING TEMPORALS, WE LOSE THE GEOGRAPHY INFORMATION?

ACTUALLY. A DISADVENTAGE OF tint IS THAT WE CANNOT INTERPOLATE
WHERAS IT IS POSSIBLE USING GEOMETRIES

BUT, ARENT TRIP POINT SUFFICIENT IN THAT CASE ? DO WE REALLY WANT/NEED TO CREATE LINE SEGMENTS?
MOREOVER, NOTE THAT THOSE LINES DONT (a priori) FOLLOW THE ACTUAL STREETS. 
(perhaps they do, I don't know if this is already implemented in mobilitydb, investigate)
WAIT
BUT WE ARE GIVEN ROUTE SHAPES THAT ACTUALLY CONTAIN THOSE -> MAPPING TO STREETS IS NOT NEEDED
THUS
CANNOT WE JUST SOMEHOW DIVIDE THOSE ROUTE GEOMETRIES INTO SEGMENTS 
RATHER THAN APPROXIMATELY CREATING SEGMENTS FROM JUST POINTS ?
-> that's what we do here, those are not approximate :D

*/