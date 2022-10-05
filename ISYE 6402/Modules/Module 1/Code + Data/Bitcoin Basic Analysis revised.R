
library(xts)
install.packages("tseries")
library(tseries)
install.packages("mgcv")
library(mgcv)

#======================== Import & Process Data ========================
# BTC-USD data
databtc=read.csv('BTCUSD.csv',header = TRUE)
pricebtc=databtc[,c(5)]
## check the structure of the dates to specify the dates in the command below
mydates = as.Date(databtc[, 1], "%m/%d/%Y")
tsbtc = xts(pricebtc, mydates)
dlbtc=diff(log(tsbtc))

par(mfrow=c(2,1))
plot(tsbtc,main='BTC-USD')
acf(tsbtc,main='ACF of BTC')

#Differenced Log Time Series
plot(dlbtc,main='Diff_log_BTC')
acf(dlbtc[-1],main='')

## Stationarity Test: Kwiatkowski-Phillips-Schmidt-Shin (KPSS) test
## Null Hypothesis: Stationary Time Series
kpss.test(dlbtc[-1])
# Dickey-Fuller test
## Null Hypothesis: Non-Stationary Time Series
adf.test(dlbtc[-1], alternative = "stationary")

par(mfrow=c(1,1))
## Trend Estimation for original time series
time.pts = c(1:length(mydates))
time.pts = c(time.pts - min(time.pts))/max(time.pts)
## Local Polynomial Trend Estimation
loc.fit = loess(pricebtc~time.pts)
price.fit.loc = fitted(loc.fit)
loc.tsbtc=xts(price.fit.loc,mydates)
## Splines Trend Estimation
gam.fit = gam(pricebtc~s(time.pts))
summary(gam.fit)
price.fit.gam = fitted(gam.fit)
fit.tsbtc=xts(price.fit.gam,mydates)
plot(tsbtc,main='BTC-USD')
lines(fit.tsbtc,lwd=2,col="red")
lines(loc.tsbtc,lwd=2,col="brown")

## Is there a seasonality? 
month = as.factor(format(mydates,"%b"))
gam.fit.seastr.1 = gam(pricebtc~s(time.pts)+month)
summary(gam.fit.seastr.1)
fitseastr.tsbtc=xts(fitted(gam.fit.seastr.1),mydates)
plot(tsbtc,main='BTC-USD')
lines(fit.tsbtc,lwd=2,col="red")
lines(fitseastr.tsbtc,lwd=2,col="blue")

## Trend Estimation for the log differenced time series
## Splines Trend Estimation
diff.ts <- diff(log(pricebtc))
gam.fit.dif = gam(diff.ts~s(time.pts[-1]))
summary(gam.fit.dif)
difprice.fit.gam = fitted(gam.fit.dif)
fit.tsbtc.dif=xts(difprice.fit.gam,mydates[-1])
plot(dlbtc,main='BTC-USD - Log Difference')
lines(fit.tsbtc.dif,lwd=2,col="purple")

diff.ts.sq <- diff.ts^2 
gam.fit.dif.sq = gam(diff.ts.sq~s(time.pts[-1]))
summary(gam.fit.dif.sq)
difprice.fit.gam = fitted(gam.fit.dif.sq)
fit.tsbtc.dif=xts(difprice.fit.gam,mydates[-1])
plot(dlbtc^2,main='Log Difference Squared',ylim=c(0,0.06))
lines(fit.tsbtc.dif,lwd=2,col="purple")