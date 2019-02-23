library(DBI)
library(RPostgreSQL)
con <- dbConnect(
  dbDriver("PostgreSQL"),
  user = "jovyan",
  host = "127.0.0.1",
  port = 8765,
  dbname = "rsm-docker",
  password = "postgres"
)

library(dplyr)

## show list of tables
dbListTables(con)

## add a table to the dbase
if (!"mtcars" %in% db_tabs) {
  copy_to(con, mtcars, "mtcars", temporary = FALSE)
}

## extra data from dbase connection
dat <- tbl(con, "mtcars")
dat

## show updated list of tables
dbListTables(con)

## drop a table
db_drop_table(con, table = 'mtcars')

## show updated list of tables
dbListTables(con)
