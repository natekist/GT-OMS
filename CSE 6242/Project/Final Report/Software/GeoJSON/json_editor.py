import pandas as pd
import json

df = pd.read_csv("main_data2.csv")

df['fips_complete'] = df['fips_complete'].map(str).apply(lambda x: x.zfill(5))

df['Single Family'] = df['Single Family'].fillna(0)
df['aqi'] = df['aqi'].fillna(0)
df['temp_mean_nsrdb'] = df['temp_mean_nsrdb'].fillna(0)

df.head()

ca_mapper_file = 'ca_mapper_file.geojson'

import json

with open("ca_counties.geojson") as f:
    data = json.load(f)

for feature in data['features']:
    fips5 = feature['properties']['STATE'] + feature['properties']['COUNTY']
    data_to_append = []
    for index, row in df.iterrows():
        if fips5 == row['fips_complete']:
            data_to_append.append([row['complete_date'], row['temp_mean_nsrdb'], row['aqi'], row['Single Family']])
    feature['properties']['timeseries'] = data_to_append
    
with open(ca_mapper_file, 'w+') as f:
    json.dump(data, f, indent=2)
