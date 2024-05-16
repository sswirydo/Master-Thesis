
CREATE EXTENSION IF NOT EXISTS mobilitydb CASCADE;

SELECT pmode('2 days', 10, true, '[2019-11-01, 2019-12-01]');

SELECT anchor(pint('[1#2000-01-01 UTC, 2#2000-01-02 UTC, 2#2000-01-03 UTC)'), pmode('2 days', 10, true, '[2019-11-01, 2019-12-01]'));


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








-- SELECT tint '[1@2001-01-01 08:00:00, 1@2001-01-03 08:00:00]';
-- SELECT pint '[12001-01-01 08:00:00, 1@2001-01-03 08:00:00]';

-- SELECT tgeompoint '[Point(0 0)@2017-01-01 08:00:00, Point(0 0)@2017-01-01 08:05:00)';
-- SELECT pgeompoint '[Point(0 0)@2017-01-01 08:00:00, Point(0 0)@2017-01-01 08:05:00)';

-- SELECT postgis_full_version();