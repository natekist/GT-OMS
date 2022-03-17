DESCRIPTION:
With the following set-up, a user will be able to re-create our project "Visualizing the Impact of Climate Change on Housing Prices in California."
Final visualization will be in Tableau.

INSTALLATION:

First, the user should be able to download and extract all relevant datasets from the appropriate sources:
	1. Housing Prices (Direct Download): https://www.zillow.com/research/data/
	2. Temperature and Precipitable Water (Obtain through API): https://nsrdb.nrel.gov/data-sets/api-instructions.html
	3. AQI (Direct Download): https://aqs.epa.gov/aqsweb/airdata/download_files.html#AQI

OBTAIN PRECIPITATION AND TEMPERATURE DATA VIA API:
	- Detailed instructions for working with NSRDB API can be found here: https://nsrdb.nrel.gov/data-sets/api-instructions.html and outlined below:
	1. First one must register for a NSRDB API key for the queries to validate: https://developer.nrel.gov/signup/
	2. For mass downloads, it is recommended to create a helper file with columns LAT | LON | YEAR | FIPS. This way, one can loop through the rows and query each county/year combination quickly. One has been provided (latlongs_years_for_api.xlsx), for all counties in CA and years 2010 -> 2020 as per the analysis.
	3. Use Python (data_api_downloader.py) to perform the API query as succinctly outlined on the NSRDB API page, which results in 638 CSV files (58 counties * 11 years (2010 --> 2020) = 638 files)
	4. Use Python (data_csv_combiner.py) to combine all 638 CSV files into a singular CSV file (~590 MB)
	5. Use Python (data_aggergator.py) to aggregate the data from raw 30-minute intervals to daily invervals, thus shrinking file size to (~19 MB)

After obtaining data from the above resources, we will have 3 raw data CSVs to start with. All 3 csvs are stored in the "Data before prediction" folder:
	1. historical_aqi.csv (direct download)
	2. historical_nsrdb.csv - containing precipitation and temperature (API)
	3. historical_zillow.csv (direct download)

DATA MODELLING AND FUTURE PROJECTIONS
All code used for the modeling portion of the project is performed in Python.  For this portion, we recommend using Jupyter Notebook and Python >= 3.7.  
Packages needed:
	- pandas
	- datetime
	- pmdarima
	- matplotlib.pyplot
	- numpy
	- multiprocessing


Run AQI_Model.py for AQI Forecasts
Run Temp_Model.py for Temperature Forecasts
Run HousingPriceSF_Model.py for SF Housing Price Forecasts
Run HousingPricesCondo_Model.py for Condo Housing Price Forecasts
Run Precip_Model.py for Precipitation Forecasts

    
COMBINING DATA AND MODIFICATIONS
- For historical AQI, Precipitable Water and Temperature, modify the data to show a monthly average for each county. 
- For historical Zillow housing data, we started with two categories: Single Family Average Monthly prices, and Condo Average Monthly prices. We averaged both to get an overall average housing price for each county
- Manually combine the historical CSVs with the prediction CSVs. The prediction CSVs are in the folder titled "Predictions":
	a) predict_precipitable_water.csv
	b) predict_temperature.csv
	c) zillow_condo_predictions.csv
	d) zillow_singlefamily_predictions.csv
	e) predict_aqi.csv
- The result will be 4 different CSVs with both historical and predicted values, at a county and monthly level. The final CSVs are stored in a folder called "Historical and Predictions Combined". The CSVs are:
	a) aqi.csv
	b) precipitation.csv
	c) temperature.csv
	d) zillow.csv
- Other basic cleaning was also performed in excel such as changing column header names, changing date formats or FIPS format into a four digit combination where needed

OTHER RAW DATA:
We created date_counties.csv to help with joining. The content of this CSV is a list of dates from 2010-2030 that is cross-joined with each of California's 58 counties. This data will serve as the table containing unique keys in our SQL joins.

CREATING COMBINED DATASET
- We used SQLite to combine all 5 CSVs we have so far (aqi, precipitation, temperature, zillow and date_counties). The SQLite database is included: project_database_monthly.sqbpro
- After joining all 5 csvs in SQLite, we export the result into a csv. We then add columns to that csv that calculates the score for each climate factor
- The scores are calculated based on our scoring matrix, refer to the scoring.xlsx file
- The final file is saved as an excel file : final_dataset_with_formulas.xlsx.


EXECUTION:
Download Tableau desktop or use Tableau web.

Final dashboard:
https://public.tableau.com/views/CSE6242FINALVIZ/FinalDashboard

Final dashboard workbook:
"CSE6242 FINAL VIZ.twbx"


