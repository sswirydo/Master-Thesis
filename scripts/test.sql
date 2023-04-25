CREATE EXTENSION postgis;
CREATE EXTENSION mobilitydb;

select pg_backend_pid();
-- SELECT pg_sleep(8); -- sleep to run gdb alongside the database

SELECT gtfs_test('test');
SELECT gtfs_test('patate');

-- '/home/szymon/Master-Thesis/data/gtfs/stop_times.txt'
-- SELECT gtfs_read('/home/szymon/Master-Thesis/data/gtfs/');
SELECT gtfs_read('/home/szymon/Master-Thesis/mobilitydb-workshop/');

