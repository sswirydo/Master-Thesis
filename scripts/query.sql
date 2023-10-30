CREATE EXTENSION IF NOT EXISTS mobilitydb CASCADE;

SELECT pmode('1 day', 100);
SELECT pmode('2 days', 101);
SELECT pmode('60 minutes', 102);
SELECT pmode('60 minutes;103');

SELECT pint('[10@2012-01-01 UTC, 12@2012-04-01 UTC, 12@2012-08-01 UTC)');
SELECT pint('[10#2000-01-01 UTC, 12#2000-04-01 UTC, 12#2000-08-01 UTC)');
SELECT pint('Periodic=Year;[10#Jan 05 08:00:00, 12#Feb 29 10:00:00, 12#Oct 01 12:00:00)');
SELECT pint('Periodic=Month;[10#03 08:00:00, 12#14 10:00:00, 12#31 12:00:00)');
-- SELECT pint('Periodic=Week;[10#Monday 08:00:00, 12#Tuesday 10:00:00, 16#Saturday 12:00:00)'); -- does not work because of ')'
SELECT pint('Periodic=Week;[10#Monday 08:00:00, 12#Tuesday 10:00:00, 16#Saturday 12:00:00]'); 
SELECT pint('Periodic=Day;[10#02:00:00, 12#10:00:00, 12#13:00:00)');
SELECT pint('Periodic=Interval;[10#0 days, 12@2 days 12 hours, 24@4 days 12 hours 30 minutes]');

-- todo Week does not work, all is 2000-01-01 and day of week does not work properly
-- todo make sure output is not confusing with timezones etc e.g. 00:00:00 gives 01:00:00 since we're in GMT+1

-- TODO TODO TODO make sure special sequences timestamps carry can "overflow"

SELECT anchor(pint('[10#2000-01-01 UTC, 12#2000-01-03 UTC, 12#2000-01-05 UTC)'), pmode('10 days', 4), '2019-11-01', '2019-12-01');

-- e.g. should those be possible ?
--  Sat, Sun, Mon, Tue 
--  Nov, Dec, Jan, Feb
--  22h, 23h, 01h, 02h

-- or is it sufficient to write them like
--  Mon, Tue, Sat, Sun
--  Jan, Feb, Nov, Dec
--  01h, 02h, 22h, 23h

-- what about anchoring them in time ? e.g. October 1st 2024 (Sunday) 
-- (1 time) WEEK
--  Oct 1, Oct 2, Oct 3 (Sun, Mon, Tue)
--  Oct 1, Oct 2, Oct 3, Oct 7 (Sun, Mon, Tue, Sat)
--  Oct 1 (Sun)
-- (in [Oct 1, Oct8])
--  Oct 1, Oct 2, Oct 3, Oct 7, Oct 8 (Sun, Mon, Tue, Sat, Sun)