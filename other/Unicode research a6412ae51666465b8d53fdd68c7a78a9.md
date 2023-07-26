# Unicode research

# Links

## PostgreSQL related doc

[https://www.postgresql.org/docs/15/charset.html](https://www.postgresql.org/docs/15/charset.html)

[https://www.postgresql.org/docs/current/locale.html](https://www.postgresql.org/docs/current/locale.html)

[https://www.postgresql.org/docs/15/collation.html](https://www.postgresql.org/docs/15/collation.html)

[https://www.postgresql.org/docs/current/multibyte.html](https://www.postgresql.org/docs/current/multibyte.html)

## Usefull ressources

[https://www.cprogramming.com/tutorial/unicode.html](https://www.cprogramming.com/tutorial/unicode.html)

[https://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap07.html](https://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap07.html)

## M**iscellaneous**

[https://dba.stackexchange.com/questions/7323/unicode-support-of-postgresql-and-its-performance](https://dba.stackexchange.com/questions/7323/unicode-support-of-postgresql-and-its-performance)

# Notes

## Locale

<aside>
💡 *Locale* support refers to an application respecting cultural preferences regarding alphabets, sorting, number formatting, etc.

</aside>

- According to doc, affects
    - ORDER BY
    - upper, lower, initcap
    - Pattern matching
        - LIKE, SIMILAR TO, regex
    - to char( ) family
    - indexes with LIKE
- supports multiple locales providers :
    - libc (OS C library)
    - icu (external ICU lib)
- drawback of using locales other than `C` or `POSIX` in PostgreSQL
    - performance impact: it slows character handling and prevents ordinary indexes from being used by `LIKE`. For this reason use locales only if you actually need them.

## Collation

<aside>
💡 The collation feature allows specifying the sort order and character classification behavior of data per-column, or even per-operation.

</aside>

Basically affects comparison operators for strings.

```sql
CREATE TABLE test1 (
    a text COLLATE "de_DE",
    b text COLLATE "es_ES",
    ...
);
SELECT a < 'foo' FROM test1;
SELECT a < ('foo' COLLATE "fr_FR") FROM test1;
```

## Multibyte characters

<aside>
💡 The character set support in PostgreSQL allows you to store text in a variety of character sets (also called encodings), including single-byte character sets such as the ISO 8859 series and multiple-byte character sets such as EUC (Extended Unix Code), UTF-8, and Mule internal code.

</aside>

<aside>
🚨 An important restriction, however, is that each database's character set must be compatible with the database's `LC_CTYPE` (character classification) and `LC_COLLATE` (string sort order) locale settings. For `C` or `POSIX` locale, any character set is allowed, but for other libc-provided locales there is only one character set that will work correctly. (On Windows, however, UTF-8 encoding can be used with any locale.) If you have ICU support configured, ICU-provided locales can be used with most but not all server-side encodings.

</aside>

- To be specified at `initdb`/ `createdb` level.
- Possibly different client / server encodings ⇒ conversion required

# PostgreSQL implementation

## Encodings

### src > backend > utils > mb

Folder containing utility stuff for multibyte support.

### src > backend > utils > mb > mbutils.c

Encoding conversion.

### src > backend > utils > mb > conv.c

Conversion utility functions.

### src > backend > utils > mb > wstrncmp.c

Defines `pg_wchar_strncmp( )` and `pg_wchar_strlen()`

### src > include > mb > pg_wchar.h

Various and important declarations and definitions for multibyte support.

Enumerations of different possible encodings.

### src > common > wchar.c

Main .c file for multibyte support : functions for working with multibyte characters in various encodings.

### src > backend > utils > mb > conversion_procs

- Folder with lots of different conversion .c files
    - e.g. utf8_and_cyrillic.c
        - `Datum utf8_to_koi8r(PG_FUNCTION_ARGS)`
        - …
- Note the presence of fmgr.h

## Locale

### src > backend > utils > adt > pg_locale.c

Locale utilities.

Important code from code:

```c
* Here is how the locale stuff is handled: LC_COLLATE and LC_CTYPE
* are fixed at CREATE DATABASE time, stored in pg_database, and cannot
* be changed. Thus, the effects of strcoll(), strxfrm(), isupper(),
* toupper(), etc. are always in the same fixed locale.
```

## Others

```
src > backend > catalog > pg_collation.c
src > backend > catalog > pg_conversion.c

src > backend > regex > regc_pg_locale.c
src > backend > tsearch > ts_locale.c
src > backend > tsearch > wparser_def.c
src > backend > utils > adt > like.c
src > backend > utils > adt > formatting.c
… and possibly many others affected
```

## Tests

```
src > test > locale
src > test > mb

src > test > regress > sql > collate.linux.utf8.sql
src > test > regress > sql > collate.icu.utf8.sql```
src > test > regress > sql > collate
src > test > regress > sql > regex.linux.utf8.sql
```