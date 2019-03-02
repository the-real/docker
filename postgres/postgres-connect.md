---
title: "Connecting to a postgresql database"
output: 
  html_document: 
    keep_md: yes
---



Start the `rsm-msba` or `rsm-msba-spark` computing container to also start postgresql. You can connect to the database using the code chunk below.


```r
library(DBI)
library(RPostgreSQL)
con <- dbConnect(
  dbDriver("PostgreSQL"),
  user = "jovyan", 
  host = "127.0.0.1",
  port = 8765,
  dbname = "rsm-docker",
  password = "postgres"
  ## can use the line below in interactive sessions
  # password = rstudioapi::askForPassword("Database password")
)
```

Is there anything in the data base? If this is not the first time you are running this Rmarkdown file the database should be available already (i.e., the code chunk below should show "flights" as an existing table)


```r
library(dplyr)
```

```
## 
## Attaching package: 'dplyr'
```

```
## The following objects are masked from 'package:stats':
## 
##     filter, lag
```

```
## The following objects are masked from 'package:base':
## 
##     intersect, setdiff, setequal, union
```

```r
db_tabs <- dbListTables(con)
db_tabs
```

```
## [1] "flights" "mtcars"  "films"
```

If the database is empty, lets start with the example at <https://db.rstudio.com/dplyr/>{target="_blank"} and work through the following 6 steps:

### 1. install the nycflights13 package if not already available


```r
if (!require("nycflights13")) {
  install.packages("nycflights13")
}
```

```
## Loading required package: nycflights13
```

### 2. Push data into the database 

Note that this is a fairly large file that we are copying into the database so make sure you have at least a reasonable amount of resources set as available for docker. See the install instructions for details:

* Windows: https://github.com/radiant-rstats/docker/blob/master/install/rsm-msba-windows.md
* macOS: https://github.com/radiant-rstats/docker/blob/master/install/rsm-msba-macos.md
* Linux: https://github.com/radiant-rstats/docker/blob/master/install/rsm-msba-linux.md


```r
## only push to db if table does not yet exist
## Note: This step requires you have a reasonable amount of memory accessible 
## for docker. This can be changed in Docker > Preferences > Advanced 
## Memory should be set to > 4GB
if (!"flights" %in% db_tabs) {
  copy_to(con, nycflights13::flights, "flights",
    temporary = FALSE,
    indexes = list(
      c("year", "month", "day"),
      "carrier",
      "tailnum",
      "dest"
    )
  )
}
```

### 3. Create a reference to the data base that (db)plyr can work with


```r
flights_db <- tbl(con, "flights")
```

### 4. Query the data base using (db)plyr


```r
flights_db %>% select(year:day, dep_delay, arr_delay)
```

```
## # Source:   lazy query [?? x 5]
## # Database: postgres 10.6.0 [jovyan@127.0.0.1:8765/rsm-docker]
##     year month   day dep_delay arr_delay
##    <int> <int> <int>     <dbl>     <dbl>
##  1  2013     1     1         2        11
##  2  2013     1     1         4        20
##  3  2013     1     1         2        33
##  4  2013     1     1        -1       -18
##  5  2013     1     1        -6       -25
##  6  2013     1     1        -4        12
##  7  2013     1     1        -5        19
##  8  2013     1     1        -3       -14
##  9  2013     1     1        -3        -8
## 10  2013     1     1        -2         8
## # … with more rows
```

```r
flights_db %>% filter(dep_delay > 240)
```

```
## # Source:   lazy query [?? x 19]
## # Database: postgres 10.6.0 [jovyan@127.0.0.1:8765/rsm-docker]
##     year month   day dep_time sched_dep_time dep_delay arr_time
##    <int> <int> <int>    <int>          <int>     <dbl>    <int>
##  1  2013     1     1      848           1835       853     1001
##  2  2013     1     1     1815           1325       290     2120
##  3  2013     1     1     1842           1422       260     1958
##  4  2013     1     1     2115           1700       255     2330
##  5  2013     1     1     2205           1720       285       46
##  6  2013     1     1     2343           1724       379      314
##  7  2013     1     2     1332            904       268     1616
##  8  2013     1     2     1412            838       334     1710
##  9  2013     1     2     1607           1030       337     2003
## 10  2013     1     2     2131           1512       379     2340
## # … with more rows, and 12 more variables: sched_arr_time <int>,
## #   arr_delay <dbl>, carrier <chr>, flight <int>, tailnum <chr>,
## #   origin <chr>, dest <chr>, air_time <dbl>, distance <dbl>, hour <dbl>,
## #   minute <dbl>, time_hour <dttm>
```

```r
flights_db %>%
  group_by(dest) %>%
  summarise(delay = mean(dep_time))
```

```
## Warning: Missing values are always removed in SQL.
## Use `AVG(x, na.rm = TRUE)` to silence this warning
```

```
## # Source:   lazy query [?? x 2]
## # Database: postgres 10.6.0 [jovyan@127.0.0.1:8765/rsm-docker]
##    dest  delay
##    <chr> <dbl>
##  1 ABQ   2006.
##  2 ACK   1033.
##  3 ALB   1627.
##  4 ANC   1635.
##  5 ATL   1293.
##  6 AUS   1521.
##  7 AVL   1175.
##  8 BDL   1490.
##  9 BGR   1690.
## 10 BHM   1944.
## # … with more rows
```

```r
tailnum_delay_db <- flights_db %>% 
  group_by(tailnum) %>%
  summarise(
    delay = mean(arr_delay),
    n = n()
  ) %>% 
  arrange(desc(delay)) %>%
  filter(n > 100)

tailnum_delay_db
```

```
## Warning: Missing values are always removed in SQL.
## Use `AVG(x, na.rm = TRUE)` to silence this warning
```

```
## # Source:     lazy query [?? x 3]
## # Database:   postgres 10.6.0 [jovyan@127.0.0.1:8765/rsm-docker]
## # Ordered by: desc(delay)
##    tailnum delay     n
##    <chr>   <dbl> <dbl>
##  1 <NA>     NA    2512
##  2 N11119   30.3   148
##  3 N16919   29.9   251
##  4 N14998   27.9   230
##  5 N15910   27.6   280
##  6 N13123   26.0   121
##  7 N11192   25.9   154
##  8 N14950   25.3   219
##  9 N21130   25.0   126
## 10 N24128   24.9   129
## # … with more rows
```

```r
tailnum_delay_db %>% show_query()
```

```
## Warning: Missing values are always removed in SQL.
## Use `AVG(x, na.rm = TRUE)` to silence this warning
```

```
## <SQL>
## SELECT *
## FROM (SELECT *
## FROM (SELECT "tailnum", AVG("arr_delay") AS "delay", COUNT(*) AS "n"
## FROM "flights"
## GROUP BY "tailnum") "cdavsxvwuq"
## ORDER BY "delay" DESC) "rdsideantf"
## WHERE ("n" > 100.0)
```

```r
nrow(tailnum_delay_db)
```

```
## [1] NA
```

```r
tailnum_delay <- tailnum_delay_db %>% collect()
```

```
## Warning: Missing values are always removed in SQL.
## Use `AVG(x, na.rm = TRUE)` to silence this warning
```

```r
nrow(tailnum_delay)
```

```
## [1] 1201
```

```r
tail(tailnum_delay)
```

```
## # A tibble: 6 x 3
##   tailnum  delay     n
##   <chr>    <dbl> <dbl>
## 1 N494UA   -8.47   107
## 2 N839VA   -8.81   127
## 3 N706TW   -9.28   220
## 4 N727TW   -9.64   275
## 5 N3772H   -9.73   157
## 6 N3753   -10.2    130
```

### 5. Query the data using SQL

You can specify a SQL code chunk to query the database directly


```sql
SELECT * FROM flights WHERE dep_time > 2350
```


<div class="knitsql-table">


Table: Displaying records 1 - 10

 year   month   day   dep_time   sched_dep_time   dep_delay   arr_time   sched_arr_time   arr_delay  carrier    flight  tailnum   origin   dest    air_time   distance   hour   minute  time_hour           
-----  ------  ----  ---------  ---------------  ----------  ---------  ---------------  ----------  --------  -------  --------  -------  -----  ---------  ---------  -----  -------  --------------------
 2013       1     4       2358             2359          -1        429              437          -8  B6            727  N599JB    JFK      BQN          189       1576     23       59  2013-01-04 20:00:00 
 2013       1     4       2358             2359          -1        436              445          -9  B6            739  N821JB    JFK      PSE          199       1617     23       59  2013-01-04 20:00:00 
 2013       1     5       2355             2359          -4        425              442         -17  B6            707  N583JB    JFK      SJU          193       1598     23       59  2013-01-05 20:00:00 
 2013       1     5       2357             2359          -2        432              437          -5  B6            727  N649JB    JFK      BQN          195       1576     23       59  2013-01-05 20:00:00 
 2013       1     6       2353             2359          -6        441              445          -4  B6            739  N583JB    JFK      PSE          207       1617     23       59  2013-01-06 20:00:00 
 2013       1     6       2355             2359          -4        433              437          -4  B6            727  N708JB    JFK      BQN          199       1576     23       59  2013-01-06 20:00:00 
 2013       1     7       2359             2359           0        506              437          29  B6            727  N805JB    JFK      BQN          196       1576     23       59  2013-01-07 20:00:00 
 2013       1     8       2351             2359          -8        414              437         -23  B6            727  N563JB    JFK      BQN          185       1576     23       59  2013-01-08 20:00:00 
 2013       1     8       2351             2359          -8        417              444         -27  B6            739  N592JB    JFK      PSE          190       1617     23       59  2013-01-08 20:00:00 
 2013       1    12       2359             2359           0        429              437          -8  B6            727  N509JB    JFK      BQN          185       1576     23       59  2013-01-12 20:00:00 

</div>
