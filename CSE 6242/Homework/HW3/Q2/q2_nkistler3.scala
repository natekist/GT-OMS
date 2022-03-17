// Databricks notebook source
// STARTER CODE - DO NOT EDIT THIS CELL
import org.apache.spark.sql.functions.desc
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import spark.implicits._
import org.apache.spark.sql.expressions.Window

// COMMAND ----------

// STARTER CODE - DO NOT EDIT THIS CELL
val customSchema = StructType(Array(StructField("lpep_pickup_datetime", StringType, true), StructField("lpep_dropoff_datetime", StringType, true), StructField("PULocationID", IntegerType, true), StructField("DOLocationID", IntegerType, true), StructField("passenger_count", IntegerType, true), StructField("trip_distance", FloatType, true), StructField("fare_amount", FloatType, true), StructField("payment_type", IntegerType, true)))

// COMMAND ----------

// STARTER CODE - YOU CAN LOAD ANY FILE WITH A SIMILAR SYNTAX.
val df = spark.read
   .format("com.databricks.spark.csv")
   .option("header", "true") // Use first line of all files as header
   .option("nullValue", "null")
   .schema(customSchema)
   .load("/FileStore/tables/nyc_tripdata.csv") // the csv file which you want to work with
   .withColumn("pickup_datetime", from_unixtime(unix_timestamp(col("lpep_pickup_datetime"), "MM/dd/yyyy HH:mm")))
   .withColumn("dropoff_datetime", from_unixtime(unix_timestamp(col("lpep_dropoff_datetime"), "MM/dd/yyyy HH:mm")))
   .drop($"lpep_pickup_datetime")
   .drop($"lpep_dropoff_datetime")

// COMMAND ----------

// LOAD THE "taxi_zone_lookup.csv" FILE SIMILARLY AS ABOVE. CAST ANY COLUMN TO APPROPRIATE DATA TYPE IF NECESSARY.
// ENTER THE CODE BELOW

val customSchema2 = StructType(Array(StructField("LocationID", IntegerType, true), StructField("Borough",StringType,true), StructField("Zone",StringType,true), StructField("service_zone",StringType,true)))
val df2 = spark.read
   .format("com.databricks.spark.csv")
   .option("header", "true") // Use first line of all files as header
   .option("nullValue", "null")
   .schema(customSchema2)
   .load("/FileStore/tables/taxi_zone_lookup.csv") // the csv file which you want to work with

df2.show(5)

// COMMAND ----------

// STARTER CODE - DO NOT EDIT THIS CELL
// Some commands that you can use to see your dataframes and results of the operations. You can comment the df.show(5) and uncomment display(df) to see the data differently. You will find these two functions useful in reporting your results.
// display(df)
df.show(5) // view the first 5 rows of the dataframe

// COMMAND ----------

// STARTER CODE - DO NOT EDIT THIS CELL
// Filter the data to only keep the rows where "PULocationID" and the "DOLocationID" are different and the "trip_distance" is strictly greater than 2.0 (>2.0).

// VERY VERY IMPORTANT: ALL THE SUBSEQUENT OPERATIONS MUST BE PERFORMED ON THIS FILTERED DATA

val df_filter = df.filter($"PULocationID" =!= $"DOLocationID" && $"trip_distance" > 2.0)
df_filter.show(5)

// COMMAND ----------

// PART 1a: The top-5 most popular drop locations - "DOLocationID", sorted in descending order - if there is a tie, then one with lower "DOLocationID" gets listed first
// Output Schema: DOLocationID int, number_of_dropoffs int 

// Hint: Checkout the groupBy(), orderBy() and count() functions.

// ENTER THE CODE BELOW

val DO = df_filter.groupBy("DOLocationID")
  .agg(
    count("DOLocationID").cast("int").as("number_of_dropoffs")
).sort(desc("number_of_dropoffs"), asc("DOLocationID"))

DO.show(5)

// COMMAND ----------

// PART 1b: The top-5 most popular pickup locations - "PULocationID", sorted in descending order - if there is a tie, then one with lower "PULocationID" gets listed first 
// Output Schema: PULocationID int, number_of_pickups int

// Hint: Code is very similar to part 1a above.

// ENTER THE CODE BELOW
val PU = df_filter.groupBy("PULocationID")
  .agg(
    count("PULocationID").cast("int").as("number_of_pickups")
).sort(desc("number_of_pickups"), asc("PULocationID"))

PU.show(5)

// COMMAND ----------

// PART 2: List the top-3 locations with the maximum overall activity, i.e. sum of all pickups and all dropoffs at that LocationID. In case of a tie, the lower LocationID gets listed first.
// Output Schema: LocationID int, number_activities int

// Hint: In order to get the result, you may need to perform a join operation between the two dataframes that you created in earlier parts (to come up with the sum of the number of pickups and dropoffs on each location). 

// ENTER THE CODE BELOW

val PUDO = PU.join(DO, DO("DOLocationID") === PU("PULocationID")).select("PULocationID", "number_of_pickups", "number_of_dropoffs")
val total = PUDO.withColumn("number_activities", PUDO("number_of_pickups") + PUDO("number_of_dropoffs")).select(col("PULocationID").alias("LocationID"), col("number_activities")).sort(desc("number_activities"), asc("LocationID"))

total.show(3)

// COMMAND ----------

// PART 3: List all the boroughs in the order of having the highest to lowest number of activities (i.e. sum of all pickups and all dropoffs at that LocationID), along with the total number of activity counts for each borough in NYC during that entire period of time.
// Output Schema: Borough string, total_number_activities int

// Hint: You can use the dataframe obtained from the previous part, and will need to do the join with the 'taxi_zone_lookup' dataframe. Also, checkout the "agg" function applied to a grouped dataframe.

// ENTER THE CODE BELOW
val total_by_borough = total.join(df2, total("LocationID") === df2("LocationID")).groupBy("Borough")
  .agg(
    sum("number_activities").cast("int").as("total_number_activites")
).sort(desc("total_number_activites"))

total_by_borough.show(true)

// COMMAND ----------

// PART 4: List the top 2 days of week with the largest number of (daily) average pickups, along with the values of average number of pickups on each of the two days. The day of week should be a string with its full name, for example, "Monday" - not a number 1 or "Mon" instead.
// Output Schema: day_of_week string, avg_count float

// Hint: You may need to group by the "date" (without time stamp - time in the day) first. Checkout "to_date" function.

// ENTER THE CODE BELOW
val df_part4 = df_filter.withColumn("pickup_date", to_date(col("pickup_datetime"))).groupBy("pickup_date").agg(count("PULocationID").cast("int").as("count")).withColumn("day_of_week", date_format(col("pickup_date"), "EEEE")).groupBy("day_of_week").agg(avg("count").cast("float").as("avg_count")).sort(desc("avg_count"))

df_part4.show(5)

// COMMAND ----------

// PART 5: For each particular hour of a day (0 to 23, 0 being midnight) - in their order from 0 to 23, find the zone in Brooklyn borough with the LARGEST number of pickups. 
// Output Schema: hour_of_day int, zone string, max_count int

// Hint: You may need to use "Window" over hour of day, along with "group by" to find the MAXIMUM count of pickups

// ENTER THE CODE BELOW
val df_part5 = df_filter.join(df2, df_filter("PULocationID") === df2("LocationID"))
val df_part5_B = df_part5.filter($"Borough" === "Brooklyn").withColumn("hour", hour(col("pickup_datetime"))).groupBy("Hour", "Zone").agg(count("PULocationID").cast("int").as("count")).sort(asc("Hour"), asc("Zone"))

val df_rank = df_part5_B.
      select(col("hour"),
        col("zone"),
        col("count"),
        rank().over(Window.partitionBy(col("hour")).orderBy(col("count").desc)).as("rank"))

val df_ans = df_rank.filter(col("rank") === 1).select(col("hour"), col("zone"), col("count").as("max_count")).sort(asc("hour")).show(24, truncate = false)

// COMMAND ----------

// PART 6 - Find which 3 different days of the January, in Manhattan, saw the largest percentage increment in pickups compared to previous day, in the order from largest increment % to smallest increment %. 
// Print the day of month along with the percent CHANGE (can be negative), rounded to 2 decimal places, in number of pickups compared to previous day.
// Output Schema: day int, percent_change float


// Hint: You might need to use lag function, over a window ordered by day of month.

// ENTER THE CODE BELOW

val df_part6 = df_filter.join(df2, df_filter("PULocationID") === df2("LocationID"))
val df_part6_B = df_part5.withColumn("month", month(col("pickup_datetime"))).withColumn("day", dayofmonth(col("pickup_datetime"))).filter($"Borough" === "Manhattan" && $"month" === 1).groupBy("day").agg(count("PULocationID").cast("int").as("count")).sort(asc("day"))

val df_part6_C = df_part6_B
         .withColumn("Lag", lag("count", 1).over(Window.orderBy("day")))
        .withColumn("percent_change", ((col("count") - col("Lag"))/col("Lag")) * 100)
        .select(col("day"), round(col("percent_change"), 2).cast("float").as("percent_change"))
        .orderBy(desc("percent_change"))

df_part6_C.show(3)

// COMMAND ----------


