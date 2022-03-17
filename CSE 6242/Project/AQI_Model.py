import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt 
from pmdarima import auto_arima


df = pd.read_csv("aqi_data.csv")## READ CSV

df['Date'] = pd.to_datetime(df["date_aqi"]) ## MAKE DATETIME COLUMN
df = df[~df['county_aqi'].isin(['Alpine', 'Lassen', 'Modoc', 'Sierra'])]


df ## CHECK 


 county_unique = df['county_aqi'].unique()

 aqi_predictions = {'Date': [], 'County': [], 'Estimated Avg. AQI': []}
aqi_predictions_df = pd.DataFrame(aqi_predictions)

future_dates = pd.date_range(start="2021-01-01",end="2030-12-31").tolist() ## CREATE LIST OF DAILY DATE_RANGE 
future_dates_df = pd.DataFrame(future_dates, columns=['Dates']) ## CONVERT TO DATAFRAME WITH COLUMN 'DATES' 
future_dates_df['new_col'] = 1 ## ADD DUMMY NUMERICAL COLUMN SO .MEAN() WORKS
future_dates_df = future_dates_df.set_index('Dates') ## SET DATE INDEX
future_dates_df = future_dates_df.resample('1M').mean() ## AGGREGATE DATA AT MONTHLY LEVEL
future_dates_df = future_dates_df.dropna()
dates_list = []
for index, row in future_dates_df.iterrows(): ## FOR-LOOP TO APPEND DATES TO DATES_LIST 
    dates_list.append(index.date())
# print(len(dates_list)) ## CHECK


county_list = []
for i in county_unique: ## FOR-LOOP LOOPS OVER FIPS_UNIQUE & APPENDS TO FIPS_LIST
    county_list.append(i) 
optimal_models = []


historical_monthly = {'date_col': [], 'county': [], 'aqi_mean': []} 
historical_monthly_df = pd.DataFrame(historical_monthly)

 for i in county_unique: ## LOOPING OVER FIPS_UNIQUE
        relevant_dataset = df[df['county_aqi'] == i] ## FILTERING DATAFRAME FOR RELEVANT FIPS
        relevant_dataset = relevant_dataset.set_index('Date')
        relevant_dataset = relevant_dataset.resample('1M').mean()
        relevant_dataset = relevant_dataset.dropna()
        temporary_historical_df = relevant_dataset.copy()
        temporary_historical_df['date_col'] = temporary_historical_df.index ## SIMPLE DF COLS FOR HISTORICAL MONTH
        temporary_historical_df['county'] = i
        historical_monthly_df = historical_monthly_df.append(temporary_historical_df)
        
        stepwise_model = auto_arima(relevant_dataset['aqi'], start_p=1, start_q=1, max_p=5, max_q=5,
                                    m=12, start_P=0, seasonal=True, trace=True, error_action='ignore',
                                    suppress_warnings=True) ## SET UP AUTO_ARIMA FUNCTION
        optimal_models.append(str(stepwise_model).strip()) ## APPEND OPTIMAL MODEL TO LIST FOR MODEL INFO DF
        train = relevant_dataset.iloc[:-24] ## SPLIT INTO TRAINING & TESTING DATASETS
        test = relevant_dataset.iloc[-24]
        model = stepwise_model.fit(train) ## APPLY AUTO_ARIMA() TO TRAINING DATA
        future_forecast = stepwise_model.predict(n_periods = 144) ## GENERATE FUTURE MONTHLY FORECASTS
        future_forecast = future_forecast[24:] ## EXCLUDE FIRST 24 AS WE ARE NOT VALIDATING ANYMORE
        
        predictions_df = pd.DataFrame({'Date': dates_list, 'Estimated Avg. AQI': future_forecast, 'County': i})
        
        aqi_predictions_df = aqi_predictions_df.append(predictions_df) ## APPEND TO FINAL DF



county_models_df = pd.DataFrame({'County': county_list, 'Optimal Model': optimal_models})
county_models_df.to_csv('aqi_models.csv', index=False) ## GENERATE CSV FILE FROM ABOVE DF (MODEL INFO)


aqi_predictions_df.to_csv('aqi_predictions.csv', index=False) ## GENERATE CSV FILE 

historical_monthly_df.to_csv('aqi_historical_monthly.csv', index=False) ## GENERATE CSV FILE 