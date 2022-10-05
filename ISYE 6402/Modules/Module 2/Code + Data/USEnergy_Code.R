
################
library(TSA)
library(xts)
library(mgcv)
library(ggplot2)
library(dynlm)
library(astsa)
library(forecast)
library(lubridate)
###############

## Read the data
Electric_Monthly_Consump = read.csv("Electric_Monthly_ConsumpNew.csv")
dates = as.character(Electric_Monthly_Consump$DATE)
dates = as.Date(dates,format = "%m/%d/%y")
consumption = xts(Electric_Monthly_Consump[,2], as.Date(dates))
#consumption = ts(Electric_Monthly_Consump[,2],start=1985,freq=12)
plot(consumption, main="Monthly Electricity Consumption")

## Read Daily data
#if (FALSE){
#  US_Energy_Daily_Consump = read.csv("Electric_Daily_Consump.csv")
#  dates = as.Date(US_Energy_Daily_Consump$DATE, format="%m/%d/%Y")
#  consumption = xts(US_Energy_Daily_Consump[,2], as.Date(dates))
#}

#The time series displays an increasing variability over time
log.consumption = log(consumption)  
log.consumption = xts(log.consumption, as.Date(dates))
plot(log.consumption, main="Monthly Log Electricity Consumption")


#########################################################
# Exploratory Analysis
#########################################################
## Equally spaced time points
time.pts = c(1:length(index(consumption)))
time.pts = c(time.pts - min(time.pts))/max(time.pts)
## Splines Trend Estimation
#gam.fit = gam(consumption~s(time.pts))
#con.fit.gam = fitted(gam.fit)
gam.fit = gam(log.consumption~s(time.pts))
logcon.fit.gam = fitted(gam.fit)

x1 = time.pts
x2 = time.pts^2
log.lm.fit = lm(log.consumption~x1+x2)
summary(log.lm.fit)

mav.fit.log = ksmooth(time.pts, log.consumption, kernel = "box")
temp.fit.mav = ts(mav.fit.log$y,start=1985,frequency=12)
## Is there a trend? 
par(mfrow=c(1,1))
#plot(dates,consumption,type='l',lwd=2,ylab="Monthly Electricity Consumption")
#grid(lty=1, col=gray(.8))     
#lines(dates,consumption,lwd=2,ylab="Monthly Electricity Consumption")
#lines(dates,con.fit.gam,lwd=2,col="Brown")
plot(dates,log.consumption,type='l',ylab="Monthly Log Electricity Consumption")
grid(lty=1, col=gray(.8))  
lines(dates,log.consumption,lwd=2)
lines(dates,logcon.fit.gam,lwd=2,col="red")
lines(dates,fitted(log.lm.fit),lwd=2,col="blue")
lines(dates,temp.fit.mav,lwd=2,col="green")
legend('topleft', legend=c("Spline","Quad Polynomial","MA"),lty = 1, col=c("red","blue","Green"))

## Trend and seasonality together
seasons = as.factor(quarters(dates))
#gam.fit.trend.season = gam(consumption~s(time.pts)+seasons-1)
#summary(gam.fit.trend.season)
#fit.gam.seastr = fitted(gam.fit.trend.season)
log.gam.fit.trend.season = gam(log.consumption~s(time.pts)+seasons-1)
summary(log.gam.fit.trend.season)
log.fit.gam.seastr = fitted(log.gam.fit.trend.season)
seasons_month = as.factor(months(dates))
log.gam.fit.trend.month = gam(log.consumption~s(time.pts)+seasons_month-1)
summary(log.gam.fit.trend.month)
log.fit.gam.monthtr = fitted(log.gam.fit.trend.month)

## Is there a trend and seasonality? 
#plot(as.Date(dates), consumption,type='l',xlab="Time", ylab="Monthly Electricity Consumption")
#lines(as.Date(dates),con.fit.gam,lwd=2,col="Brown")
#lines(as.Date(dates),fit.gam.seastr,lwd=2,col="blue")

plot(as.Date(dates), log.consumption,type='l',xlab="Time", ylab="Monthly Log Electricity Consumption")
grid(lty=1, col=gray(.8))
lines(as.Date(dates), log.consumption)
lines(as.Date(dates),log.fit.gam.seastr,lwd=2,col="blue")
lines(as.Date(dates),logcon.fit.gam,lwd=2,col="red")
legend('topleft', legend=c("Spline+Quarterly","Spline"),lty = 1, col=c("blue","red"))

plot(as.Date(dates), log.consumption,type='l',xlab="Time", ylab="Monthly Log Electricity Consumption")
grid(lty=1, col=gray(.8))
lines(as.Date(dates), log.consumption)
lines(as.Date(dates),log.fit.gam.monthtr,lwd=2,col="blue")
lines(as.Date(dates),logcon.fit.gam,lwd=2,col="red")
legend('topleft', legend=c("Spline+Monthly","Spline"),lty = 1, col=c("blue","red"))

##Fit seasonality and cos-sin after removing trend
## ''harminic' command only takes a 'ts' time series 
log.consumption.ts = ts(log.consumption, start=1985, frequency = 12)
har.log = harmonic(log.consumption.ts,2)
model3.log=lm((log.consumption-logcon.fit.gam)~har.log-1)
summary(model3.log)
plot(dates,log.consumption,type='l',ylab="Monthly Log Electricity Consumption")
grid(lty=1, col=gray(.8))
lines(dates,log.consumption)
lines(dates,fitted(model3.log)+logcon.fit.gam,lwd=2,col="blue")
lines(as.Date(dates),logcon.fit.gam,lwd=2,col="red")
legend('topleft', legend=c("Spline+CosSin","Spline"),lty = 1, col=c("blue","red"))

## Residual Process: Trend Removal
par(mfrow=c(3,2))
acf(log.consumption-log.fit.gam.seastr, main="Trend+Quarterly Residuals ACF")
pacf(log.consumption-log.fit.gam.seastr, main="Trend+Quaterly Residuals PACF")
acf(log.consumption-log.fit.gam.monthtr, main="Trend+Monthly Residuals ACF")
pacf(log.consumption-log.fit.gam.monthtr, main="Trend+Monthly Residuals PACF")
#acf(log.consumption-fitted(model3.log)-logcon.fit.gam, main="Trend+CosSin Residuals ACF")
#pacf(log.consumption-fitted(model3.log)-logcon.fit.gam, main="Trend+CosSin Residuals ACF")

#########################################################
#Module 2 Material
#########################################################
#Take the difference
diff.consump <- diff(log.consumption,12)
diff.consump.1 <- diff(log.consumption,1)
#diff.consump = na.omit(diff.consump)
plot(diff.consump, main="12-Lag Difference Log Monthly Consump")
grid(lty=1, col=gray(.8))
lines(dates,diff.consump,lwd=5)
diff.consump <- diff.consump[-c(1:12)]
diff.consump.1 <- diff.consump.1[-c(1:12)]
par(mfrow=c(2,1))
acf(diff.consump.1,24,main="ACF: 1-Lag Difference Log Monthly Consump")
pacf(diff.consump.1,24,main="PACF: 1-Lag Difference Log Monthly Consump")
par(mfrow=c(2,1))
acf(diff.consump,24,main="ACF: 12-Lag Difference Log Monthly Consump")
pacf(diff.consump, 24,main="PACF: 12-Lag Difference Log Monthly Consump")


## Divide data into training (except last year) & testing (last year)
n_forward=52
n = length(diff.consump)
nfit = n-n_forward
diff.consump.train = diff.consump[1:nfit]

## Fit an ARMA model to the 12-lag difference time series with *d=1* 
n = length(diff.consump.train) 
norder = 13
p = c(1:norder)-1; q = c(1:norder)-1
aic = matrix(0,norder,norder)
for(i in 1:norder){
  for(j in 1:norder){
    modij = stats::arima(diff.consump.train,order = c(p[i],1,q[j]), method='ML')
    aic[i,j] = modij$aic-2*(p[i]+q[j]+1)+2*(p[i]+q[j]+1)*n/(n-p[i]-q[j]-2)
  }  
}
# Extract the "best" one according to AIC
aicv <- as.vector(aic)  
plot(aicv,ylab="AIC values")
indexp <- rep(c(1:norder),norder)
indexq <- rep(c(1:norder),each=norder)
indexaic <- which(aicv == min(aicv))
porder <- indexp[indexaic]-1
qorder <- indexq[indexaic]-1

## Fit an ARMA model to the 12-lag difference time series with *d=0* 
n = length(diff.consump.train) 
norder = 13
p = c(1:norder)-1; q = c(1:norder)-1
aic = matrix(0,norder,norder)
for(i in 1:norder){
  for(j in 1:norder){
    modij = stats::arima(diff.consump.train,order = c(p[i],0,q[j]), method='ML')
    aic[i,j] = modij$aic-2*(p[i]+q[j]+1)+2*(p[i]+q[j]+1)*n/(n-p[i]-q[j]-2)
  }  
}
# Extract the "best" one according to AIC
aicv <- as.vector(aic)  
plot(aicv,ylab="AIC values")
indexp <- rep(c(1:norder),norder)
indexq <- rep(c(1:norder),each=norder)
indexaic <- which(aicv == min(aicv))
porder <- indexp[indexaic]-1
qorder <- indexq[indexaic]-1


# Fit the "best" arima model
final_model <- arima(diff.consump.train, order = c(porder,0,qorder), method = "ML")

## GOF: residual analysis
par(mfrow=c(2,2))
resids <- resid(final_model)
plot(resids, ylab='Residuals',type='o',main="Residual Plot")
abline(h=0)
acf(resids,main="ACF: Residuals")
#pacf(resids,main="ACF: Residuals")
hist(resids,xlab='Residuals',main='Histogram: Residuals')
qqnorm(resids,ylab="Sample Q",xlab="Theoretical Q")
qqline(resids)
# Test and see if residuals are correlated
Box.test(final_model$resid, lag = (porder+qorder+1), type = "Box-Pierce", fitdf = (porder+qorder))
Box.test(final_model$resid, lag = (porder+qorder+1), type = "Ljung-Box", fitdf = (porder+qorder))

## Forecasting with ARMA, 1 Year (52 Weeks) Ahead: 

outpred = predict(final_model,n.ahead=n_forward)
ubound = outpred$pred+1.96*outpred$se #confidenec interval
lbound = outpred$pred-1.96*outpred$se
ymin = min(exp(lbound))
ymax = max(exp(ubound))
dates.diff = dates[-c(1:12)]
n = length(diff.consump)
plot((dates.diff)[(n-n_forward-20):n],exp(diff.consump[(n-n_forward-20):n]),type="l", ylim=c(ymin,ymax), xlab="Weeks", ylab="12-Lag Diff Log Consumption")
points((dates.diff)[(nfit+1):n],exp(outpred$pred),col="red")
lines((dates.diff)[(nfit+1):n],exp(ubound),lty=3,lwd= 2, col="blue")
lines((dates.diff)[(nfit+1):n],exp(lbound),lty=3,lwd= 2, col="blue")
legend('topleft', legend=c("1 Year Ahead ","Upper-Lower bound"),lty = 2, col=c("red","blue"))
## Compute Accuracy Measures
consump_true = as.vector(exp(diff.consump[(nfit+1):n]))
consump_pred = exp(outpred$pred)
### Mean Squared Prediction Error (MSPE)
mean((consump_pred-consump_true)^2)
### Mean Absolute Prediction Error (MAE)
mean(abs(consump_pred-consump_true))
### Mean Absolute Percentage Error (MAPE)
mean(abs(consump_pred-consump_true)/consump_true)
### Precision Measure (PM)
sum((consump_pred-consump_true)^2)/sum((consump_true-mean(consump_true))^2)
### Does the observed data fall outside the prediction intervals?
sum(consump_true<exp(lbound))+sum(consump_true>exp(ubound))

#### SARIMA Fit ##########################

norder=13
sorder=2
p = c(1:norder)-1; q = c(1:norder)-1
sp = c(1:norder)-1; sq = c(1:norder)-1
nfit.sarima=length(log.consumption.ts)-12
n = length(log.consumption)
log.consump.train=log.consumption.ts[1:nfit.sarima]

## hgher AR orders than 9 result in lack of convergence hence run the code for i in 1:10
## Select order for SARIMA: p = 0,.., 9; q = 0,..,12; *sp=0; qp=1*
aic_sarima_01=matrix(0,10,norder) 
for(i in 1:norder){
  for(j in 1:norder){
    sarima_model_select1 = astsa::sarima(log.consump.train, p[i], 0, q[j], sp[1], 1, sq[2], 12, details=FALSE, Model=FALSE)
    aic_sarima_01[i,j] = sarima_model_select1$AIC
  }
}
## hgher AR orders than 9 result in lack of convergence hence run the code for i in 1:10
## Select order for SARIMA: p = 0,.., 9; q = 0,..,12; *sp=0; qp=1*
## For some combinations of (p,q) orders, the SARIMA model does not converge
## you will need to skip those combinations
aic_sarima_10=matrix(0,10,norder) 
for(i in 1:norder){
  for(j in 1:norder){
    sarima_model_select2 = astsa::sarima(log.consump.train, p[i], 0, q[j], sp[2], 1, sq[1], 12, details=FALSE, Model=FALSE)
    aic_sarima_10[i,j] = sarima_model_select2$AIC
  }  
}

## hgher AR orders than 9 result in lack of convergence hence run the code for i in 1:10
## Select order for SARIMA: p = 0,.., 9; q = 0,..,12; *sp=0; qp=1*
## For some combinations of (p,q) orders, the SARIMA model does not converge
## you will need to skip those combinations
aic_sarima_11=matrix(0,10,norder)
for(i in 1:3){
  for(j in 1:norder){
    sarima_model_select3 = astsa::sarima(log.consump.train, p[i], 0, q[j], sp[2], 1, sq[2], 12, details=FALSE, Model=FALSE)
    aic_sarima_11[i,j] = sarima_model_select3$AIC
  }  
}

## SARIMA with p=3,d=0,q=12 & sp=1, sd=1,sq=1
sarima.consump = astsa::sarima(log.consumption.ts, 3,0,12, 1,1,1, 12)
## Predict one year ahead
sarima_1year = sarima.for(log.consumption.ts, 12, 3,0,12, 1,1,1, 12)

pred_SARIMA = sarima_1year$pred
true_SARIMA =log.consumption.ts[(nfit.sarima+1):n]


## Accuracy Measures
### Mean Squared Prediction Error (MSPE)
mean((pred_SARIMA-true_SARIMA)^2)
### Mean Absolute Prediction Error (MAE)
mean(abs(pred_SARIMA-true_SARIMA))
### Mean Absolute Percentage Error (MAPE)
mean(abs(pred_SARIMA-true_SARIMA)/true_SARIMA)
### Precision Measure (PM)
sum((pred_SARIMA-true_SARIMA)^2)/sum((true_SARIMA-mean(true_SARIMA))^2)

par(mfrow=c(1,1))
plot(dates[(n-n_forward-20):n],log.consumption.ts[(n-n_forward-20):n],type="l", xlab="Weeks", ylab="Log Consumption",main="SARIMA Forecasting")
grid(lty=1, col=gray(.8))
lines(dates[(n-n_forward-20):n],log.consumption.ts[(n-n_forward-20):n])
lines(dates[(nfit.sarima+1):n],sarima_1year$pred, col=2)



