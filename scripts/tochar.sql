
select to_char(timestamptz '2019-09-01', 'MON-DD-YYYY HH12:MIPM');
select to_char(interval '15h 2m 12s', 'HH24:MI:SS');
select to_date('05 Dec 2000', 'DD Mon YYYY');
select to_timestamp('05 Dec 2000', 'DD Mon YYYY');

SELECT p.proname AS function_name, p.prosrc AS source_code
FROM pg_proc p
JOIN pg_language l ON p.prolang = l.oid
WHERE p.proname = 'to_date'
  AND l.lanname = 'internal';