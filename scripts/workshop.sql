
/*
  Modified version of the MobilityDB GTFS workshop script.
  https://github.com/MobilityDB/MobilityDB-workshop
*/



/****************************************************************************************

  DEFINING EXTENSIONS

****************************************************************************************/

CREATE EXTENSION MobilityDB CASCADE;



/****************************************************************************************

  DEFINING TABLES

****************************************************************************************/

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

-- ADD: stop_geom, platform_code
CREATE TABLE stops (
  stop_id text,
  stop_code text,
  stop_name text DEFAULT NULL,
  stop_desc text DEFAULT NULL,
  stop_lat double precision,
  stop_lon double precision,
  zone_id text,
  stop_url text,
  location_type integer REFERENCES location_types(location_type),
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



/****************************************************************************************

 IMPORTING DATA

****************************************************************************************/

-- CALENDAR
COPY calendar(service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,
start_date,end_date) FROM '/home/szymon/Master-Thesis/data/gtfs/calendar.txt' DELIMITER ',' CSV HEADER;

-- CALENDAR DATES (EXCEPTIONS)
COPY calendar_dates(service_id,date,exception_type)
FROM '/home/szymon/Master-Thesis/data/gtfs/calendar_dates.txt' DELIMITER ',' CSV HEADER;

-- STOP TIMES
COPY stop_times(trip_id,arrival_time,departure_time,stop_id,stop_sequence,
pickup_type,drop_off_type) FROM '/home/szymon/Master-Thesis/data/gtfs/stop_times.txt' DELIMITER ',' CSV HEADER;

-- TRIPS
COPY trips(route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id)
FROM '/home/szymon/Master-Thesis/data/gtfs/trips.txt' DELIMITER ',' CSV HEADER;

-- AGENCY
COPY agency(agency_id,agency_name,agency_url,agency_timezone,agency_lang,agency_phone)
FROM '/home/szymon/Master-Thesis/data/gtfs/agency.txt' DELIMITER ',' CSV HEADER;

-- ROUTE TYPES (optional)
COPY route_types(route_type,description)
FROM '/home/szymon/Master-Thesis/data/gtfs/route_types.txt' DELIMITER ',' CSV HEADER;

-- ROUTES
COPY routes(route_id,route_short_name,route_long_name,route_desc,route_type,route_url,
route_color,route_text_color) FROM '/home/szymon/Master-Thesis/data/gtfs/routes.txt' DELIMITER ',' CSV HEADER;

-- SHAPES
COPY shapes(shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence)
FROM '/home/szymon/Master-Thesis/data/gtfs/shapes.txt' DELIMITER ',' CSV HEADER;

-- STOPS
COPY stops(stop_id,stop_code,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,
location_type,parent_station) FROM '/home/szymon/Master-Thesis/data/gtfs/stops.txt' DELIMITER ',' CSV HEADER;



/****************************************************************************************

  CREATING GEOMETRIES AND OTHER

****************************************************************************************/

INSERT INTO shape_geoms
SELECT shape_id, ST_MakeLine(array_agg(
ST_SetSRID(ST_MakePoint(shape_pt_lon, shape_pt_lat), 4326) ORDER BY shape_pt_sequence))
FROM shapes
GROUP BY shape_id;

UPDATE stops
SET stop_geom = ST_SetSRID(ST_MakePoint(stop_lon, stop_lat), 4326);


DROP TABLE IF EXISTS service_dates;
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


DROP TABLE IF EXISTS trip_stops;
CREATE TABLE trip_stops (
  trip_id text,
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

DROP TABLE IF EXISTS trip_segs;
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

INSERT INTO trip_segs (trip_id, route_id, service_id, stop1_sequence, stop2_sequence, no_stops, shape_id, stop1_arrival_time, stop2_arrival_time, perc1, perc2)
  WITH temp AS (
    SELECT trip_id, route_id, service_id, stop_sequence,
    LEAD(stop_sequence) OVER w AS stop_sequence2,
    MAX(stop_sequence) OVER (PARTITION BY trip_id),
    shape_id, arrival_time, 
    LEAD(arrival_time) OVER w, 
    perc, 
    LEAD(perc) OVER w
    FROM trip_stops WINDOW w AS (PARTITION BY trip_id ORDER BY stop_sequence)
  )
  SELECT * FROM temp WHERE stop_sequence2 IS NOT null;
    UPDATE trip_segs t
    SET seg_geom = ST_LineSubstring(g.shape_geom, perc1, perc2)
    FROM shape_geoms g
    WHERE t.shape_id = g.shape_id;
    UPDATE trip_segs
    SET seg_length = ST_Length(seg_geom), no_points = ST_NumPoints(seg_geom);

DROP TABLE IF EXISTS trip_points;
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

DROP TABLE IF EXISTS trips_input;
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
  ( SELECT service_id, MIN(date) AS date FROM service_dates GROUP BY service_id) s
  ON t.service_id = s.service_id;

DROP TABLE IF EXISTS trips_mdb;
CREATE TABLE trips_mdb (
  trip_id text NOT NULL,
  route_id text NOT NULL,
  service_id text NOT NULL,
  date date NOT NULL,
  trip tgeompoint,
  PRIMARY KEY (trip_id, date)
);

INSERT INTO trips_mdb(trip_id, route_id, date, trip)
  SELECT trip_id, route_id, date,
  tgeompoint_seq(array_agg(tgeompoint_inst(point_geom, t) ORDER BY T))
  FROM trips_input
  GROUP BY trip_id, route_id, date;
  INSERT INTO trips_mdb(trip_id, service_id, route_id, date, trip)
  SELECT trip_id, route_id, t.service_id, d.date,
  shift(trip, make_interval(days => d.date - t.date))
  FROM trips_mdb t JOIN service_dates d ON t.service_id = d.service_id AND t.date <> d.date;

/****************************************************************************************

  SELECTING DATA (TESTING)

****************************************************************************************/

SELECT * FROM stops LIMIT 10;
