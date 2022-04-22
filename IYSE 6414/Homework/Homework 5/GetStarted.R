# Ensure that the sampling type is correct
RNGkind(sample.kind="Rejection")

# Reading the data: 
data = read.csv("GA_EDVisits.csv",header=TRUE) 
data = na.omit(data)

# Get names of the column 
names = colnames(data) 
attach(data)

# Standardized predictors - use these variables in your modeling in addition to the predictors A5.9, A10.14
sAvgDistS = scale(log(SpecDist)) 
sAvgDistP = scale(log(PedDist))
sMedianIncome = scale(MedianIncome) 
sNumHospitals = scale(No.Hospitals)
sPercentLessHS = scale(PercentLessHS) 
sPercentHS = scale(PercentHS)

# Define interaction terms
DistA5.9 = sAvgDistS*A5.9 
DistA10.14 = sAvgDistS* A10.14
DistIncome = sAvgDistS*sMedianIncome 
DistLessHS = sAvgDistS*sPercentLessHS
DistHS = sAvgDistS*sPercentHS 
DistPA5.9 = sAvgDistP*A5.9
DistPA10.14 = sAvgDistP* A10.14 
DistPIncome = sAvgDistP*sMedianIncome
DistPLessHS = sAvgDistP*sPercentLessHS 
DistPHS = sAvgDistP*sPercentHS

# Define final data frame
X = data.frame(A5.9, A10.14, sAvgDistS, sAvgDistP, sMedianIncome,sPercentLessHS,sPercentHS, sNumHospitals,DistA5.9, DistA10.14, DistIncome,DistLessHS, DistHS, DistPA5.9, DistPA10.14, DistPIncome,DistPLessHS, DistPHS)

# Set Seed to 100
set.seed(100)
