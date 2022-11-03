## Simulation: Independent vs Uncorrelated TS: Lesson 2

a0 <- 0.2
a1 <- 0.5
b1 <- 0.3
w <- rnorm(5000)
eps <- rep(0, 5000)
sigsq = rep(0, 5000)
for (i in 2:5000) {
    sigsq[i] <- a0 + a1 * (eps[i-1]^2) + b1 * sigsq[i-1]
    eps[i] <- w[i]*sqrt(sigsq[i])
}
## Plot the acf of the time series and squared time series
acf(eps)
acf(eps^2)

##### Data Examples for Concept Slides ######################

## Financial Data Analysis
library(quantmod)
library(xts)
## Get the daily traiding data for PDCE
getSymbols("PDCE",src="yahoo")
mydates = row.names(as.data.frame(PDCE))
mydates=as.Date(mydates,"%Y-%m-%d")
candleChart(PDCE,multi.col=TRUE,theme="white")
## Log returns of the close price
pdcert <- diff(log(Cl(PDCE)))
plot(pdcert,main="")

###############################################################################
## Fit ARIMA
n <- length(pdcert)

test_modelA <- function(p,d,q){
    mod = arima(pdcert, order=c(p,d,q), method="ML")
    current.aic <- AIC(mod)
    current.aic<-current.aic-2*(p+q+1)+2*(p+q+1)*n/(n-p-q-2)
    df = data.frame(p,d,q,current.aic)
    names(df) <- c("p","d","q","AIC")
    print(paste(p,d,q,current.aic,sep=" "))
    return(df)
}

orders <- data.frame(Inf,Inf,Inf,Inf)
names(orders) <- c("p","d","q","AIC")
for (p in 0:6){
    for(d in 0:1) {
        for (q in 0:6) {
            possibleError <- tryCatch(
                orders<-rbind(orders,test_modelA(p,d,q)),
                error=function(e) e
            )
            if(inherits(possibleError, "error")) next
        }
    }
}
orders <- orders[order(-orders$AIC),]
tail(orders)
select.arima <- arima(pdcert, order=c(4,0,4))
pars.arima <- arima(pdcert, order=c(0,1,1))


## Residual Analysis
select.resids <- resid(select.arima)[-1]
pars.resids <- resid(pars.arima)[-1]
acf(select.resids,main="Residuals of Selected ARIMA")
acf(select.resids^2,main="Squared Residuals of Selected ARIMA")
acf(pars.resids,main="Residuals of Parsimonious ARIMA")
acf(pars.resids^2,main="Squared Residuals of Parsimonious ARIMA")

qqnorm(select.resids)
qqline(select.resids, col="blue")
hist(select.resids,main="Residuals: Selected ARIMA")
qqnorm(pars.resids)
qqline(pars.resids, col="blue")
hist(select.resids,main="Residuals: Parsimonious ARIMA")

# test for serial correlation in residuals
Box.test(select.resids,lag=9,type='Ljung',fitdf=8)
Box.test(pars.resids,lag=3,type='Ljung',fitdf=2)
# test for serial correlation in squared residuals
Box.test((select.resids)^2,lag=9,type='Ljung',fitdf=8)
Box.test((pars.resids)^2,lag=3,type='Ljung',fitdf=2)

## Estimate the variance using nonparametric regression
library(mgcv)
zt.ssq.log = log(select.resids^2)
n = length(select.resids)
time.pts = c(1:n)
time.pts = (time.pts-min(time.pts))/(max(time.pts)-min(time.pts))
gam.var.select = gam(zt.ssq.log~s(time.pts))
pdcert.var.select=sqrt(exp(fitted(gam.var.select)))
tsresid.select=xts(select.resids,mydates[-1])
tspdcert.var.select = xts(pdcert.var.select,mydates[-1])
plot(tsresid.select^2,main='Squared Residuals: Selected Model',ylim=c(0,0.2))
lines(tspdcert.var.select,lwd=2,col="purple")

plot(tspdcert.var.select,lwd=2,col="purple",main='Estimated Volatility')


######## Apply ARCH Model ###################################################
## garch from tseries library
library(tseries)
resids <- pars.resids
pacf(resids^2,main="Squared Residuals")
arch.fit = garch(resids, order = c(0, 8),trace=F)
summary(arch.fit)
resids.fgarch = residuals(arch.fit)[-c(1:8)]
acf(resids.fgarch,main="ACF of ARCH Residuals")
acf(resids.fgarch^2,main="ACF of Squared ARCH Residuals")
Box.test(resids.fgarch,lag=8,fitdf=7,type='Ljung')
Box.test(resids.fgarch^2,lag=8,fitdf=7,type='Ljung')
hist(resids.fgarch,main="Histrogram of the Residuals")
qqnorm(resids.fgarch)

## garchFit from the fGarch library
library(fGarch)
archFit.resid = garchFit(~ garch(8,0), data = resids, trace = FALSE)
archFit.ts = garchFit(~ arma(4,4)+ garch(8,0), data=pdcert[-1], trace = FALSE)
summary(archFit.resid)
summary(archFit.ts)

######## Apply GARCH Model #############################################
##divide into training and testing
## Predict August & Septmeber 1-16 
pdcert2 = pdcert[-1]
n=length(pdcert2)
pdcert.test = pdcert2[3419:n]
pdcert.train =  pdcert2[-c(3419:n)]

## garchFit from the fGarch library
library(fGarch)
garchFit.ts = garchFit(~ arma(4,4)+ garch(1,1), data=pdcert.train, trace = FALSE)
# Prediction of garchFit does not work properly when considering joint arma+garch
#fore_garch11 = predict(garchFit.ts, n.ahead = 32)

##### Order Selection ################################################
## Find GARCH Order given ARMA order identified before
## ugrach from rugarch libary
library(rugarch)
#Initial GARCH Order
#ARIMA-GARCH: Select GARCH order
test_modelAGG <- function(m,n){
    spec = ugarchspec(variance.model=list(garchOrder=c(m,n)),
                      mean.model=list(armaOrder=c(4,4),
                                      include.mean=T),
                      distribution.model="std")
    fit = ugarchfit(spec, pdcert.train, solver = 'hybrid')
    current.bic = infocriteria(fit)[2]
    df = data.frame(m,n,current.bic)
    names(df) <- c("m","n","BIC")
    print(paste(m,n,current.bic,sep=" "))
    return(df)
}

ordersAGG = data.frame(Inf,Inf,Inf)
names(ordersAGG) <- c("m","n","BIC")

for (m in 0:2){
    for (n in 0:2){
        possibleError <- tryCatch(
            ordersAGG<-rbind(ordersAGG,test_modelAGG(m,n)),
            error=function(e) e
        )
        if(inherits(possibleError, "error")) next
    }
}
ordersAGG <- ordersAGG[order(-ordersAGG$BIC),]
tail(ordersAGG)
# 2,2

#ARMA update
#ARIMA-GARCH: Select ARIMA order
test_modelAGA <- function(p,q){
    spec = ugarchspec(variance.model=list(garchOrder=c(2,2)),
                      mean.model=list(armaOrder=c(p,q),
                                      include.mean=T),
                      distribution.model="std")
    fit = ugarchfit(spec, pdcert.train, solver = 'hybrid')
    current.bic = infocriteria(fit)[2]
    df = data.frame(p,q,current.bic)
    names(df) <- c("p","q","BIC")
    print(paste(p,q,current.bic,sep=" "))
    return(df)
}

ordersAGA = data.frame(Inf,Inf,Inf)
names(ordersAGA) <- c("p","q","BIC")
for (p in 0:4){
    for (q in 0:4){
        possibleError <- tryCatch(
            ordersAGA<-rbind(ordersAGA,test_modelAGA(p,q)),
            error=function(e) e
        )
        if(inherits(possibleError, "error")) next
    }
}
ordersAGA <- ordersAGA[order(-ordersAGA$BIC),]
tail(ordersAGA)
# Don't choose 0,0 since it's trivial.
#0,1

#GARCH update
test_modelAGG <- function(m,n){
    spec = ugarchspec(variance.model=list(garchOrder=c(m,n)),
                      mean.model=list(armaOrder=c(0,1),
                                      include.mean=T), distribution.model="std")
    fit = ugarchfit(spec, pdcert.train, solver = 'hybrid')
    current.bic = infocriteria(fit)[2]
    df = data.frame(m,n,current.bic)
    names(df) <- c("m","n","BIC")
    print(paste(m,n,current.bic,sep=" "))
    return(df)
}

ordersAGG = data.frame(Inf,Inf,Inf)
names(ordersAGG) <- c("m","n","BIC")

for (m in 0:2){
    for (n in 0:2){
        possibleError <- tryCatch(
            ordersAGG<-rbind(ordersAGG,test_modelAGG(m,n)),
            error=function(e) e
        )
        if(inherits(possibleError, "error")) next
    }
}
ordersAGG <- ordersAGG[order(-ordersAGG$BIC),]
tail(ordersAGG)
# Final ARMA(0,1)+GARCH(1,1) selected 

### Goodness of Fit ####################################################
spec.1 = ugarchspec(variance.model=list(garchOrder=c(2,2)),
                 mean.model=list(armaOrder=c(4, 4),
                 include.mean=T), distribution.model="std")
final.model.1 = ugarchfit(spec.1, pdcert.train, solver = 'hybrid')

spec.2 = ugarchspec(variance.model=list(garchOrder=c(2,2)),
                 mean.model=list(armaOrder=c(0, 1),
                 include.mean=T), distribution.model="std")
final.model.2 = ugarchfit(spec.2, pdcert.train, solver = 'hybrid')

spec.3 = ugarchspec(variance.model=list(garchOrder=c(1,1)),
                 mean.model=list(armaOrder=c(0, 1),
                 include.mean=T), distribution.model="std")
final.model.3 = ugarchfit(spec.3, pdcert.train, solver = 'hybrid')

## compare Information Criteria
infocriteria(final.model.1)
infocriteria(final.model.2)
infocriteria(final.model.3)

## Residual Analysis
resids.final.model = residuals(final.model.3)
acf(resids.final.model,main="ACF of ARCH Residuals")
acf(resids.final.model^2,main="ACF of Squared ARCH Residuals")
Box.test(resids.final.model,lag=10,type='Ljung')
Box.test(resids.final.model^2,lag=10,type='Ljung')
qqnorm(resids.final.model)

### 1-lag Ahead Rolling Prediction ##################################################

## 1. Prediction of the return time series
## 2. Prediction of the volatility
nfore = length(pdcert.test)
fore.series.1 = NULL
fore.sigma.1 = NULL
fore.series.2 = NULL
fore.sigma.2 = NULL
fore.series.3 = NULL
fore.sigma.3 = NULL
for(f in 1: nfore){
    ## Fit models
    data = pdcert.train
    if(f>2)
       data = c(pdcert.train,pdcert.test[1:(f-1)])
    final.model.1 = ugarchfit(spec.1, data, solver = 'hybrid')
    final.model.2 = ugarchfit(spec.2, data, solver = 'hybrid')
    final.model.3 = ugarchfit(spec.3, data, solver = 'hybrid')
    ## Forecast
    fore = ugarchforecast(final.model.1, n.ahead=1)
    fore.series.1 = c(fore.series.1, fore@forecast$seriesFor)
    fore.sigma.1 = c(fore.sigma.1, fore@forecast$sigmaFor)
    fore = ugarchforecast(final.model.2, n.ahead=1)
    fore.series.2 = c(fore.series.2, fore@forecast$seriesFor)
    fore.sigma.2 = c(fore.sigma.2, fore@forecast$sigmaFor)
    fore = ugarchforecast(final.model.3, n.ahead=1)
    fore.series.3 = c(fore.series.3, fore@forecast$seriesFor)
    fore.sigma.3 = c(fore.sigma.3, fore@forecast$sigmaFor)
}

 ## Compute Accuracy Measures

### Mean Squared Prediction Error (MSPE)
mean((fore.series.1 - pdcert.test)^2)
mean((fore.series.2 - pdcert.test)^2)
mean((fore.series.3 - pdcert.test)^2)
### Mean Absolute Prediction Error (MAE)
mean(abs(fore.series.1 - pdcert.test))
mean(abs(fore.series.2 - pdcert.test))
mean(abs(fore.series.3 - pdcert.test))
### Mean Absolute Percentage Error (MAPE)
mean(abs(fore.series.1 - pdcert.test)/abs(pdcert.test))
mean(abs(fore.series.2 - pdcert.test)/abs(pdcert.test))
mean(abs(fore.series.3 - pdcert.test)/abs(pdcert.test))
### Precision Measure (PM)
sum((fore.series.1 - pdcert.test)^2)/sum((pdcert.test-mean(pdcert.test))^2)
sum((fore.series.2 - pdcert.test)^2)/sum((pdcert.test-mean(pdcert.test))^2)
sum((fore.series.3 - pdcert.test)^2)/sum((pdcert.test-mean(pdcert.test))^2)

ymin = min(c(as.vector(pdcert.test),fore.series.1,fore.series.2,fore.series.3), na.rm = T)
ymax = max(c(as.vector(pdcert.test),fore.series.1,fore.series.2,fore.series.3), na.rm = T)
data.plot = pdcert.test
names(data.plot)="Fore"
n=length(pdcert2)
time.series = pdcert2[c(n-90):n]
plot(time.series,type="l", ylim=c(ymin,ymax), xlab="Time", ylab="Return Price")
data.plot$Fore=fore.series.1
points(data.plot,lwd= 2, col="blue")
data.plot$Fore=fore.series.2
points(data.plot,lwd= 2, col="brown")
data.plot$Fore=fore.series.3
points(data.plot,lwd= 2, col="purple")

ymin = min(c(as.vector(pdcert.test^2),fore.sigma.1^2,fore.sigma.2^2,fore.sigma.3^2), na.rm = T)
ymax = max(c(as.vector(pdcert.test^2),fore.sigma.1^2,fore.sigma.2^2,fore.sigma.3^2), na.rm = T)


plot(time.series^2,type="l", ylim=c(ymin,0.025), xlab="Time", ylab="Return Price")
data.plot$Fore=fore.sigma.1^2
points(data.plot,lwd= 2, col="blue")
data.plot$Fore=fore.sigma.2^2
points(data.plot,lwd= 2, col="brown")
data.plot$Fore=fore.sigma.3^2
points(data.plot,lwd= 2, col="purple")

