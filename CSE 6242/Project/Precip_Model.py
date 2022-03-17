import pandas as pd
import matplotlib
from matplotlib import pyplot as plt
import sys, os
import numpy as np
from pmdarima import auto_arima
from multiprocessing import Process, Value
import calendar

## READ DATA
def load(fname):
    df=pd.read_csv(fname,header=0, usecols=['date_nsrdb','fips_nsrdb','precipitable_water_mean_nsrdb'])
    df=df.dropna()
    df['date_nsrdb'] = pd.to_datetime(df['date_nsrdb'],format="%m/%d/%y")
    df = df.set_index(['fips_nsrdb','date_nsrdb'])
    return df

## TESTING
def fit_arima_m(y, fips, m, aic_out, plot=True):
    end = int(0.8 * len(y))
    train = y.iloc[:end]
    test = y.iloc[end-1:]
    model = auto_arima(train, start_p=1, start_q=1,
                        max_p=5, max_q=5,
                        start_P=0, seasonal=True,
                        m=m,
                        d=1, D=1, trace=True,
                        error_action='ignore',
                        suppress_warnings=True)
    
    aic_out.value = model.aic()
    
    f = open(fips + '/' + fips + '_' + str(m) + '_summary.csv', 'w')
    f.write(model.summary().as_csv())
    f.close()
    
    if plot:
        pred = np.hstack((model.predict_in_sample()[1:], model.predict(n_periods=len(test))))
        # pred_in_sample = pd.DataFrame({'date_nsrdb' : y.index[:end],
        #                                 'Predict in Sample' : pred[:end]}).set_index('date_nsrdb')
        future_forecast = pd.DataFrame({'date_nsrdb' : y.index[end-1:],
                                        'Predict in Sample' : pred[end-1:]}).set_index('date_nsrdb')
        
        plt.rc('font', family='serif')
        plt.rc('xtick', labelsize='large')
        plt.rc('ytick', labelsize='large')
        plt.figure(figsize=(12, 8))
        plt.plot(train,label="Training", color='blue', alpha=0.5, linewidth=2.5, linestyle='-')
        plt.plot(test,label="Test", color='green', alpha=0.5, linewidth=2, linestyle='-')
        plt.plot(future_forecast,label="Predicted", color='red', alpha=0.5, linewidth=2, linestyle='-')
        # plt.plot(pred_in_sample,label="Predict in Sample", color='orange', alpha=0.5, linewidth=2, linestyle='-')
        plt.xlabel('Measurement Date', fontsize="x-large")
        plt.ylabel('Precipitable Water', fontsize="x-large")
        plt.legend(loc = 'upper left')
        plt.title('Fitted ARIMA Model for Alameda County Precipitable Water')
        plt.savefig(fips + '/' + fips + '_' + str(m) + '_predict.pdf')

def predict_arima(df, fips, m, dates, resample='Q'):
    y = df.xs(int(fips)).interpolate('linear').resample(resample).mean()
    model = auto_arima(y, start_p=1, start_q=1,
                        max_p=5, max_q=5,
                        start_P=0, seasonal=True,
                        m=m,
                        d=1, D=1, trace=True,
                        error_action='ignore',
                        suppress_warnings=True)
    return pd.DataFrame({'date':dates,
                        'fips': 120*[fips],
                        'precipitable_water': model.predict(n_periods=120)})

def fit_arima(df, fips, m_range=None, resample='1M', plot=True):
    y = df.xs(int(fips)).interpolate('linear').resample(resample).mean()
    
    # Data conditionining to make slightly more periodic
    if m_range is None:
        m_range = [12]
    fips = str(fips) + '_' + resample
    
    if not os.path.exists(fips):
        os.makedirs(fips)

    if len(m_range) > 1:
        aics = []
        aic_i = []
        for m in m_range:
            aic = Value('d', 0.0, lock=False)
            p = Process(target=fit_arima_m, args=(y, fips, m, aic, plot))
            p.start()
            p.join()
            if aic.value > 0:
                aics.append(aic.value)
                aic_i.append(m)
        return aic_i, aics
    else:
        aic = Value('d', 0.0, lock=False)
        fit_arima_m(y, fips, m_range[0], aic, plot)
        aic_i = m_range[0]
        return m_range, [aic.value]        

def main(argv):
    df = load('nsrdb.csv')
    
    if len(argv) > 0:
        fips = int(argv[0])
        aic_i, aic = fit_arima(df, fips, range(1,30), '1M')
        print(aic)
        i = np.argmin(aic)
        print(aic_i[i])
        print(aic[i])
    else:
        # Setup
        fips_range = df.index.unique(0)
        dates = []
        for year in range(2021, 2031):
            for month in range(1,13):
                dates.append(str(year) + str(month) + str(calendar.monthrange(year,month)[1]))
        predict_dates = pd.to_datetime(dates, format='%Y%m%d')
        
        # Iterate through each fips
        predict_y = pd.DataFrame(columns=['date','fips','precipitable_water'])
        # for fips in [fips_range[0]]:
        for fips in fips_range:
            aic_i, aic = fit_arima(df, fips, range(1,30), '1M', plot=False)
            m = aic_i[np.argmin(aic)]
            pred = predict_arima(df, fips, m, predict_dates, resample='1M')
            predict_y = predict_y.append(pred)
        
        # Write to csv
        predict_y.to_csv('predict_precipitable_water.csv', index=False)
        

if __name__ == "__main__":
    main(sys.argv[1:])
    # main()
