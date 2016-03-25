# Sequence of steps followed
# Step 1. Load all data using SSIS, no FKs
# Step 2. Analysis for Feature Engineering - finding columns which are essential but do have some missing values(sql query), adding
# arrival and departure delay colunms, one of these will be our target variable ad populating them, for this we had to do 
# conversions, get 24:00 straight, etc.
# Step 3. Finding what prediction we will do - More flights delayed on arrival than delayed for departure, so looks like we will 
# predict arrival delay!

# create DNS for linking R to sql server

library(ggplot2)
library("RODBC")
library(Hmisc)
library(dplyr)
library(caTools)
library(randomForest)
library(gbm)
library(dismo)

# install.packages("Hmisc")
# install.packages("dplyr")
#install.packages("randomForest")
# install.packages("gbm")
# install.packages("dismo")

setwd("D:/Repositories/DOT-Ontime-Flights/FlightsPredictionAndAnalysis")

odbcChannel <- odbcConnect("FlightsData")

#trying to see which will be more fun to predict
querydata <- sqlQuery(odbcChannel, "select Departure_Delay, Arrival_Delay from _flights.data.flights")

summary(querydata)

#excluding the outliers
df = subset(querydata, querydata$Departure_Delay > -1000 & querydata$Arrival_Delay > -1000 & 
              querydata$Departure_Delay < 1000 & querydata$Arrival_Delay < 1000)

summary(df)

# Looks like we can take either as target variable
boxplot(subset(df, df$Departure_Delay < 500 & df$Departure_Delay > -500 & df$Arrival_Delay < 500 
               & df$Arrival_Delay > -500))

# Histogram for on time arrival vs delayed arrival
querydata$OnTimeArrival = ifelse(querydata$Arrival_Delay > 0,"Delayed", "OnTime")
ggplot(querydata, aes(factor(OnTimeArrival))) + geom_bar() + coord_flip()

# Histogram for on time departure vs delayed departure
querydata$OnTimeDeparture = ifelse(querydata$Departure_Delay >= 0,"Delayed", "OnTime")
ggplot(querydata, aes(factor(OnTimeDeparture))) + geom_bar() + coord_flip()

# I am thinking of doing a classification problem here (although regression could also be done) to see 
# whether I can predict arrival to be latedelayed or not 

# Step 4. Feature Engineering 
# Does Day of the Week has a role to play?

# Now I am thinking I will do multi class classification - late, on time, delayed
data <- sqlQuery(odbcChannel, "SELECT DATENAME(dw,fl_date) as 'DayOfWeek', 
                 SUBSTRING(crs_dep_time,0,3) as 'Hour', 
                 Origin, Dest, distance, arrival_delay,
                 case when arrival_delay > 10 then 'Delayed' 
                 when arrival_delay >= -10 and arrival_delay <= 10 then 'OnTime' 
                 else 'BeforeTime' end as 'WhatTime' 
                 from data.flights")
ggplot(data, aes(factor(WhatTime))) + geom_bar() + coord_flip()

#Day of week effect  + coord_flip()
qplot(factor(DayOfWeek), data=data, geom="bar", fill=factor(WhatTime))
#Not much effect - maybe on Sunday and Friday they get delayed a bit more

#Does dep hour of the day play a role
qplot(factor(Hour), data=data, geom="bar", fill=factor(WhatTime))
# Yes it does!

#Does arrival airport plays a role
qplot(factor(Origin), data=data, geom="bar", fill=factor(WhatTime))

#Does departure airport plays a role
qplot(factor(Dest), data=data, geom="bar", fill=factor(WhatTime))
# certainly looks like

#Departure time certainly does have a role to play

#How about security delay at an airport
#It plays a role - some airports always have a security delay
#select origin, sum(security_delay) as 'TotalSecurityDelay' from data.flights where security_delay is not null and security_delay > 0 group by origin

#Does distance play a role
cor(data$distance, data$arrival_delay) # doesn't seem like!!!

#What if a flight is diverted
#select * from data.flights where diverted = 1 and arrival_delay >=0

#Number of flights cancelled and their reasons
# No flights were cancelled

#Any bad weather days this month?
#Might play a role

#Will depend on carrier also

#Our candiate feature variables
# Departure delay, carrier, origin, dest, diverted, distance, weather_delay, busyness of origin, weekday, hour of day

# all feature data
featuresAndTarget <- sqlQuery(odbcChannel, "select 
                              carrier, origin, dest, diverted, distance, weather_delay, arrival_delay, 
                              departure_delay, DATENAME(dw,fl_date) as 'DayOfWeek', 
                              SUBSTRING(crs_dep_time,0,3) as 'Hour', 
                              case when arrival_delay > 10 then 'ArrivalDelayed' when
                              arrival_delay >= -10 and arrival_delay <= 10 then 'ArrivalOnTime' 
                              else 'ArrivalBeforeTime' end as 'ArrivalTarget', 
                              zs.OriginBusyness, (security_delay + nas_delay) as 'Airport_Delay',
                              case when departure_delay > 10 then 'DepartureDelayed' when
                              departure_delay >= -10 and departure_delay <= 10 then 'DepartureOnTime' 
                              else 'DepartureBeforeTime' end as 'DepartureClass' 
                              from data.flights fl join OriginBusyZscores zs 
                              on zs.origin_airport_id = fl.origin_airport_id")

#split data
set.seed(3000)
split = sample.split(featuresAndTarget$ArrivalTarget, SplitRatio = 0.80)
Train = subset(featuresAndTarget, split==TRUE)
Test = subset(featuresAndTarget, split==FALSE)

#DayOfWeek+ distance+OriginBusyness
FlightArrivalForest = randomForest(ArrivalTarget ~ diverted+DepartureClass+Hour+OriginBusyness, 
                                   data = Train, ntree=2000, nodesize=5,mtry=3, 
                              na.action=na.omit)

Train$ArrivalTarget = as.factor(Train$ArrivalTarget)
Test$ArrivalTarget = as.factor(Test$ArrivalTarget)

# Make predictions
PredictForest = predict(FlightArrivalForest, newdata = Test)

table(Test$ArrivalTarget, PredictForest)
accuracy = 53

#Making binomial prediction using random forests  -later, maybe we could do one vs all

##GBM tree.complexity=6, step.size=25,

#Trying to predict just late and on time this time
featuresAndTarget$LateOrNot = ifelse(featuresAndTarget$arrival_delay >=5, 0, 1)
featuresAndTarget$departclass = ifelse(featuresAndTarget$departure_delay >=5, 0, 1)

str(featuresAndTarget)

set.seed(3000)
split = sample.split(featuresAndTarget$LateOrNot, SplitRatio = 0.80)
Train = subset(featuresAndTarget, split==TRUE)
Test = subset(featuresAndTarget, split==FALSE)

# CV
gbmCV <- gbm.step(data=Train, gbm.x = c('DayOfWeek','Hour','DepartureClass','Airport_Delay',
                                        'diverted','carrier','OriginBusyness', 'departure_delay','departclass'), gbm.y=c('LateOrNot'), 
                max.trees=4000, family="bernoulli", n.trees=50, tree.complexity=2, step.size=50, 
                learning.rate=0.01, plot.main=T) 

summary(gbmCV)
gbm.perf(gbmCV) # no of trees we want to use for prediction

# Trying to see more closely which variables are good for prediction
for(i in 1:length(gbmCV$var.names)){
  plot(gbmCV, i.var = i,
       ntrees = gbm.perf(gbmCV, plot.it = FALSE)
       , ntype = "response"
  )
}

# actual prediction,no of trees come from gbm.perf
preds90 <- predict.gbm(gbmCV, Test, n.trees=, type="response")
summary(preds90)
str(preds90)

# trying to use cross validation to pick a good threshold

# to make an ROC curve one needs actual values and predicted values, both are given below.
# These functions will do the groupings on their own (p > 0.2, etc.) like we were doing above
ROCRpred = prediction(preds90, Test$target)

# Performance function
ROCRperf = performance(ROCRpred, "tpr", "fpr")

auc.tmp <- performance(ROCRpred,"auc"); 
auc <- as.numeric(auc.tmp@y.values)

acc.perf = performance(ROCRpred, measure = "acc")
plot(acc.perf)

str(ROCRperf)

# cutoffs <- data.frame(cut=ROCRperf@alpha.values[[1]], fpr=ROCRperf@x.values[[1]], 
#                       tpr=ROCRperf@y.values[[1]])
# head(cutoffs)

# Add threshold labels
plot(ROCRperf, colorize=TRUE, print.cutoffs.at=seq(0,1,by=0.07), text.adj=c(-0.2,1.7))

close(odbcChannel)
rm(list=ls())