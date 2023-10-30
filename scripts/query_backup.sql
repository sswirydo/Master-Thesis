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

-- SELECT temporal_make_periodic(tint '[10@2012-01-01 00:00:00 UTC, 12@2012-04-01 00:00:00 UTC]', pmode('1 day', 1000));
-- SELECT temporal_make_periodic(tint '[10@2012-01-01 UTC, 12@2012-04-01 UTC]', pmode('1 day', 1000));

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



