library(xts)
library(mgcv)
library(data.table)
library(vars)
library(tseries)

btc <- read.csv("Data/btc.csv")
gold <- read.csv("Data/gold.csv")
sp500 <- read.csv("Data/sp500.csv")

pricebtc<-btc[,2]
datesbtc<-as.Date(btc[,1],"%m/%d/%Y")
tsbtc=xts(pricebtc,datesbtc)
dlbtc<-diff(log(tsbtc))
plot(tsbtc,main='BTC-USD')

pricegold<-gold[,2]
datesgold<-as.Date(gold[,1],"%m/%d/%Y")
tsgold<-xts(pricegold,datesgold)
dlgold<-diff(log(tsgold))
plot(tsgold,main='Gold Price-USD')

pricesp<-sp500[,2]
datessp<-as.Date(sp500[,1],"%m/%d/%Y")
tssp<-xts(pricesp,datessp)
dlsp<-diff(log(tssp))
plot(tssp,main='S&P 500')

plot(dlbtc,main='BTC Return Price')
plot(dlgold,main='Gold Return Price')
plot(dlsp,main='S&P 500 Return Price')

dlbtc <- dlbtc[-1]
dlgold <- dlgold[-1]
dlsp <- dlsp[-1]


#mvts.btc <- na.omit(cbind(dlbtc,dlgold,dlsp))
#acf(mvts.btc)

## ACF Analysis for BTC vs Gold or SP500 Return Price
#acf(merge(dlbtc,dlgold, join='inner'))
#acf(merge(dlbtc,dlsp, join='inner'))

## ACF Analysis for all three time series together
ts.merge <- merge(tsbtc,tsgold, join='inner')
ts.merge <- merge(ts.merge,tssp, join='inner')
colnames(ts.merge)<-c("tsbtc","tsgold","tssp")

dl.merge <- merge(dlbtc,dlgold, join='inner')
dl.merge <- merge(dl.merge,dlsp, join='inner')
colnames(dl.merge)<-c("dlbtc","dlgold","dlsp")
acf(dl.merge)

## Augmented Dickey-Fuller test for stationarity (H0: not stationary vs HA: stationary)
adf.test(dlbtc)
adf.test(dlgold)
adf.test(dlsp)


n <- dim(ts.merge)[1]
cor(ts.merge)
## lag-one correlation between BTC & Gold price
cor(ts.merge[(1:n-1),1],ts.merge[(2:n),2])
cor(ts.merge[(2:n),1],ts.merge[(1:n-1),2])
## lag-one correlation between BTC & SP500 price
cor(ts.merge[(1:n-1),1],ts.merge[(2:n),3])
cor(ts.merge[(2:n),1],ts.merge[(1:n-1),3])

n <- dim(dl.merge)[1]
cor(dl.merge)
## lag-one correlation between BTC & Gold price
cor(dl.merge[(1:n-1),1],dl.merge[(2:n),2])
cor(dl.merge[(2:n),1],dl.merge[(1:n-1),2])
## lag-one correlation between BTC & SP500 price
cor(dl.merge[(1:n-1),1],dl.merge[(2:n),3])
cor(dl.merge[(2:n),1],dl.merge[(1:n-1),3])


## Univariate AR vs VAR: Order Selection

## Select AR Order
mod_btc = ar(dlbtc,order.max=20)
print(mod_btc$order)
mod_gold = ar(dlgold,order.max=20)
print(mod_gold$order)
mod_sp = ar(dlsp,order.max=20)
print(mod_sp$order)
## Capture relationship of change 
mod_aic_1 = VAR(dl.merge,lag.max=20,ic="AIC", type="const")
mod_aic_2 = VAR(dl.merge,lag.max=20,ic="AIC", type="trend")
mod_aic_3 = VAR(dl.merge,lag.max=20,ic="AIC", type="both")
pord_1 = mod_aic_1$p; pord_2 = mod_aic_2$p; pord_3 = mod_aic_3$p
mod_hq = VAR(dl.merge,lag.max=20,ic="HQ")
mod_sc = VAR(dl.merge,lag.max=20,ic="SC")
mod_fpe = VAR(dl.merge,lag.max=20,ic="FPE")
pord_hq = mod_hq$p; pord_sc = mod_sc$p; pord_fpe = mod_fpe$p


## Apply VAR Model ####

## Divide data into test & train 
#dl.train <- dl.merge[1:(n-30),]
#dl.test <-  dl.merge[(n-29):n,]

# Model Fitting: Unrestricted VAR
model.var <- VAR(dl.merge,p=2)
summary(model.var)

#Model Fitting: Restricted VAR        
model.var.restrict <- restrict(model.var)
summary(model.var.restrict)

# Granger Causality Tests

## Estimated coefficients and their variance for Bitcoin regression Equaltion
coef.btc = coefficients(model.var)$dlbtc[-(2*3+1),1]
var.btc = vcov(model.var)[c(2:(2*3+1)),c(2:(2*3+1))]
## Estimated coefficients and their variance for SP500 regression Equaltion
coef.sp = coefficients(model.var)$dlsp[-(2*3+1),1]
sp.index = c(16:21)
var.sp = vcov(model.var)[sp.index,sp.index]

library(aod)
# Is there a lead-lag relationship for btc-sp500
wald.test(b=coef.btc, var.btc,Terms = c(3,6))
wald.test(b=coef.sp, var.sp,Terms = c(1,4))



# Predict the future gold prices
pred.test <- as.vector(predict(model.var,n.ahead=30))
preds.test


## Evaluate potential cointegration visually
lbtc<- log(pricebtc)
tsbtc<-xts(lbtc,datesbtc)
lsp <- log(pricesp)
tssp<-xts(lsp,datessp)
lgold<- log(pricegold)
tsgold<-xts(lgold,datesgold)

ts.merge <- merge(tsbtc,tssp, join='inner')
lm.btcsp <- lm(ts.merge[,1]~ts.merge[,2])
#summary(lm.btcsp)
coef.sp <-lm.btcsp$coef
tr.tssp<-xts((coef.sp[2]*lsp+coef.sp[1]),datessp)
ts.merge <- merge(tsbtc,tsgold, join='inner')
lm.btcgold <- lm(ts.merge[,1]~ts.merge[,2])
#summary(lm.btcgold)
coef.gold <-lm.btcgold$coef
tr.tsgold<-xts((coef.gold[2]*lgold+coef.gold[1]),datesgold)

ts.merge <- merge(tsbtc,tr.tssp, join='inner')
ts.merge <- merge(ts.merge,tr.tsgold, join='inner')
plot(ts.merge, main="")

## Evaluate potential cointegration between BTC & SP500
ts.merge <- merge(tsbtc,tr.tssp, join='inner')
co.resid <- ts.merge[,1]-ts.merge[,2]
adf.test(co.resid)

library(urca)
summary(ur.df(co.resid, type="none",selectlags="BIC"))
summary(ur.df(co.resid, type="drift",selectlags="BIC"))
summary(ur.df(co.resid, type="trend",selectlags="BIC"))

## Fit VECM 
library(dynlm)
tsbtc <-as.numeric(ts.merge[,1])
tssp <- as.numeric(ts.merge[,2])
## Set Error Correction Term
tsdif <- tsbtc[-1]-tssp[-1]

VECM_BTC <- dynlm(d(tsbtc) ~ L(d(tssp), 1) + L(d(tsbtc), 1) +  L(tsdif))
names(VECM_BTC$coefficients) <- c("Intercept", "D_SP_l1","D_BTC_l1", "ect_l1")
coeftest(VECM_BTC, vcov. = NeweyWest(VECM_BTC, prewhite = F, adjust = T))

VECM_SP <- dynlm(d(tssp) ~ L(d(tssp), 1) + L(d(tsbtc), 1) +  L(tsdif))
names(VECM_SP$coefficients) <- c("Intercept", "D_SP_l1","D_BTC_l1", "ect_l1")
coeftest(VECM_SP, vcov. = NeweyWest(VECM_SP, prewhite = F, adjust = T))



