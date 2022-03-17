import pandas as pd

thirty_min_db = pd.read_csv("NSRDB_30_minute_CA_counties.csv")
thirty_min_db.head()

print(f'{len(thirty_min_db):,}')

new_db_thirty = thirty_min_db.groupby(['Year', 'Month', 'Day', 'lat', 'lon', 'FIPS']).agg({'Temperature': ['mean'], 'Clearsky DHI': ['mean'], 'Clearsky DNI': ['mean'], 'Clearsky GHI': ['mean'], 
           'GHI': ['mean'], 'DHI': ['mean'], 'DNI': ['mean'], 'Wind Speed': ['mean']})

new_db_thirty.columns = ['temp_mean', 'clearsky_dhi_mean', 'clearsky_dni_mean', 'clearsky_ghi_mean', 'ghi_mean', 
                 'dhi_mean', 'dni_mean', 'wind_speed_mean']

new_db_thirty = new_db_thirty.reset_index()

print(f'{len(new_db_thirty):,}')

new_db_thirty.head()

new_db_thirty.to_csv('30_min_agg_daily_CA_counties.csv', index=False)
