import pandas as pd
import numpy as np
import sys, os 
from IPython.display import display

api_key = 'NEv1SzEsD5Jqle7CMW37qJhs2iHGuuJs5Cjidys6'
attributes = 'clearsky_dhi,clearsky_dni,clearsky_ghi,ghi,dhi,dni,wind_speed,air_temperature,solar_zenith_angle'
leap_year = 'false'
interval = '30'
utc = 'false'
your_name = 'Preston+Slane'
reason_for_use = 'class+project'
your_affiliation = 'GA+Tech'
your_email = 'ps7preston@gmail.com'
mailing_list = 'false'

lat_long_year_info = pd.read_excel('latlongs_years_for_api.xlsx', index_col=None)

print(lat_long_year_info)

for index, row in lat_long_year_info.iterrows():
    lat, lon, year, fips = row['lat'], row['lon'], row['year'], row['FIPS5']
    url = 'https://developer.nrel.gov/api/solar/nsrdb_psm3_download.csv?wkt=POINT({lon}%20{lat})&names={year}&leap_day={leap}&interval={interval}&utc={utc}&full_name={name}&email={email}&affiliation={affiliation}&mailing_list={mailing_list}&reason={reason}&api_key={api}&attributes={attr}'.format(year=year, lat=lat, lon=lon, leap=leap_year, interval=interval, utc=utc, name=your_name, email=your_email, mailing_list=mailing_list, affiliation=your_affiliation, reason=reason_for_use, api=api_key, attr=attributes)
    df_name = str(lat) + ',' + str(lon) + ',' + str(year) + ',' + str(fips)
    df = pd.read_csv(url, skiprows=2)
    df = df.set_index(pd.date_range('1/1/{yr}'.format(yr=year), freq=interval+'Min', periods=525600/int(interval)))
    df.to_csv(df_name+".csv", index=False)
