CREATE EXTENSION IF NOT EXISTS mobilitydb CASCADE;

-- CREATE TABLE Department(DeptNo integer, DeptName varchar(25), NoEmps pint);
-- INSERT INTO Department VALUES
--   (10, 'Research', pint '[10@2012-01-01, 12@2012-04-01, 12@2012-08-01)'),
--   (20, 'Human Resources', pint '[4@2012-02-01, 6@2012-06-01, 6@2012-10-01)');
-- SELECT * FROM Department;

SELECT '2023-05-03 12:00:00 UTC'; 
SELECT '2023-05-03 12:00:00' AT TIME ZONE 'UTC'; 
SELECT tint '[10@2012-01-01 UTC, 12@2012-04-01 UTC, 12@2012-08-01 UTC)';

SELECT tint '[10@2000-01-01 UTC, 12@2000-01-04 UTC]' + tint '[14@2000-01-06 UTC, 12@2000-01-08 UTC]';
SELECT tint '[10@2000-01-01 UTC, 12@2000-01-04 UTC]' + tint '[14@2000-01-01 UTC, 12@2000-01-08 UTC]';
SELECT tint '[14@2000-01-06 UTC, 12@2000-01-08 UTC]';

SELECT asText(ttext '[Buyl@2023-07-01 08:00:00 UTC, ULB@2023-07-01 08:10:00 UTC]');

SELECT tbool ' { true@2001-01-01 08:00:00 , false@2001-01-01 08:05:00 , true@2001-01-01 08:06:00 } ';

SELECT pmode('1 day', 1000);
SELECT pmode('2 days', 1001);
SELECT pmode('60 minutes', 1002);

-- CREATE TABLE test_table (
--   id serial primary key,
--   data pmode
-- );
-- insert into test_table (data)
-- values ("2 days;42");
-- select data from test_table;


SELECT pmode()

SELECT pint('[10@2012-01-01 UTC, 12@2012-04-01 UTC, 12@2012-08-01 UTC)');
SELECT periodicType(pint('[10@2012-01-01 UTC, 12@2012-04-01 UTC]'));
SELECT setPeriodicType(pint('[10@2012-01-01 UTC, 12@2012-04-01 UTC]'), 'day');
SELECT periodicType(setPeriodicType(pint('[10@2012-01-01 UTC, 12@2012-04-01 UTC]'), 'none'));
SELECT periodicType(setPeriodicType(pint('[10@2012-01-01 UTC, 12@2012-04-01 UTC]'), 'day'));
SELECT periodicType(setPeriodicType(pint('[10@2012-01-01 UTC, 12@2012-04-01 UTC]'), 'week'));
SELECT periodicType(setPeriodicType(pint('[10@2012-01-01 UTC, 12@2012-04-01 UTC]'), 'month'));
SELECT periodicType(setPeriodicType(pint('[10@2012-01-01 UTC, 12@2012-04-01 UTC]'), 'year'));

select to_char(timestamptz '2012-01-01 08:00:00', 'DD Mon HH24:MI:SS');
select to_char(timestamptz '2019-09-01', 'MON-DD-YYYY HH12:MIPM');

select quick_test(timestamptz '2012-01-01 13:07:23', 'TEST %a %H:%M:%S');
select quick_test(timestamptz '2012-01-01 13:07:23', 'DD Mon HH24:MI:SS'); -- OK!



---------------------------------------------------------


SELECT pmode('1 day', 100);
SELECT pmode('2 days', 101);
SELECT pmode('60 minutes', 102);
SELECT pmode('60 minutes;103');

SELECT tint('[10@2012-01-01 UTC, 12@2012-04-01 UTC, 12@2012-08-01 UTC)');
SELECT tint '[1@2000-01-01, 2@2000-01-05]' + tint '[10@2000-01-04, 20@2000-01-07]';
-- SELECT tint '[1@2000-01-01, 2@2000-01-02, 3@2000-01-03]' + tint '[10@2000-0:1-05, 10@2000-01-06, 10@2000-01-07]';
-- SELECT tint '[1@2000-01-01, 2@2000-01-02, 3@2000-01-03]' + tint '[10@2000-01-02, 10@2000-01-03, 10@2000-01-04]';

SELECT pint('[10@2012-01-01 UTC, 12@2012-04-01 UTC, 12@2012-08-01 UTC)');
SELECT pint('[10#2000-01-01 UTC, 12#2000-04-01 UTC, 12#2000-08-01 UTC)');
SELECT pint('[10#2000-02-01 UTC, 12#2000-04-01 UTC, 12#2000-08-01 UTC)');
SELECT pint('Periodic=Year;[10#Jan 05 08:00:00, 12#Feb 29 10:00:00, 12#Oct 01 12:00:00)');
SELECT pint('Periodic=Month;[10#03 08:00:00, 12#14 10:00:00, 12#31 12:00:00)');
-- SELECT pint('Periodic=Week;[10#Monday 08:00:00, 12#Tuesday 10:00:00, 16#Saturday 12:00:00)'); -- does not work because of ')'
SELECT pint('Periodic=Week;[10#Monday 08:00:00, 12#Tuesday 10:00:00, 16#Saturday 12:00:00]'); 
SELECT pint('Periodic=Day;[10#02:00:00, 12#10:00:00, 12#12:00:00, 12#13:00:00)');
SELECT pint('Periodic=Interval;[10#0 days, 12#2 days 12 hours, 24#4 days 12 hours 30 minutes]');
SELECT pint('Periodic=Interval;[1#0, 2#30days, 3#1 months 30 days, 4#2 months 30 days]');


-- todo Week does not work, all is 2000-01-01 and day of week does not work properly
-- todo make sure output is not confusing with timezones etc e.g. 00:00:00 gives 01:00:00 since we're in GMT+1
-- TODO TODO TODO make sure special sequences timestamps carry can "overflow"

-- SELECT anchor(pint('[10#2000-01-01 UTC, 12#2000-01-02 UTC, 12#2000-01-03 UTC)'), pmode('2 days', 100), '2019-11-01', '2019-12-01', false);
-- SELECT anchor(pint('[10#2000-01-01 UTC, 12#2000-01-02 UTC, 12#2000-01-03 UTC)'), pmode('2 days', 100), '2019-11-01', '2019-12-01', false);

-- SELECT anchor(pint('[1#2000-02-28, 2#2000-02-29, 3#2000-03-01, 4#2000-03-05]'), pmode('1 year', 2), '2000-01-01', '2022-01-01', false);

-- SELECT anchor(pint('Periodic=Month;[1#29 00:00:00, 2#30 00:00:00, 3#31 00:00:00]'), pmode('1 month', 5), '2001-01-01', '2022-01-01', false);
-- SELECT anchor(pint('Periodic=Month;[1#29 00:00:00, 2#30 00:00:00]'), pmode('1 month', 5), '2001-01-01', '2022-01-01', false);
-- SELECT anchor(pint('Periodic=Month;[1#28 00:00:00, 2#29 00:00:00, 3#30 00:00:00]'), pmode('1 month', 100), '2001-01-01', '2004-01-01', false);

SELECT anchor(pint('[1#2000-01-01 UTC, 2#2000-01-02 UTC, 2#2000-01-03 UTC)'), pmode('2 days', 100), '2019-11-01', '2019-12-01', false);
