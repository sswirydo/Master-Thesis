/**
 * The program can be build as follows
 * @code
 * gcc -Wall -g -I/usr/local/include -o sandbox sandbox.c -L/usr/local/lib -lmeos
 * @endcode
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <meos_internal.h>

const char* tochar_fmt[] = {
  "MON-DD-YYYY HH12:MIPM",
  // "YYYY-MM-DD HH:MI:SS TZ",
  "YYYY-MM-DD SSSS",
  "YYYY-MM-DD SSSSS",
  "DAY Day day DY Dy dy MONTH Month month RM MON Mon mon",
  "FMDAY FMDay FMday FMMONTH FMMonth FMmonth FMRM",
  "Y,YYY YYYY YYY YY Y CC Q MM WW DDD DD D J",
  "FMY,YYY FMYYYY FMYYY FMYY FMY FMCC FMQ FMMM FMWW FMDDD FMDD FMD FMJ",
  "HH HH12 HH24 MI SS SSSS",
  "\"HH:MI:SS is\" HH:MI:SS \"\\\"text between quote marks\\\"",
  "HH24--text--MI--text--SS",
  "YYYYTH YYYYth Jth",
  "YYYY A.D. YYYY a.d. YYYY bc HH:MI:SS P.M. HH:MI:SS p.m. HH:MI:SS pm",
  "IYYY IYY IY I IW IDDD ID",
  "FMIYYY FMIYY FMIY FMI FMIW FMIDDD FMID",
  // "TZH:TZM",
  "FF1 FF2 FF3 FF4 FF5 FF6  ff1 ff2 ff3 ff4 ff5 ff6  MS US",
};

const char* tochar_dt[] = {
  "2000-01-01 00:00:00",
  "01-01-01 00:00:00",
  "2010-02-10 12:10:00",
  "2024-03-20 24:00:00",
  "2000-04-30 03:35:54",
  "2000-05-01 06:49:00",
  "2000-06-10 09:50:00",
  "2000-07-20 13:59:59",
  "2000-08-30 19:48:23",
  "2000-09-01 21:23:11",
  "2000-10-10 23:44:59",
  "2000-11-20 05:01:53",
  "2000-12-30 15:23:23",
};

// to_date() and to_ts()
const char* dates_fmt[] = {
  "1 4 1902", "Q MM YYYY", // --- Q is ignored
  "3 4 21 01", "W MM CC YY",
  "2458872", "J",
  "44-02-01 BC","YYYY-MM-DD BC",
  "-44-02-01","YYYY-MM-DD",
  "-44-02-01 BC","YYYY-MM-DD BC",
  "2011 12  18", "YYYY MM DD",
  "2011 12  18", "YYYY MM  DD",
  "2011 12  18", "YYYY MM   DD",
  "2011 12 18", "YYYY  MM DD",
  "2011  12 18", "YYYY  MM DD",
  "2011   12 18", "YYYY  MM DD",
  "2011 12 18", "YYYYxMMxDD",
  "2011x 12x 18", "YYYYxMMxDD",
  //
  // -- error handling starts here (out and not out of range)
  //
  // "2011 x12 x18", "YYYYxMMxDD",
  // "2016-13-10", "YYYY-MM-DD", 
  // "2016-02-30", "YYYY-MM-DD",
  "2016-02-29", "YYYY-MM-DD", // -- ok
  // "2015-02-29", "YYYY-MM-DD",
  "2015 365", "YYYY DDD", // -- ok
  // "2015 366", "YYYY DDD",
  "2016 365", "YYYY DDD", // -- ok
  "2016 366", "YYYY DDD", // -- ok
  // "2016 367", "YYYY DDD",
  "0000-02-01","YYYY-MM-DD", // -- allowed, though it shouldn't be
  //
  // -- UTF8
  //
  // "01 ŞUB 2010", "DD TMMON YYYY",
  // "01 Şub 2010", "DD TMMON YYYY",
  // "1234567890ab 2010", "TMMONTH YYYY", // -- fail
};

// todo fixme (?) troubles to parse input with quotes ("") but might be SQL <-> C related
//  i.e. there is no error but after-quote input seem ignored in output
// (only affects to_timestamp, quotes are fine for to_char() family)
const char* timestamps_fmt[] = {
  "0097/Feb/16 --> 08:14:30", "YYYY/Mon/DD --> HH:MI:SS",
  "97/2/16 8:14:30", "FMYYYY/FMMM/FMDD FMHH:FMMI:FMSS",
  "2011$03!18 23_38_15", "YYYY-MM-DD HH24:MI:SS",
  "1985 January 12", "YYYY FMMonth DD",
  "1985 FMMonth 12", "YYYY \"FMMonth\" DD", // fixme (?) -> 12 ie DD ignored -> 1985-01-01
  "1985 \\ 12", "YYYY \\ DD", 
  // "My birthday-> Year: 1976, Month: May, Day: 16", "\"My birthday-> Year:\" YYYY, \"Month:\" FMMonth, \"Day:\" DD",
  "1,582nd VIII 21", "Y,YYYth FMRM DD",
  // "15 \"text between quote marks\" 98 54 45", "HH24 \"text between quote marks\" YY MI SS",
  // "15 \"text between quote marks\" 98 54 45", "HH24 \"\\\"text between quote marks\\\"\" YY MI SS",
  "15 text between quote marks 98 54 45", "HH24 \"\\text between quote marks\\\" YY MI SS",
  "15 98 54 45", "HH24 YY MI SS",
  // select to_timestamp('15 "text between quote marks" 98 54 45', E'HH24 "\\"text between quote marks\\"" YY MI SS');
  // => 1998-01-01 15:54:45
  "05121445482000", "MMDDHH24MISSYYYY",
  "2000January09Sunday", "YYYYFMMonthDDFMDay",
  // "97/Feb/16", "YYMonDD", // invalid value (ok)
  "97/Feb/16", "YY:Mon:DD",
  "97/Feb/16", "FXYY:Mon:DD",
  "97/Feb/16", "FXYY/Mon/DD",
  "19971116", "YYYYMMDD",
  "20000-1116", "YYYY-MMDD",
  "1997 AD 11 16", "YYYY BC MM DD",
  "1997 BC 11 16", "YYYY BC MM DD",
  "1997 A.D. 11 16", "YYYY B.C. MM DD",
  "1997 B.C. 11 16", "YYYY B.C. MM DD",
  "9-1116", "Y-MMDD",
  "95-1116", "YY-MMDD",
  "995-1116", "YYY-MMDD",
  "2005426", "YYYYWWD",
  "2005300", "YYYYDDD",
  "2005527", "IYYYIWID",
  "005527", "IYYIWID",
  "05527", "IYIWID",
  "5527", "IIWID",
  "2005364", "IYYYIDDD",
  "20050302", "YYYYMMDD",
  "2005 03 02", "YYYYMMDD",
  " 2005 03 02", "YYYYMMDD",
  "  20050302", "YYYYMMDD",
  "2011-12-18 11:38 AM", "YYYY-MM-DD HH12:MI PM",
  "2011-12-18 11:38 A.M.", "YYYY-MM-DD HH12:MI P.M.",
  "2011-12-18 11:38 P.M.", "YYYY-MM-DD HH12:MI P.M.",
  "2011-12-18 11:38 +05",    "YYYY-MM-DD HH12:MI TZH",
  "2011-12-18 11:38 -05",    "YYYY-MM-DD HH12:MI TZH",
  "2011-12-18 11:38 +05:20", "YYYY-MM-DD HH12:MI TZH:TZM",
  "2011-12-18 11:38 -05:20", "YYYY-MM-DD HH12:MI TZH:TZM",
  "2011-12-18 11:38 20",     "YYYY-MM-DD HH12:MI TZM",
  // "2011-12-18 11:38 PST", "YYYY-MM-DD HH12:MI TZ", // -- NYI
  "2018-11-02 12:34:56.025", "YYYY-MM-DD HH24:MI:SS.MS",
  "2018-11-02 12:34:56", "YYYY-MM-DD HH24:MI:SS.FF",
  "2018-11-02 12:34:56.1", "YYYY-MM-DD HH24:MI:SS.FF",
  "2018-11-02 12:34:56.12", "YYYY-MM-DD HH24:MI:SS.FF",
  "2018-11-02 12:34:56.123", "YYYY-MM-DD HH24:MI:SS.FF",
  "2018-11-02 12:34:56.1234", "YYYY-MM-DD HH24:MI:SS.FF",
  "2018-11-02 12:34:56.12345", "YYYY-MM-DD HH24:MI:SS.FF",
  "2018-11-02 12:34:56.123456", "YYYY-MM-DD HH24:MI:SS.FF",
  "2018-11-02 12:34:56.123456789", "YYYY-MM-DD HH24:MI:SS.FF",
  "44-02-01 11:12:13 BC","YYYY-MM-DD HH24:MI:SS BC",
  "-44-02-01 11:12:13","YYYY-MM-DD HH24:MI:SS",
  "-44-02-01 11:12:13 BC","YYYY-MM-DD HH24:MI:SS BC",
  "2011-12-18 23:38:15", "YYYY-MM-DD  HH24:MI:SS",
  "2011-12-18  23:38:15", "YYYY-MM-DD  HH24:MI:SS",
  "2011-12-18   23:38:15", "YYYY-MM-DD  HH24:MI:SS",
  "2011-12-18  23:38:15", "YYYY-MM-DD HH24:MI:SS",
  "2011-12-18  23:38:15", "YYYY-MM-DD  HH24:MI:SS",
  "2011-12-18  23:38:15", "YYYY-MM-DD   HH24:MI:SS",
  "2000+   JUN", "YYYY/MON",
  "  2000 +JUN", "YYYY/MON",
  " 2000 +JUN", "YYYY//MON",
  "2000  +JUN", "YYYY//MON",
  "2000 + JUN", "YYYY MON",
  "2000 ++ JUN", "YYYY  MON",
  // "2000 + + JUN", "YYYY  MON", // invalid input (ok)
  "2000 + + JUN", "YYYY   MON",
  "2000 -10", "YYYY TZH",
  "2000 -10", "YYYY  TZH",
  //
  // -- error handling starts here
  //
  // Mixture of date conventions (ISO week and Gregorian):
  // "2005527", "YYYYIWID", // ok
  // -- -- Insufficient characters in the source string:
  // "19971", "YYYYMMDD", // ok
  // -- Insufficient digit characters for a single node:
  // "19971)24", "YYYYMMDD", // ok
  // -- We don't accept full-length day or month names if short form is specified:
  // "Friday 1-January-1999", "DY DD MON YYYY",
  // "Fri 1-January-1999", "DY DD MON YYYY",
  "Fri 1-Jan-1999", "DY DD MON YYYY", // correct and ok
  // -- Value clobbering:
  // "1997-11-Jan-16", "YYYY-MM-Mon-DD", // ok
  // -- Non-numeric input:
  // "199711xy", "YYYYMMDD", // ok
  // -- Input that doesn't fit in an int:
  // "10000000000", "FMYYYY", // ok
  // -- Out-of-range and not-quite-out-of-range fields:
  // "2016-06-13 25:00:00", "YYYY-MM-DD HH24:MI:SS", // ok
  // "2016-06-13 15:60:00", "YYYY-MM-DD HH24:MI:SS", // ok
  // "2016-06-13 15:50:60", "YYYY-MM-DD HH24:MI:SS", // ok
  "2016-06-13 15:50:55", "YYYY-MM-DD HH24:MI:SS", // -- ok
  // "2016-06-13 15:50:55", "YYYY-MM-DD HH:MI:SS", // ok
  // "2016-13-01 15:50:55", "YYYY-MM-DD HH24:MI:SS", // ok
  // "2016-02-30 15:50:55", "YYYY-MM-DD HH24:MI:SS", // ok
  "2016-02-29 15:50:55", "YYYY-MM-DD HH24:MI:SS", // -- ok
  // "2015-02-29 15:50:55", "YYYY-MM-DD HH24:MI:SS",
  "2015-02-11 86000", "YYYY-MM-DD SSSS", // -- ok
  // "2015-02-11 86400", "YYYY-MM-DD SSSS", // ok
  "2015-02-11 86000", "YYYY-MM-DD SSSSS", // -- ok
  // "2015-02-11 86400", "YYYY-MM-DD SSSSS", // ok
};

const char* interval_fmt[] = {
  "15h 2m 12s", "HH24:MI:SS", // Expected Output: 15:02:12
  "3 days 5 hours 30 minutes", "DD \"days\" HH24 \"hours\" MI \"minutes\"",
  "2 months 15 days 3 hours 45 minutes", "MM \"months\" DD \"days\" HH24 \"hours\" MI \"minutes\"",
  "1 year 6 months 20 days 12 hours 30 minutes", "YYYY \"years\" MM \"months\" DD \"days\" HH24 \"hours\" MI \"minutes\"",
};




void test_timestamptz_to_char()
{
  printf("\n########################\n %s\n########################\n\n", "TO_CHAR( TSTZ )");
  for (size_t i = 0; i < sizeof(tochar_fmt) / sizeof(char*); i++) {
    printf("\n%s\n", tochar_fmt[i]);
    for (size_t j = 0; j < sizeof(tochar_dt) / sizeof(char*); j++) {
      printf("(%d)", (int) j);
      TimestampTz tstz = pg_timestamptz_in(tochar_dt[j], -1);
      text *fmt_t = cstring2text(tochar_fmt[i]);
      printf(" %s", tochar_dt[j]);
      text *out_t = pg_timestamptz_to_char(tstz, fmt_t);
      char *out = text2cstring(out_t);
      printf(" => %s\n", out);
      free(fmt_t); free(out_t); free(out);
    }
  }
}

void test_timestamp_to_char()
{
  printf("\n########################\n %s\n########################\n\n", "TO_CHAR( TS )");
  for (size_t i = 0; i < sizeof(tochar_fmt) / sizeof(char*); i++) {
    printf("\n%s\n", tochar_fmt[i]);
    for (size_t j = 0; j < sizeof(tochar_dt) / sizeof(char*); j++) {
      printf("(%d)", (int) j);
      Timestamp ts = pg_timestamp_in(tochar_dt[j], -1);
      text *fmt_t = cstring2text(tochar_fmt[i]);
      printf(" %s", tochar_dt[j]);
      text *out_t = pg_timestamp_to_char(ts, fmt_t);
      char *out = text2cstring(out_t);
      printf(" => %s\n", out);
      free(fmt_t); free(out_t); free(out);
    }
  }
}

void test_interval_to_char() 
{
  printf("\n########################\n %s\n########################\n\n", "TO_CHAR( INTERVAL )");

    for (size_t i = 0; i < sizeof(interval_fmt) / sizeof(char *); i++) {
    printf("%d ", (int) i/2);
    const char *it_str = interval_fmt[i++];
    const char *fmt_str = interval_fmt[i];
    printf("'%s', '%s' ", it_str, fmt_str);
    Interval *it = pg_interval_in(it_str, -1);
    text *fmt_t = cstring2text(fmt_str);
    text *out_t = pg_interval_to_char(it, fmt_t);
    char *out = text2cstring(out_t);
    printf("=> '%s'\n", out);
    free(it); free(fmt_t); free(out);
  }
}

void test_to_timestamp()
{
  printf("\n########################\n %s\n########################\n\n", "TO_TIMESTAMP( )");
  for (size_t i = 0; i < sizeof(timestamps_fmt) / sizeof(char *); i++) {
    printf("%d ", (int) i/2);
    const char *date = timestamps_fmt[i++];
    const char *fmt = timestamps_fmt[i];
    printf("'%s', '%s' ", date, fmt);
    text *date_t = cstring2text(date);
    text *fmt_t = cstring2text(fmt);
    Timestamp ts = pg_to_timestamp(date_t, fmt_t);
    char *out = pg_timestamptz_out(ts);
    printf("=> '%s'\n", out);
    free(date_t); free(fmt_t); free(out);
  }
}

void test_to_date()
{
  printf("\n########################\n %s\n########################\n\n", "TO_TIMESTAMP( )");
  for (size_t i = 0; i < sizeof(dates_fmt) / sizeof(char *); i++) {
    printf("%d ", (int) i/2);
    const char *date = dates_fmt[i++];
    const char *fmt = dates_fmt[i];
    printf("'%s', '%s' ", date, fmt);
    text *date_t = cstring2text(date);
    text *fmt_t = cstring2text(fmt);
    DateADT dadt = pg_to_date(date_t, fmt_t);
    char *out = pg_date_out(dadt);
    printf("=> '%s'\n", out);
    free(date_t); free(fmt_t); free(out);
  }
}





int main() {
  /* Initialize MEOS */
  meos_initialize(NULL);
 
  test_timestamptz_to_char(); // OK
  test_timestamp_to_char(); // OK
  test_interval_to_char(); // OK
  test_to_timestamp(); // OK (kind of except for quotes)
  test_to_date(); // OK

  /* Finalize MEOS */
  meos_finalize();

  /* Return */
  return 0;
}
