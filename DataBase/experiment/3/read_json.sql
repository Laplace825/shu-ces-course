CREATE TABLE birthratetable
using org.apache.spark.sql.json
options (path "us_births_2016_2021.json");
