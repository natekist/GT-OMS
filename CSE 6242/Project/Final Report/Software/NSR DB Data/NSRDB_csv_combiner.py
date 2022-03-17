import pandas as pd
from pathlib import Path

source_files = sorted(Path("C:/Users/ps7pr/OneDrive/GA Tech - OMS Analytics/3. CLASSES/SEMESTER 3/6. CSE 6242/PROJECT/DATA/datasets/data_files_30").glob('*.csv'))

dataframes_list = []
for file in source_files:
    df = pd.read_csv(file) # additional arguments up to your needs
    df['lat'] = file.name.split(",")[0]
    df['lon'] = file.name.split(",")[1]
    df['year2'] = file.name.split(",")[2]
    df['FIPS'] = file.name.split(",")[3].split(".")[0]
    dataframes_list.append(df)

df_all = pd.concat(dataframes_list)

df_all.to_csv('NSRDB_30_minute_CA_counties.csv', index=False)
