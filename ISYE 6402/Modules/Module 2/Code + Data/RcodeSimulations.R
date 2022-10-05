##############################################################################
############ Simulate ARMA Processes (L2) ####################################
##############################################################################
## Simulate normal WN
w1= rnorm(1000,0,1)
# re-scale to mean 0 and std dev 1
w1 = (w1-mean(w1))/sqrt(var(w1))
# simulate exponential WN
w2 = rexp(1000,1)
# re-scale to mean 0 and std dev 1
w2 = (w2-mean(w2))/sqrt(var(w2))
# form time series
w1 = ts(w1,start=1,deltat=1)
 w2 = ts(w2,start=1,deltat=1)
# plot ts and their acf's
par(mfrow=c(2,2))
ts.plot(w1,main='Normal')
ts.plot(w2,main='Exponential')
acf(w1,main='')
acf(w2,main='')
 
## Simulate MA(2) with Normal White Noise
w1 = rnorm(502)
#set coefficients
a = c(1,-.5,.2)
ma2.11 = filter(w1,filter=a,side=1)
ma2.11 = ma2.11[3:502]
#change lag-1 coefficient
a1 = c(1,.5,.2)
ma2.12 = filter(w1,filter=a1,side=1)
ma2.12 = ma2.12[3:502]

# Simulate MA(2) with Exponetial white noise
w2 = rexp(502)-1
#set coefficients
a = c(1,-.5,.2)
ma2.21 = filter(w2,filter=a,side=1)
ma2.21 = ma2.21[3:502]
#change lag-1 coefficient
a1 = c(1,.5,.2)
ma2.22 = filter(w2,filter=a1,side=1)
ma2.22 = ma2.22[3:502]

par(mfrow=c(2,2))
acf(ma2.11,main="Normal/-.5")
acf(ma2.12,main="Normal/.5")
acf(ma2.21,main="Exponential/-.5")
acf(ma2.22,main="Exponential/.5")


# MA(3) with non-stationary noise
a4 = c(1,.2,.8,1.2)
ma2.4 = filter(w1*(2*(1:502)+0.5),filter=a4,side=1)
ma2.4 = ma2.4[4:502]
par(mfrow=c(2,1))
ts.plot(ma2.4,ylab="")
acf(ma2.4,main='')

##############################################################################
################# Causal and Invertible Processes (L3) #######################
##############################################################################
## Causal AR(1) processes (|phi|<1)
w2 = rnorm(1500)
a1 = 0.1
ar1 = filter(w2,filter=a1,method='recursive')
ar1.1 = ar1[1251:1500]
a1 = - 0.1
ar1 = filter(w2,filter=a1,method='recursive')
ar1.2 = ar1[1251:1500]

a1 = 0.9
ar1 = filter(w2,filter=a1,method='recursive')
ar1.3 = ar1[1251:1500]
a1 = - 0.9
ar1 = filter(w2,filter=a1,method='recursive')
ar1.4=ar1[1251:1500]

par(mfrow=c(2,2))
ts.plot(ar1.1,main='phi=0.1')
ts.plot(ar1.2,main='phi=-0.1')
ts.plot(ar1.3,main='phi=0.9')
ts.plot(ar1.4,main='phi=-0.9')

##############################################################################
################# AR & MA vs PACF & ACF (L5) #################################
##############################################################################
w2 = rnorm(1500)
## Nonstationary AR(2) process 
a2 = c(0.8,0.2)
ar2.n = filter(w2,filter=a2,method='recursive')
ar2.n = ar2.n[1251:1500]
## Stationary AR(2) process
a2 = c(1.8,-0.9)
ar2.s = filter(w2,filter=a2,method='recursive')
ar2.s = ar2.s[1251:1500]

par(mfrow=c(2,2))
ts.plot(ar2.n,main='Nonstationary AR(2)',ylab="",xlab="")
ts.plot(ar2.s,main='Stationary AR(2)',ylab="",xlab="")
pacf(ar2.n,main = '')
pacf(ar2.s,main = '')

## ARMA(2,2) Process
arma22 = arima.sim(n = 500, list(ar = c(0.88, -0.49), ma = c(-0.23, 0.25)), sd = sqrt(0.18))
ts.plot(arma22,ylab="",xlab="")
par(mfrow=c(1,2))
acf(arma22,main = '')
pacf(arma22,main = '')
##############################################################################
################# AR & MA Estimation (L7) #################################
##############################################################################

## AR Estimation
## Method 1: Linear Regression

# AR(1) & AR(2) process simulation
w2 = rnorm(1500)
b = 0.5
ar1 = filter(w2,filter=b,method='recursive')
ar1 = ar1[1001:1500]
b = c(1.2,-0.5)
ar2 = filter(w2,filter=b,method='recursive')
ar2 = ar2[1001:1500]

## Fit Linear Regression to AR(2)
data2 = data.frame(cbind(x1=ar2[1:498],x2=ar2[2:499],y=ar2[3:500]))
model2 = lm(y~x1+x2,data=data2)
## t-test for H_0: beta_1=-0.5 vs H_a: beta_1 not equal to -0.5
t.value = (-0.48149+0.5)/0.394
p.value = 2*(1-pnorm(t.value))
summary(model2)
par(mfrow=c(2,2))
ts.plot(ar2,ylab="AR(2) Time Series")
pacf(ar2,main='PACF of AR(2)')
ts.plot(model2$residuals,ylab="Residuals")
pacf(model2$residuals,main='PACF of Residuals')

# fit an AR(2) to an AR(1) process using linear regression
data3 = data.frame(cbind(x1=ar1[1:498],x2=ar1[2:499],y=ar1[3:500]))
model3 = lm(y~x1+x2,data=data3)
summary(model3)
par(mfrow=c(2,2))
ts.plot(ar1)
pacf(ar1)
ts.plot(model3$residuals)
pacf(model3$residuals)

## Yule-Walker Approach

w2 = rnorm(1500)
b = c(1.2,-0.5)
ar2 = filter(w2,filter=b,method='recursive')
ar2 = ar2[1001:1500]

## Fit an AR(3) to an AR(2) model
# Form Gamma_3 
covf = acf(ar2,type='covariance',plot=FALSE)
Gammamatrix = matrix(0,3,3)
for(i in 1:3){
 if(i>1){
 Gammamatrix[i,] = c(covf$acf[i:2,,1],covf$acf[1:(3-i+1),,1])
 }
 else{
 Gammamatrix[i,] = covf$acf[1:(3-i+1),,1]
 }
}
Gamma1 = covf$acf[2:4,,1]
phi.estim = solve(Gammamatrix,Gamma1)

## Compare Statistical Properties of the Estimators
## Sampling Distribution: Linear Regression
phi.estim.lm = NULL
S = 500
for(s in 1:S){
  w2 = rnorm(1500)
  b = c(1.2,-0.5)
  ar2 = filter(w2,filter=b,method='recursive')
  ar2 = ar2[1001:1500]
  ## Fit Linear Regression to AR(2)
  data2 = data.frame(cbind(x1=ar2[1:498],x2=ar2[2:499],y=ar2[3:500]))
  phi.estim = rev(coefficients(lm(y~x1+x2,data=data2))[-1])
  phi.estim.lm = rbind(phi.estim.lm,phi.estim)
 }
phi.estim.yw = NULL
S = 500
for(s in 1:S){
  w2 = rnorm(1500)
  b = c(1.2,-0.5)
  ar2 = filter(w2,filter=b,method='recursive')
  ar2 = ar2[1001:1500]
  ## Fit Yule-Walker to AR(2)
  covf = acf(ar2,type='covariance',plot=FALSE)
  Gammamatrix = matrix(0,2,2)
  Gammamatrix[2,] = c(covf$acf[2,,1],covf$acf[1,,1])
  Gammamatrix[1,] = covf$acf[1:2,,1]
  Gamma1 = covf$acf[2:3,,1]
  phi.estim = solve(Gammamatrix,Gamma1)
  phi.estim.yw = rbind(phi.estim.yw,phi.estim)
 }

summary(phi.estim.lm)
summary(phi.estim.yw)
estim.phi.1 = c(phi.estim.lm[,1],phi.estim.yw[,1])
estim.phi.2 = c(phi.estim.lm[,2],phi.estim.yw[,2])
label.phi.1 = factor(rep(c("LMX(t-1)","YWX(t-1)"),each=S))
label.phi.2 = factor(rep(c("LMX(t-2)","YWX(t-2)"),each=S))
boxplot(estim.phi.1~label.phi.1,main="Estimates for Phi1=1.2")
boxplot(estim.phi.2~label.phi.2,main="Estimates for Phi2=-0.5")
