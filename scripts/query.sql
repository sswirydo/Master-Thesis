
CREATE EXTENSION IF NOT EXISTS mobilitydb CASCADE;

SELECT pmode('2 days', 10, true, '[2019-11-01, 2019-12-01]');

-- SELECT anchor(pint('[1#2000-01-01 UTC, 2#2000-01-02 UTC, 2#2000-01-03 UTC)'), pmode('2 days', 10, true, '[2019-11-01, 2019-12-01]'));


SELECT tstzspanset '{[2001-01-01 08:00:00, 2001-01-01 08:10:00),
  [2001-01-01 08:10:00, 2001-01-01 08:10:00], (2001-01-01 08:10:00, 2001-01-01 08:20:00]}';


SELECT tgeompoint 'Point(0 0)@2017-01-01 08:00:05';
SELECT pgeompoint 'Point(0 0)#2017-01-01 08:00:05';

SELECT pint('Periodic=Interval;[1#0, 2#30days, 3#1 months 30 days, 4#2 months 30 days]');

SELECT pgeompoint('Periodic=Interval;[Point(0 0)#0, Point(0 1)#30days, Point(0 2)#1 months 30 days, Point(0 3)#2 months 30 days]');
SELECT periodicType(pgeompoint('Periodic=Interval;[Point(0 0)#0, Point(0 1)#30days, Point(0 2)#1 months 30 days, Point(0 3)#2 months 30 days]'));


CREATE TABLE Department(DeptNo integer, DeptName varchar(25), NoEmps pint);
INSERT INTO Department VALUES
  (10, 'Research', pint '[10@2012-01-01, 12@2012-04-01, 12@2012-08-01)'),
  (20, 'Human Resources', pint '[4@2012-02-01, 6@2012-06-01, 6@2012-10-01)');
SELECT * FROM Department;

UPDATE Department
SET NoEmps = setPeriodicType(NoEmps, 'interval');
SELECT NoEmps FROM Department;

ALTER TABLE Department ALTER COLUMN NoEmps TYPE tint;
SELECT NoEmps FROM Department;

ALTER TABLE Department ALTER COLUMN NoEmps TYPE pint;
SELECT NoEmps FROM Department;

SELECT 2+2;


CREATE TABLE calendar_dates (
  service_id text,
  date date NOT NULL,
  exception_type int
);
COPY calendar_dates(service_id,date,exception_type)
  FROM '/home/szymon/Master-Thesis/mobilitydb-workshop/calendar_dates.txt' DELIMITER ',' CSV HEADER;


CREATE VIEW exceptions AS 
  SELECT set(array_agg(c.date::timestamptz)) FROM calendar_dates c;

CREATE VIEW points AS
  SELECT pgeompoint('[Point(0 0)#2000-01-01, 
                      Point(0 1)#2000-01-02, 
                      Point(0 2)#2000-01-03, 
                      Point(0 3)#2000-01-04,
                      Point(0 4)#2000-01-05]');


-- SELECT anchor(pint('[1#2000-01-01 CET, 2#2000-01-02 CET]'), pmode('1 week', 4, true, '[2019-01-01, 2019-12-01]'));


SELECT setPeriodicType(pint ('[1#2000-01-01 UTC, 2#2000-01-02 UTC, 2#2000-01-08 00:59:59 UTC)'), 'day'); -- OK
SELECT setPeriodicType(pint ('[1#2000-01-01 UTC, 2#2000-01-02 UTC, 2#2000-01-08 00:59:59 UTC)'), 'week'); -- OK

SELECT pint('Periodic=Day;[1#08:00:00, 2#10:00:00, 3#12:00:00]');

SELECT 2+2;

SELECT timestamptz '2000-01-31' + interval '31 days';
SELECT timestamptz '2000-01-31' + interval '1 month';
SELECT timestamptz '2000-01-29' + interval '1 month';

SELECT setPeriodicType(pint('Periodic=Interval;[1#0, 2#31 days, 3#62 days]'), 'none');
SELECT setPeriodicType(pint('Periodic=Interval;[1#0, 2#1 month, 3#2 months]'), 'none');


SELECT tint '{20@2024-03-01, 25@2024-03-06, 30@2024-04-01}';
SELECT tint 'Interp=Step; (20@2024-03-01, 25@2024-03-06, 30@2024-04-01]';
SELECT tint '(20@2024-03-01, 25@2024-03-06, 30@2024-04-01]';

SELECT tint '25@2024-03-06';

CREATE VIEW test1 AS (
SELECT ttext '{[Delta@2024-03-01 08:00:00, ULB@2024-03-01 08:30:00],
  [Buyl@2024-03-01 08:45:00, VUB@2024-03-01 09:00:00]}' as trip
);

SELECT valueAtTimestamp(trip, '2024-03-01 11:00:00') FROM test1;
SELECT valueAtTimestamp(trip, '2024-03-01 13:00:00') FROM test1;


SELECT 
    DATE_TRUNC('month', CURRENT_DATE) + i_day * '1 day'::interval AS date
FROM generate_series(0, 6) AS i_day
WHERE EXTRACT(dow FROM DATE_TRUNC('month', CURRENT_DATE) + i_day * '1 day'::interval) = 1;


SELECT tgeompoint '[Point(0 0)@2001-01-01, Point(1 1)@2001-01-02)' <-> tgeompoint '[Point(0 1)@2001-01-01, Point(1 2)@2001-01-02)';

SELECT tgeompoint '[Point(0 0)@2001-01-01, Point(1 1)@2001-01-02]' <-> tgeompoint '[Point(0 1)@2001-01-02, Point(1 2)@2001-01-03]';


SELECT valueAtTimestamp(tfloat '(20@2024-03-01, 25@2024-03-06, 30@2024-03-11]', '2024-03-03');
SELECT tfloat '(20@2024-03-01, 25@2024-03-06, 30@2024-03-11]';

-- CREATE FUNCTION add_numbers(x integer, y integer)
-- RETURNS integer as $$ 
--     SELECT x + y; 
-- $$ LANGUAGE SQL; 

-- SELECT add_numbers(2, 2)


SELECT asText(tgeompoint '[Point(0 0)@2024-01-01 10:00, Point(1 1)@2024-06-01 10:00]');


SELECT '2000-01-01 08:00:00'::timestamptz;
-- timestamptz|2000-01-01 08:00:00+01
SELECT '2000-06-01 08:00:00'::timestamptz;
-- timestamptz|2000-06-01 08:00:00+02

SELECT '2000-01-01 08:00:00'::timestamptz AT TIME ZONE 'UTC';
-- timezone|2000-01-01 07:00:00
SELECT '2000-06-01 08:00:00'::timestamptz AT TIME ZONE 'UTC';
-- timezone|2000-06-01 06:00:00

SELECT '2000-01-01 08:00:00'::timestamptz AT TIME ZONE 'UTC' AT TIME ZONE 'CEST';

SELECT '2000-06-01 07:00:00 UTC'::timestamptz AT TIME ZONE 'CEST';
-- timestamptz|2000-01-01 08:00:00+01

SELECT '2024-06-30 00:00:00 CEST'::timestamptz AT TIME ZONE 'UTC';

-- SELECT ('2024-06-29 22:00:00 UTC'::integer + '2000-01-01 10:00:00 CET'::integer)::timestamptz;

SELECT asText(tgeompoint '[Point(0 0)@2000-10-29 01:59, Point(1 1)@2000-10-29 03:00]');
SELECT duration(tgeompoint '[Point(0 0)@2000-10-29 01:59, Point(1 1)@2000-10-29 02:00]');

SELECT duration(tgeompoint '[Point(0 0)@2000-01-01 00:00:00 CEST, Point(1 1)@2000-10-28 10:00:00]');

SELECT duration(tgeompoint '[Point(0 0)@2000-01-01 10:00, Point(1 1)@2000-06-01 10:00]');
SELECT duration(tgeompoint '[Point(0 0)@2000-01-01 00:00:00 CET, Point(1 1)@2000-06-01 10:00]');


SELECT '2000-01-01 10:00:00'::timestamptz AT TIME ZONE 'UTC';

SELECT ('2000-01-01 10:00:00+15'::timestamptz)::timestamp;
SHOW timezone;
SELECT '2000-01-01 10:00:00+15'::timestamp;


SELECT setPeriodicType(pint('Periodic=Week; [1#Monday 10:00:00, 2#Tuesday 10:00:00]'), 'none');
SELECT setPeriodicType(pint('Periodic=Week; [1#Monday 10:00:00, 2#Tuesday 10:00:00]'), 'none');

SELECT pint('Periodic=Week; [1#Monday 10:00:00+05, 2#Tuesday 10:00:00]');
SELECT setPeriodicType(pint('Periodic=Week; [1#Monday 10:00:00+05, 2#Tuesday 10:00:00]'), 'none');

-- SELECT pint('Periodic=Year;[10#Jan 05 10:00:00, 12#Feb 29 10:00:00, 12#Oct 01 10:00:00)');
-- SELECT setPeriodicType(pint('Periodic=Year;[10#Jan 05 10:00:00, 12#Feb 29 10:00:00, 12#Oct 01 10:00:00)'), 'none');

SELECT setPeriodicType(pint('Periodic=Interval; [1#0 days 10:00:00, 2#152 days 10:00:00]'), 'none');

SELECT '[2019-11-01, 2019-12-01]';
SELECT '[2019-11-01, 2019-12-01]'::tstzspan;
SELECT span('2019-11-01'::timestamptz, '2019-12-01'::timestamptz, true, true)::tstzspan;

-- SELECT anchor_pmode(pint('Periodic=Day; [1#08:00:00, 2#08:30:00, 2#09:00:00)'), pmode('1 day', 20, true, '[2019-11-01, 2019-12-01]'::tstzspan));
SELECT anchor_pmode(pint('Periodic=Day; [1#08:00:00, 2#08:30:00, 2#09:00:00)'), pmode('1 hour', 20, true, '[2019-11-01, 2019-12-01]'::tstzspan));

SELECT anchor_pmode(pint('Periodic=Day; [1#08:00:00, 2#08:30:00, 2#09:00:00)'), pmode('1 hour', 100, true, '[2019-11-01, 2019-11-01 13:45:00]'::tstzspan));
SELECT anchor_pmode(pint('Periodic=Day; [1#08:00:00, 2#08:30:00, 2#09:00:00)'), pmode('1 hour', 100, false, '[2019-11-01, 2019-11-01 13:45:00]'::tstzspan));

SELECT anchor(pint('Periodic=Day; [1#08:00:00, 2#08:30:00, 2#09:00:00)'), '[2019-11-01, 2019-11-01 13:45:00]'::tstzspan, '1 hour', true);


SELECT anchor_array(pint('Periodic=Day; [1#08:00:00, 2#08:30:00, 2#09:00:00)'), '[2019-11-01, 2019-11-29 13:45:00]'::tstzspan, '1 day', true, ARRAY[1,1,1,1,1,0,1]);


SELECT periodic_align(pint('Periodic=Day; [1#08:00:00, 2#08:30:00, 2#09:00:00)'));
SELECT periodic_align(pint('Periodic=Day; [1#08:00:00, 2#08:30:00, 2#09:00:00)'), timestamp '2000-01-01 15:23:23');

SELECT periodicValueAtTimestamp(
  pint('Periodic=Day; [1#08:00:00, 2#08:30:00, 2#09:00:00)'),
  '[2000-01-01 00:00:00, 2000-02-01 00:00:00]'::tstzspan,
  '1 day'::interval,
  '2000-01-03 08:00:00'::timestamptz
);

-- SELECT tint '[1@2001-01-01 08:00:00, 1@2001-01-03 08:00:00]';
-- SELECT pint '[12001-01-01 08:00:00, 1@2001-01-03 08:00:00]';

-- SELECT tgeompoint '[Point(0 0)@2017-01-01 08:00:00, Point(0 0)@2017-01-01 08:05:00)';
-- SELECT pgeompoint '[Point(0 0)@2017-01-01 08:00:00, Point(0 0)@2017-01-01 08:05:00)';

-- SELECT postgis_full_version();