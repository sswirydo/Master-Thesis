
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS mobilitydb;

-- select to_char(timestamptz '2019-09-01', 'MON-DD-YYYY HH12:MIPM');
-- select to_char(interval '15h 2m 12s', 'HH24:MI:SS');
-- select to_date('05 Dec 2000', 'DD Mon YYYY');
-- select to_timestamp('05 Dec 2000', 'DD Mon YYYY'); -- 2000-12-05 00:00:00-05
-- select to_timestamp('05 Dec 2000 15:00:00 -01', 'DD Mon YYYY HH24:MI:SS TZH'); -- 2000-12-05 00:00:00-05
-- select to_timestamp('05 Dec 2000 15:00:00 -01', 'DD Mon YYYY HH24:MI:SS  TZH'); -- 2000-12-05 00:00:00-05
  
-- select to_timestamp('05121445482000', 'MMDDHH24MISSYYYY'); -- does not work in meos
-- select to_timestamp('2000January09Sunday', 'YYYYFMMonthDDFMDay');

-- SELECT p.proname AS function_name, p.prosrc AS source_code
-- FROM pg_proc p
-- JOIN pg_language l ON p.prolang = l.oid
-- WHERE p.proname = 'to_timestamp'
--   AND l.lanname = 'internal';


-- select to_timestamp('2000-01-01 08:14:30 +02', 'YYYY-MM-DD HH24:MI:SS TZH');
-- select to_date('2011 x12 x18', 'YYYYxMMxDD');

select tint '[10@2000-01-01, 20@2010-01-01]';
select tint '[10@0001-01-01]';

select to_timestamp('1890-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
select to_timestamp('19971116', 'YYYYMMDD');
select to_timestamp('15 "text between quote marks" 98 54 45', E'HH24 "\\"text between quote marks\\"" YY MI SS');

show timezone;